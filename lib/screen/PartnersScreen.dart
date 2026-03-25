import 'package:flutter/material.dart';
import 'package:sexpedition_application_1/models/partner_connection.dart';
import 'package:sexpedition_application_1/models/user_profile.dart';
import 'package:sexpedition_application_1/services/partners_repository.dart';

class PartnersScreen extends StatefulWidget {
  const PartnersScreen({super.key});

  @override
  State<PartnersScreen> createState() => _PartnersScreenState();
}

class _PartnersScreenState extends State<PartnersScreen> {
  final PartnersRepository _repo = PartnersRepository();
  final _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _repo.ensureMyProfile();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _addByEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;
    final profile = await _repo.getUserByEmail(email);
    if (!mounted) return;
    if (profile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пользователь с таким email не найден')),
      );
      return;
    }
    final myId = _repo.currentUserId;
    if (myId == null || profile.id == myId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Нельзя добавить самого себя')),
      );
      return;
    }
    final id = await _repo.sendRequest(profile.id);
    if (!mounted) return;
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Запрос уже отправлен или связь уже есть')),
      );
    } else {
      _emailController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Запрос отправлен')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Партнёры')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withValues(alpha: 0.20),
                  theme.colorScheme.surface,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Добавить по email', style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  'Пригласите партнёра в приватное пространство.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          hintText: 'Email партнёра',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(onPressed: _addByEmail, child: const Text('Добавить')),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _SectionTitle(
            icon: Icons.mark_email_unread_rounded,
            title: 'Входящие запросы',
          ),
          const SizedBox(height: 8),
          StreamBuilder<List<PartnerConnection>>(
            stream: _repo.watchIncomingRequests(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Text('Ошибка загрузки: ${snapshot.error}', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                );
              }
              if (!snapshot.hasData) return const SizedBox(height: 40, child: Center(child: CircularProgressIndicator()));
              final list = snapshot.data!;
              if (list.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.only(bottom: 24),
                  child: Text('Нет входящих запросов'),
                );
              }
              return Column(
                children: list.map((c) => _IncomingRequestTile(connection: c, repo: _repo)).toList(),
              );
            },
          ),
          const SizedBox(height: 24),
          _SectionTitle(
            icon: Icons.favorite_rounded,
            title: 'Мои партнёры',
          ),
          const SizedBox(height: 8),
          StreamBuilder<List<PartnerConnection>>(
            stream: _repo.watchAcceptedPartners(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Text('Ошибка загрузки: ${snapshot.error}', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                );
              }
              if (!snapshot.hasData) return const SizedBox(height: 40, child: Center(child: CircularProgressIndicator()));
              final list = snapshot.data!;
              if (list.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.only(bottom: 24),
                  child: Text('Нет партнёров'),
                );
              }
              return Column(
                children: list.map((c) => _PartnerTile(connection: c, repo: _repo)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _IncomingRequestTile extends StatelessWidget {
  const _IncomingRequestTile({required this.connection, required this.repo});
  final PartnerConnection connection;
  final PartnersRepository repo;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserProfile?>(
      future: repo.getProfile(connection.fromUserId),
      builder: (context, snap) {
        final name = snap.data?.displayLabel ?? connection.fromUserId;
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person_add_alt_1)),
            title: Text(name),
            subtitle: const Text('Хочет добавить вас в партнёры'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.check),
                  onPressed: () => repo.acceptConnection(connection.id),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => repo.rejectConnection(connection.id),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PartnerTile extends StatelessWidget {
  const _PartnerTile({required this.connection, required this.repo});
  final PartnerConnection connection;
  final PartnersRepository repo;

  @override
  Widget build(BuildContext context) {
    final myId = repo.currentUserId;
    final partnerId = myId == null ? null : connection.partnerUserId(myId);
    if (partnerId == null) return const SizedBox.shrink();
    return FutureBuilder<UserProfile?>(
      future: repo.getProfile(partnerId),
      builder: (context, snap) {
        final name = snap.data?.displayLabel ?? partnerId;
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.18),
              child: Icon(Icons.favorite, color: Theme.of(context).colorScheme.primary),
            ),
            title: Text(name),
            subtitle: const Text('Подключён'),
            trailing: IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (c) => AlertDialog(
                    title: const Text('Удалить партнёра?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.of(c).pop(false), child: const Text('Нет')),
                      FilledButton(onPressed: () => Navigator.of(c).pop(true), child: const Text('Да')),
                    ],
                  ),
                );
                if (ok == true) await repo.removePartner(connection.id);
              },
            ),
          ),
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(title, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}
