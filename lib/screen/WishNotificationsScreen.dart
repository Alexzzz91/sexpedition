import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sexpedition_application_1/models/user_profile.dart';
import 'package:sexpedition_application_1/models/wish_notification.dart';
import 'package:sexpedition_application_1/models/wish_notification_comment.dart';
import 'package:sexpedition_application_1/services/partners_repository.dart';
import 'package:sexpedition_application_1/services/wish_notifications_repository.dart';

String? extractFirstUrl(String text) {
  // Simple URL detector: if body contains one, use it for copy/logging.
  final m = RegExp(r'(https?://[^\s]+)').firstMatch(text);
  return m?.group(1);
}

Future<void> copyTextToClipboard(String rawText, {String? label}) async {
  final text = rawText.trim();
  if (text.isEmpty) return;
  try {
    await Clipboard.setData(ClipboardData(text: text));
  } catch (e) {
    // Requirement: if link copy fails, output the link text to console.
    // ignore: avoid_print
    debugPrint('[WishNotifications] Copy failed (${label ?? 'text'}): $text; error=$e');
  }
}

class WishNotificationsScreen extends StatefulWidget {
  const WishNotificationsScreen({super.key});

  @override
  State<WishNotificationsScreen> createState() => _WishNotificationsScreenState();
}

class _WishNotificationsScreenState extends State<WishNotificationsScreen> {
  final WishNotificationsRepository _repo = WishNotificationsRepository();
  final PartnersRepository _partnersRepo = PartnersRepository();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Уведомления')),
      body: StreamBuilder<List<WishNotification>>(
        stream: _repo.watchMyNotifications(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Ошибка загрузки уведомлений: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final list = snapshot.data!;
          if (list.isEmpty) return const Center(child: Text('Уведомлений пока нет'));
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (context, i) {
              final item = list[i];
              return FutureBuilder<UserProfile?>(
                future: _partnersRepo.getProfile(item.fromUserId),
                builder: (context, profileSnap) {
                  final sender = profileSnap.data?.displayLabel ?? item.fromUserId;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Icon(
                        item.isRead ? Icons.notifications_none : Icons.notifications_active,
                        color: item.isRead ? Theme.of(context).colorScheme.outline : Theme.of(context).colorScheme.primary,
                      ),
                      title: Text(item.title),
                      subtitle: SelectableText('$sender: ${item.body}'),
                      trailing: item.isRead
                          ? null
                          : const Chip(
                              label: Text('Новое', style: TextStyle(fontSize: 10)),
                              padding: EdgeInsets.zero,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                      onTap: () async {
                        if (!item.isRead) {
                          await _repo.markAsRead(item.id);
                        }
                        if (context.mounted) {
                          await showModalBottomSheet<void>(
                            context: context,
                            isScrollControlled: true,
                            builder: (_) => _WishNotificationDetailsSheet(
                              notification: item,
                              senderName: sender,
                              repo: _repo,
                            ),
                          );
                        }
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _WishNotificationDetailsSheet extends StatefulWidget {
  const _WishNotificationDetailsSheet({
    required this.notification,
    required this.senderName,
    required this.repo,
  });

  final WishNotification notification;
  final String senderName;
  final WishNotificationsRepository repo;

  @override
  State<_WishNotificationDetailsSheet> createState() => _WishNotificationDetailsSheetState();
}

class _WishNotificationDetailsSheetState extends State<_WishNotificationDetailsSheet> {
  final TextEditingController _commentController = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final body = widget.notification.body;
    final url = extractFirstUrl(body);
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SafeArea(
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.8,
          child: Column(
            children: [
              Card(
                margin: const EdgeInsets.only(left: 12, right: 12, top: 12, bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.notification.title, style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 6),
                            SelectableText(widget.notification.body),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Копировать ссылку',
                        onPressed: url == null
                            ? null
                            : () async => copyTextToClipboard(url, label: 'url'),
                        icon: const Icon(Icons.copy),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: StreamBuilder<List<WishNotificationComment>>(
                  stream: widget.repo.watchComments(widget.notification.id),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                    final comments = snapshot.data!;
                    if (comments.isEmpty) {
                      return const Center(child: Text('Комментариев пока нет'));
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: comments.length,
                      itemBuilder: (context, i) {
                        final c = comments[i];
                        final isMe = c.authorUserId == currentUid;
                        final name = isMe ? 'Вы' : widget.senderName;
                        return Align(
                          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 320),
                            child: Card(
                              color: isMe ? Theme.of(context).colorScheme.primaryContainer : null,
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(name, style: Theme.of(context).textTheme.labelMedium),
                                    const SizedBox(height: 4),
                                    Text(c.text),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        minLines: 1,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: 'Добавить комментарий',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _sending
                          ? null
                          : () async {
                              final text = _commentController.text.trim();
                              if (text.isEmpty) return;
                              setState(() => _sending = true);
                              await widget.repo.addComment(widget.notification.id, text);
                              if (mounted) {
                                _commentController.clear();
                                setState(() => _sending = false);
                              }
                            },
                      child: _sending
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
