import 'package:flutter/material.dart';
import 'package:sexpedition_application_1/data/kamasutra_poses.dart';
import 'package:sexpedition_application_1/models/calendar_event.dart' show sexTypeLabels;
import 'package:sexpedition_application_1/models/partner_connection.dart';
import 'package:sexpedition_application_1/models/user_profile.dart';
import 'package:sexpedition_application_1/models/user_toy.dart';
import 'package:sexpedition_application_1/models/wish.dart';
import 'package:sexpedition_application_1/models/wish_request.dart';
import 'package:sexpedition_application_1/services/partners_repository.dart';
import 'package:sexpedition_application_1/services/user_toys_repository.dart';
import 'package:sexpedition_application_1/services/wishes_repository.dart';

class WishesScreen extends StatefulWidget {
  const WishesScreen({super.key});

  @override
  State<WishesScreen> createState() => _WishesScreenState();
}

class _WishesScreenState extends State<WishesScreen> with SingleTickerProviderStateMixin {
  final WishesRepository _wishesRepo = WishesRepository();
  final PartnersRepository _partnersRepo = PartnersRepository();
  final UserToysRepository _toysRepo = UserToysRepository();
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
          _MyWishesList(stream: _myWishesStream, repo: _wishesRepo, toysRepo: _toysRepo),
          _PartnersWishesTab(partnersRepo: _partnersRepo, wishesRepo: _wishesRepo),
          _WishRequestsTab(partnersRepo: _partnersRepo, wishesRepo: _wishesRepo),
        ],
      ),
    );
  }
}

class _MyWishesList extends StatelessWidget {
  const _MyWishesList({required this.stream, required this.repo, required this.toysRepo});
  final Stream<List<Wish>> stream;
  final WishesRepository repo;
  final UserToysRepository toysRepo;

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
                  onPressed: () => _showAddOrEditWishDialog(context, repo, toysRepo, null),
                  icon: const Icon(Icons.add),
                  label: const Text('Добавить желание'),
                ),
              );
            }
            final wish = list[i - 1];
            return _WishTile(
              wish: wish,
              repo: repo,
              onTap: () => _showAddOrEditWishDialog(context, repo, toysRepo, wish),
            );
          },
        );
      },
    );
  }
}

String _wishTileTitle(Wish wish) {
  if (wish.type == WishType.action) {
    if (wish.content.trim().isNotEmpty) return wish.content;
    if (wish.sexTypes.isNotEmpty) return 'Действие: ${wish.sexTypes.join(", ")}';
    if (wish.poseIds.isNotEmpty || wish.toyIds.isNotEmpty) return 'Действие (позы/игрушки)';
    return 'Действие';
  }
  return wish.content;
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
        title: Text(_wishTileTitle(wish)),
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

class _WishDialogResult {
  const _WishDialogResult({
    required this.type,
    required this.content,
    required this.isForNearFuture,
    required this.visibleToPartners,
    required this.sexTypes,
    required this.poseIds,
    required this.toyIds,
  });
  final WishType type;
  final String content;
  final bool isForNearFuture;
  final bool visibleToPartners;
  final List<String> sexTypes;
  final List<String> poseIds;
  final List<String> toyIds;
}

Future<void> _showAddOrEditWishDialog(BuildContext context, WishesRepository repo, UserToysRepository toysRepo, Wish? existing) async {
  final result = await showDialog<_WishDialogResult>(
    context: context,
    builder: (context) => _AddOrEditWishDialog(
      existing: existing,
      toysRepo: toysRepo,
    ),
  );

  if (result == null || !context.mounted) return;
  if (result.type != WishType.action && result.content.trim().isEmpty) return;
  if (result.type == WishType.action && result.sexTypes.isEmpty && result.poseIds.isEmpty && result.toyIds.isEmpty && result.content.trim().isEmpty) return;

  if (existing != null) {
    await repo.updateWish(existing.copyWith(
      type: result.type,
      content: result.content.trim(),
      isForNearFuture: result.isForNearFuture,
      visibleToPartners: result.visibleToPartners,
      sexTypes: result.sexTypes,
      poseIds: result.poseIds,
      toyIds: result.toyIds,
    ));
  } else {
    await repo.addWish(Wish(
      id: '',
      userId: '',
      type: result.type,
      content: result.content.trim(),
      isForNearFuture: result.isForNearFuture,
      visibleToPartners: result.visibleToPartners,
      createdAt: DateTime.now(),
      sexTypes: result.sexTypes,
      poseIds: result.poseIds,
      toyIds: result.toyIds,
    ));
  }
}

class _AddOrEditWishDialog extends StatefulWidget {
  const _AddOrEditWishDialog({this.existing, required this.toysRepo});
  final Wish? existing;
  final UserToysRepository toysRepo;

  @override
  State<_AddOrEditWishDialog> createState() => _AddOrEditWishDialogState();
}

class _AddOrEditWishDialogState extends State<_AddOrEditWishDialog> {
  late WishType _type;
  late TextEditingController _contentController;
  late bool _isForNearFuture;
  late bool _visibleToPartners;
  late Set<int> _sexTypeIndices;
  late Set<String> _poseIds;
  late Set<String> _toyIds;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _type = e?.type ?? WishType.action;
    _contentController = TextEditingController(text: e?.content ?? '');
    _isForNearFuture = e?.isForNearFuture ?? false;
    _visibleToPartners = e?.visibleToPartners ?? true;
    _sexTypeIndices = {};
    if (e?.sexTypes != null) {
      for (final t in e!.sexTypes) {
        final i = sexTypeLabels.indexOf(t);
        if (i >= 0) _sexTypeIndices.add(i);
      }
    }
    _poseIds = Set.from(e?.poseIds ?? []);
    _toyIds = Set.from(e?.toyIds ?? []);
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  void _toggleSexType(int index) {
    setState(() {
      if (_sexTypeIndices.contains(index)) {
        _sexTypeIndices.remove(index);
      } else {
        _sexTypeIndices.add(index);
      }
    });
  }

  void _togglePose(String id) {
    setState(() {
      if (_poseIds.contains(id)) {
        _poseIds.remove(id);
      } else {
        _poseIds.add(id);
      }
    });
  }

  void _toggleToy(String id) {
    setState(() {
      if (_toyIds.contains(id)) {
        _toyIds.remove(id);
      } else {
        _toyIds.add(id);
      }
    });
  }

  List<String> get _sexTypes => _sexTypeIndices.map((i) => sexTypeLabels[i]).toList();

  void _onSave() {
    if (_type != WishType.action && _contentController.text.trim().isEmpty) return;
    if (_type == WishType.action && _sexTypes.isEmpty && _poseIds.isEmpty && _toyIds.isEmpty && _contentController.text.trim().isEmpty) return;
    Navigator.of(context).pop(_WishDialogResult(
      type: _type,
      content: _contentController.text.trim(),
      isForNearFuture: _isForNearFuture,
      visibleToPartners: _visibleToPartners,
      sexTypes: _sexTypes,
      poseIds: _poseIds.toList(),
      toyIds: _toyIds.toList(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return AlertDialog(
      title: Text(isEdit ? 'Редактировать желание' : 'Добавить желание'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<WishType>(
              value: _type,
              decoration: const InputDecoration(labelText: 'Тип'),
              items: WishType.values
                  .map((t) => DropdownMenuItem(value: t, child: Text(Wish(type: t, id: '', userId: '', content: '', createdAt: DateTime.now()).typeLabel)))
                  .toList(),
              onChanged: (v) => setState(() => _type = v ?? _type),
            ),
            const SizedBox(height: 16),
            if (_type == WishType.action) ...[
              Text('Тип секса', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: List.generate(sexTypeLabels.length, (i) {
                  final selected = _sexTypeIndices.contains(i);
                  return FilterChip(
                    label: Text(sexTypeLabels[i]),
                    selected: selected,
                    onSelected: (_) => _toggleSexType(i),
                  );
                }),
              ),
              const SizedBox(height: 16),
              Text('Позы', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 6),
              SizedBox(
                height: 120,
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final p in kamasutraPoses)
                        CheckboxListTile(
                          title: Text(p.label),
                          value: _poseIds.contains(p.id),
                          onChanged: (_) => _togglePose(p.id),
                          controlAffinity: ListTileControlAffinity.leading,
                          dense: true,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              StreamBuilder<List<UserToy>>(
                stream: widget.toysRepo.watchToys(),
                builder: (context, snap) {
                  final toys = snap.data ?? [];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Text('Игрушки', style: Theme.of(context).textTheme.titleSmall),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Добавить'),
                            onPressed: () => _showAddToyDialog(context, toys),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (toys.isEmpty)
                        const Text('Список пуст. Нажмите «Добавить».', style: TextStyle(fontSize: 12, color: Colors.grey))
                      else
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: toys.map((t) {
                            final selected = _toyIds.contains(t.id);
                            return FilterChip(
                              label: Text(t.name),
                              selected: selected,
                              onSelected: (_) => _toggleToy(t.id),
                            );
                          }).toList(),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: 'Заметка (необязательно)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ] else ...[
              TextField(
                controller: _contentController,
                decoration: InputDecoration(
                  labelText: _type == WishType.movie ? 'Ссылка на фильм' : 'Вещь',
                  hintText: _type == WishType.movie ? 'https://...' : null,
                  border: const OutlineInputBorder(),
                ),
                maxLines: _type == WishType.movie ? 1 : 2,
                keyboardType: _type == WishType.movie ? TextInputType.url : null,
              ),
            ],
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('На ближайшее время'),
              value: _isForNearFuture,
              onChanged: (v) => setState(() => _isForNearFuture = v),
            ),
            SwitchListTile(
              title: const Text('Показывать партнёрам'),
              value: _visibleToPartners,
              onChanged: (v) => setState(() => _visibleToPartners = v),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
        FilledButton(onPressed: _onSave, child: Text(isEdit ? 'Сохранить' : 'Добавить')),
      ],
    );
  }

  Future<void> _showAddToyDialog(BuildContext context, List<UserToy> toys) async {
    final nameController = TextEditingController();
    final added = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Новая игрушка'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Название', border: OutlineInputBorder()),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Отмена')),
          FilledButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              await widget.toysRepo.addToy(name);
              if (ctx.mounted) Navigator.of(ctx).pop(true);
            },
            child: const Text('Добавить'),
          ),
        ],
      ),
    );
    if (added == true && mounted) setState(() {});
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
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Ошибка загрузки: ${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            );
          }
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
                  leading: Icon(
                    w.type == WishType.movie ? Icons.movie : (w.type == WishType.thing ? Icons.card_giftcard : Icons.star),
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(_wishTileTitle(w), maxLines: 2, overflow: TextOverflow.ellipsis),
                  subtitle: Text(w.typeLabel),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showPartnerWishDetail(context, partnerName, w),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

void _showPartnerWishDetail(BuildContext context, String partnerName, Wish w) {
  final theme = Theme.of(context);
  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          Icon(
            w.type == WishType.movie ? Icons.movie : (w.type == WishType.thing ? Icons.card_giftcard : Icons.star),
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text('Пожелание от $partnerName')),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Тип', style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary)),
                    const SizedBox(height: 4),
                    Text(w.typeLabel, style: theme.textTheme.bodyLarge),
                    if (w.isForNearFuture) ...[
                      const SizedBox(height: 8),
                      Chip(
                        label: const Text('На ближайшее время'),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (w.type == WishType.action && (w.sexTypes.isNotEmpty || w.poseIds.isNotEmpty || w.toyIds.isNotEmpty)) ...[
              if (w.sexTypes.isNotEmpty) ...[
                const SizedBox(height: 12),
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Тип секса', style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary)),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: w.sexTypes.map((t) => Chip(label: Text(t), materialTapTargetSize: MaterialTapTargetSize.shrinkWrap)).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              if (w.poseIds.isNotEmpty) ...[
                const SizedBox(height: 12),
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Позы', style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary)),
                        const SizedBox(height: 4),
                        Text(
                          w.poseIds.map((id) {
                            try {
                              return kamasutraPoses.firstWhere((p) => p.id == id).label;
                            } catch (_) {
                              return id;
                            }
                          }).join(', '),
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              if (w.toyIds.isNotEmpty) ...[
                const SizedBox(height: 12),
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Игрушки', style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary)),
                        const SizedBox(height: 4),
                        Text('Выбрано: ${w.toyIds.length}', style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ),
              ],
            ],
            if (w.content.trim().isNotEmpty || (w.type != WishType.action)) ...[
              const SizedBox(height: 12),
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        w.type == WishType.movie ? 'Ссылка на фильм' : (w.type == WishType.action ? 'Заметка' : 'Описание'),
                        style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary),
                      ),
                      const SizedBox(height: 4),
                      SelectableText(w.content, style: theme.textTheme.bodyMedium),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Добавлено', style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary)),
                    const SizedBox(height: 4),
                    Text(
                      '${w.createdAt.day}.${w.createdAt.month}.${w.createdAt.year}',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Закрыть'),
        ),
      ],
    ),
  );
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
