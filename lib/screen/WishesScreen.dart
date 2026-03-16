import 'package:flutter/material.dart';
import 'package:sexpedition_application_1/models/partner_connection.dart';
import 'package:sexpedition_application_1/models/wish.dart';
import 'package:sexpedition_application_1/models/wish_request.dart';
import 'package:sexpedition_application_1/models/user_profile.dart';
import 'package:sexpedition_application_1/services/partners_repository.dart';
import 'package:sexpedition_application_1/services/wishes_repository.dart';

class WishesScreen extends StatefulWidget {
  const WishesScreen({super.key});

  @override
  State<WishesScreen> createState() => _WishesScreenState();
}

class _WishesScreenState extends State<WishesScreen> with SingleTickerProviderStateMixin {
  final WishesRepository _wishesRepo = WishesRepository();
  final PartnersRepository _partnersRepo = PartnersRepository();
  late TabController _tabController;
  late Stream<List<Wish>> _myWishesStream;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _myWishesStream = _wishesRepo.watchMyWishes();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Желания'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Мой список'),
            Tab(text: 'Партнёры'),
            Tab(text: 'Запросы'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _MyWishesList(stream: _myWishesStream, repo: _wishesRepo),
          _PartnersWishesTab(partnersRepo: _partnersRepo, wishesRepo: _wishesRepo),
          _WishRequestsTab(partnersRepo: _partnersRepo, wishesRepo: _wishesRepo),
        ],
      ),
    );
  }
}

class _MyWishesList extends StatelessWidget {
  const _MyWishesList({required this.stream, required this.repo});
  final Stream<List<Wish>> stream;
  final WishesRepository repo;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Wish>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Ошибка: ${snapshot.error}', textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  const Text('Проверьте правила Firestore и индексы для коллекции wishes.', textAlign: TextAlign.center),
                ],
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final list = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: list.length + 1,
          itemBuilder: (context, i) {
            if (i == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: FilledButton.icon(
                  onPressed: () => _showAddOrEditWishDialog(context, repo, null),
                  icon: const Icon(Icons.add),
                  label: const Text('Добавить желание'),
                ),
              );
            }
            final wish = list[i - 1];
            return _WishTile(
              wish: wish,
              repo: repo,
              onTap: () => _showAddOrEditWishDialog(context, repo, wish),
            );
          },
        );
      },
    );
  }
}

class _WishTile extends StatelessWidget {
  const _WishTile({required this.wish, required this.repo, required this.onTap});
  final Wish wish;
  final WishesRepository repo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(wish.content),
        subtitle: Row(
          children: [
            Text(wish.typeLabel, style: Theme.of(context).textTheme.bodySmall),
            if (wish.isForNearFuture) ...[
              const SizedBox(width: 8),
              Chip(
                label: const Text('На ближайшее время', style: TextStyle(fontSize: 10)),
                padding: EdgeInsets.zero,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
            if (!wish.visibleToPartners) ...[
              const SizedBox(width: 8),
              Icon(Icons.visibility_off, size: 14, color: Theme.of(context).colorScheme.outline),
            ],
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (v) async {
            if (v == 'edit') {
              onTap();
            } else if (v == 'delete') {
              final ok = await showDialog<bool>(
                context: context,
                builder: (c) => AlertDialog(
                  title: const Text('Удалить желание?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Нет')),
                    FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Да')),
                  ],
                ),
              );
              if (ok == true) await repo.deleteWish(wish.id);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text('Редактировать')),
            const PopupMenuItem(value: 'delete', child: Text('Удалить')),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}

Future<void> _showAddOrEditWishDialog(BuildContext context, WishesRepository repo, Wish? existing) async {
  final isEdit = existing != null;
  WishType type = existing?.type ?? WishType.action;
  final contentController = TextEditingController(text: existing?.content ?? '');
  bool isForNearFuture = existing?.isForNearFuture ?? false;
  bool visibleToPartners = existing?.visibleToPartners ?? true;

  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(isEdit ? 'Редактировать желание' : 'Добавить желание'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<WishType>(
                    value: type,
                    decoration: const InputDecoration(labelText: 'Тип'),
                    items: WishType.values
                        .map((t) => DropdownMenuItem(value: t, child: Text(Wish(type: t, id: '', userId: '', content: '', createdAt: DateTime.now()).typeLabel)))
                        .toList(),
                    onChanged: (v) => setState(() => type = v ?? type),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: contentController,
                    decoration: InputDecoration(
                      labelText: type == WishType.movie ? 'Ссылка на фильм' : (type == WishType.action ? 'Действие' : 'Вещь'),
                      hintText: type == WishType.movie ? 'https://...' : null,
                    ),
                    maxLines: type == WishType.movie ? 1 : 2,
                    keyboardType: type == WishType.movie ? TextInputType.url : null,
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('На ближайшее время'),
                    value: isForNearFuture,
                    onChanged: (v) => setState(() => isForNearFuture = v),
                  ),
                  SwitchListTile(
                    title: const Text('Показывать партнёрам'),
                    value: visibleToPartners,
                    onChanged: (v) => setState(() => visibleToPartners = v),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
              FilledButton(
                onPressed: () {
                  if (contentController.text.trim().isEmpty) return;
                  Navigator.pop(context, true);
                },
                child: Text(isEdit ? 'Сохранить' : 'Добавить'),
              ),
            ],
          );
        },
      );
    },
  );

  if (result != true || !context.mounted) return;
  final content = contentController.text.trim();
  if (content.isEmpty) return;

  if (isEdit) {
    await repo.updateWish(existing.copyWith(
      type: type,
      content: content,
      isForNearFuture: isForNearFuture,
      visibleToPartners: visibleToPartners,
    ));
  } else {
    await repo.addWish(Wish(
      id: '',
      userId: '',
      type: type,
      content: content,
      isForNearFuture: isForNearFuture,
      visibleToPartners: visibleToPartners,
      createdAt: DateTime.now(),
    ));
  }
}

class _PartnersWishesTab extends StatelessWidget {
  const _PartnersWishesTab({required this.partnersRepo, required this.wishesRepo});
  final PartnersRepository partnersRepo;
  final WishesRepository wishesRepo;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PartnerConnection>>(
      stream: partnersRepo.watchAcceptedPartners(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final partners = snapshot.data!;
        final myId = partnersRepo.currentUserId;
        if (myId == null || partners.isEmpty) {
          return const Center(child: Text('Нет партнёров. Добавьте партнёра во вкладке «Партнёры».'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: partners.length,
          itemBuilder: (context, i) {
            final conn = partners[i];
            final partnerId = conn.partnerUserId(myId);
            return FutureBuilder<UserProfile?>(
              future: partnersRepo.getProfile(partnerId),
              builder: (context, profileSnap) {
                final name = profileSnap.data?.displayLabel ?? partnerId;
                return ListTile(
                  title: Text(name),
                  subtitle: const Text('Пожелания на ближайшее время'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (context) => _PartnerNearFutureWishesPage(
                        partnerUserId: partnerId,
                        partnerName: name,
                        wishesRepo: wishesRepo,
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _PartnerNearFutureWishesPage extends StatelessWidget {
  const _PartnerNearFutureWishesPage({
    required this.partnerUserId,
    required this.partnerName,
    required this.wishesRepo,
  });
  final String partnerUserId;
  final String partnerName;
  final WishesRepository wishesRepo;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Желания: $partnerName')),
      body: StreamBuilder<List<Wish>>(
        stream: wishesRepo.watchPartnerNearFutureWishes(partnerUserId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final list = snapshot.data!;
          if (list.isEmpty) {
            return const Center(child: Text('Нет пожеланий на ближайшее время'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (context, i) {
              final w = list[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(w.content),
                  subtitle: Text(w.typeLabel),
                  onTap: () {
                    if (w.type == WishType.movie && w.content.startsWith('http')) {
                      // Could launch URL
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _WishRequestsTab extends StatelessWidget {
  const _WishRequestsTab({required this.partnersRepo, required this.wishesRepo});
  final PartnersRepository partnersRepo;
  final WishesRepository wishesRepo;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Запросить пожелания у партнёра', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        StreamBuilder<List<PartnerConnection>>(
          stream: partnersRepo.watchAcceptedPartners(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox.shrink();
            final partners = snapshot.data!;
            final myId = partnersRepo.currentUserId;
            if (myId == null || partners.isEmpty) return const Text('Нет партнёров');
            return Column(
              children: partners.map((conn) {
                final partnerId = conn.partnerUserId(myId);
                return FutureBuilder<UserProfile?>(
                  future: partnersRepo.getProfile(partnerId),
                  builder: (context, profileSnap) {
                    final name = profileSnap.data?.displayLabel ?? partnerId;
                    return ListTile(
                      title: Text(name),
                      trailing: FilledButton(
                        onPressed: () async {
                          final id = await wishesRepo.sendWishRequest(partnerId);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              id != null ? const SnackBar(content: Text('Запрос отправлен')) : const SnackBar(content: Text('Запрос уже отправлен')),
                            );
                          }
                        },
                        child: const Text('Запросить'),
                      ),
                    );
                  },
                );
              }).toList(),
            );
          },
        ),
        const SizedBox(height: 24),
        const Text('Входящие запросы', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        StreamBuilder<List<WishRequest>>(
          stream: wishesRepo.watchIncomingWishRequests(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final list = snapshot.data!;
            if (list.isEmpty) return const Text('Нет входящих запросов');
            return Column(
              children: list.map((req) => _IncomingRequestTile(request: req, partnersRepo: partnersRepo, wishesRepo: wishesRepo)).toList(),
            );
          },
        ),
        const SizedBox(height: 24),
        const Text('Мои запросы', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        StreamBuilder<List<WishRequest>>(
          stream: wishesRepo.watchOutgoingWishRequests(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final list = snapshot.data!;
            if (list.isEmpty) return const Text('Нет отправленных запросов');
            return Column(
              children: list.map((req) => _OutgoingRequestTile(request: req, partnersRepo: partnersRepo, wishesRepo: wishesRepo)).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _IncomingRequestTile extends StatelessWidget {
  const _IncomingRequestTile({required this.request, required this.partnersRepo, required this.wishesRepo});
  final WishRequest request;
  final PartnersRepository partnersRepo;
  final WishesRepository wishesRepo;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserProfile?>(
      future: partnersRepo.getProfile(request.fromUserId),
      builder: (context, snapshot) {
        final name = snapshot.data?.displayLabel ?? request.fromUserId;
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text('$name просит ваши пожелания на ближайшее время'),
            subtitle: request.status == WishRequestStatus.answered
                ? const Text('Вы ответили')
                : null,
            trailing: request.status == WishRequestStatus.pending
                ? FilledButton(
                    onPressed: () async {
                      await wishesRepo.markWishRequestAnswered(request.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Запрос отмечен как отвеченный. Отметьте желания «на ближайшее время» во вкладке «Мой список».')),
                        );
                      }
                    },
                    child: const Text('Ответил'),
                  )
                : null,
          ),
        );
      },
    );
  }
}

class _OutgoingRequestTile extends StatelessWidget {
  const _OutgoingRequestTile({required this.request, required this.partnersRepo, required this.wishesRepo});
  final WishRequest request;
  final PartnersRepository partnersRepo;
  final WishesRepository wishesRepo;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserProfile?>(
      future: partnersRepo.getProfile(request.toUserId),
      builder: (context, snapshot) {
        final name = snapshot.data?.displayLabel ?? request.toUserId;
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(name),
            subtitle: request.status == WishRequestStatus.answered
                ? const Text('Партнёр ответил')
                : const Text('Ожидает ответа'),
            trailing: request.status == WishRequestStatus.answered
                ? TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (context) => _PartnerNearFutureWishesPage(
                          partnerUserId: request.toUserId,
                          partnerName: name,
                          wishesRepo: wishesRepo,
                        ),
                      ),
                    ),
                    child: const Text('Посмотреть'),
                  )
                : null,
          ),
        );
      },
    );
  }
}
