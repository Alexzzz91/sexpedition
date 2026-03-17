import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sexpedition_application_1/data/kamasutra_poses.dart';
import 'package:sexpedition_application_1/models/calendar_event.dart';
import 'package:sexpedition_application_1/models/user_toy.dart';
import 'package:sexpedition_application_1/services/user_toys_repository.dart';

sealed class AddEventDialogResult {}

class AddEventDialogSaveSexRecord extends AddEventDialogResult {
  AddEventDialogSaveSexRecord({
    required this.date,
    this.partnerId,
    required this.sexTypes,
    required this.poseIds,
    required this.toyIds,
    this.durationMinutes,
    this.satisfactionRating,
    this.note,
  });
  final DateTime date;
  final String? partnerId;
  final List<String> sexTypes;
  final List<String> poseIds;
  final List<String> toyIds;
  final int? durationMinutes;
  final int? satisfactionRating;
  final String? note;
}

class AddEventDialogSaveWish extends AddEventDialogResult {
  AddEventDialogSaveWish({
    required this.date,
    required this.sexTypes,
    this.contentLink,
    this.contentText,
    this.imageUrl,
    this.visibleToPartners = true,
  });
  final DateTime date;
  final List<String> sexTypes;
  final String? contentLink;
  final String? contentText;
  final String? imageUrl;
  final bool visibleToPartners;
}

class AddEventDialogDelete extends AddEventDialogResult {}

class AddEventDialogCancel extends AddEventDialogResult {}

/// Шаг диалога: выбор типа -> (опционально выбор пожелания) -> форма записи о сексе или форма пожелания.
enum _Step { choice, choosePartnerWish, sexRecord, wishToday }

class CalendarAddEventDialog extends StatefulWidget {
  const CalendarAddEventDialog({
    super.key,
    required this.date,
    this.existing,
    this.prefillFromWish,
    this.partnerWishesForDay = const [],
    required this.partnersList,
    required this.toysRepository,
    required this.uploadImage,
    this.startAtWishToday = false,
    this.complementToPartnerLabel,
  });

  final DateTime date;
  final CalendarEvent? existing;
  /// Предзаполнение из пожелания партнёра (при открытии из просмотра пожелания).
  final CalendarEvent? prefillFromWish;
  /// Пожелания партнёров за день (для шага «Запись о сексе по пожеланию»).
  final List<CalendarEvent> partnerWishesForDay;
  final List<({String userId, String label})> partnersList;
  final UserToysRepository toysRepository;
  final Future<String?> Function(File file) uploadImage;
  /// Открыть сразу форму «Пожелание на сегодня» (например, из просмотра пожелания партнёра).
  final bool startAtWishToday;
  /// Подпись «В дополнение к пожеланию от [label]» в форме пожелания.
  final String? complementToPartnerLabel;

  @override
  State<CalendarAddEventDialog> createState() => _CalendarAddEventDialogState();
}

class _CalendarAddEventDialogState extends State<CalendarAddEventDialog> {
  late _Step _step;
  /// Выбранное пожелание партнёра для предзаполнения (шаг «Запись о сексе по пожеланию»).
  CalendarEvent? _selectedWishForPrefill;

  @override
  void initState() {
    super.initState();
    if (widget.prefillFromWish != null) {
      _step = _Step.sexRecord;
      return;
    }
    if (widget.existing != null) {
      if (widget.existing!.isSexRecord) {
        _step = _Step.sexRecord;
      } else if (widget.existing!.isWishToday) {
        _step = _Step.wishToday;
      } else {
        _step = _Step.choice;
      }
    } else if (widget.startAtWishToday) {
      _step = _Step.wishToday;
    } else {
      _step = _Step.choice;
    }
  }

  void _goToChoice() {
    setState(() {
      _step = _Step.choice;
      _selectedWishForPrefill = null;
    });
  }

  void _goToChoosePartnerWish() {
    setState(() => _step = _Step.choosePartnerWish);
  }

  void _goToSexRecordFromWish(CalendarEvent wish) {
    setState(() {
      _selectedWishForPrefill = wish;
      _step = _Step.sexRecord;
    });
  }

  void _goBackFromSexRecordWhenFromWishList() {
    setState(() {
      _step = _Step.choosePartnerWish;
      _selectedWishForPrefill = null;
    });
  }

  void _goToSexRecord() {
    setState(() => _step = _Step.sexRecord);
  }

  void _goToWishToday() {
    setState(() => _step = _Step.wishToday);
  }

  CalendarEvent? get _effectivePrefill => widget.prefillFromWish ?? _selectedWishForPrefill;

  @override
  Widget build(BuildContext context) {
    if (_step == _Step.choice) {
      return _buildChoiceStep(context);
    }
    if (_step == _Step.choosePartnerWish) {
      return _buildChoosePartnerWishStep(context);
    }
    if (_step == _Step.sexRecord) {
      final prefill = _effectivePrefill;
      final fromWishList = _selectedWishForPrefill != null;
      return _SexRecordForm(
        date: widget.date,
        existing: (widget.existing?.isSexRecord == true || widget.existing?.isLegacy == true) ? widget.existing : null,
        prefillFromWish: prefill,
        partnersList: widget.partnersList,
        toysRepository: widget.toysRepository,
        onBack: widget.existing != null
            ? null
            : (fromWishList ? _goBackFromSexRecordWhenFromWishList : _goToChoice),
        onSave: (r) => Navigator.of(context).pop(r),
        onDelete: widget.existing != null ? () => Navigator.of(context).pop(AddEventDialogDelete()) : null,
        onCancel: () => Navigator.of(context).pop(AddEventDialogCancel()),
      );
    }
    return _WishTodayForm(
      date: widget.date,
      existing: widget.existing?.isWishToday == true ? widget.existing : null,
      uploadImage: widget.uploadImage,
      complementToPartnerLabel: widget.complementToPartnerLabel,
      onBack: widget.existing == null ? _goToChoice : null,
      onSave: (r) => Navigator.of(context).pop(r),
      onCancel: () => Navigator.of(context).pop(AddEventDialogCancel()),
    );
  }

  Widget _buildChoiceStep(BuildContext context) {
    return AlertDialog(
      title: const Text('Добавить событие'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 300),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
          Text('Дата: ${widget.date.day}.${widget.date.month}.${widget.date.year}', style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            icon: const Icon(Icons.favorite),
            label: const Text('Запись о сексе'),
            onPressed: _goToSexRecord,
            style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            icon: const Icon(Icons.card_giftcard),
            label: const Text('Пожелание на сегодня'),
            onPressed: _goToWishToday,
            style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            icon: const Icon(Icons.favorite_border),
            label: const Text('Запись о сексе по пожеланию'),
            onPressed: _goToChoosePartnerWish,
            style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
          ),
        ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(AddEventDialogCancel()),
          child: const Text('Отмена'),
        ),
      ],
    );
  }

  Widget _buildChoosePartnerWishStep(BuildContext context) {
    return AlertDialog(
      title: const Text('Выберите пожелание партнёра'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 300),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Дата: ${widget.date.day}.${widget.date.month}.${widget.date.year}', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            if (widget.partnerWishesForDay.isEmpty)
              const Text('Нет пожеланий партнёров на этот день.')
            else
              ...widget.partnerWishesForDay.map((w) {
                final title = w.contentText?.isNotEmpty == true
                    ? w.contentText!
                    : (w.sexTypes.isNotEmpty ? w.sexTypes.join(', ') : 'Пожелание');
                return ListTile(
                  title: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
                  subtitle: w.sexTypes.isNotEmpty ? Text('Тип: ${w.sexTypes.join(", ")}', style: Theme.of(context).textTheme.bodySmall) : null,
                  onTap: () => _goToSexRecordFromWish(w),
                );
              }),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _goToChoice,
          child: const Text('Назад'),
        ),
      ],
    );
  }
}

// --- Sex record form ---

class _SexRecordForm extends StatefulWidget {
  const _SexRecordForm({
    required this.date,
    this.existing,
    this.prefillFromWish,
    required this.partnersList,
    required this.toysRepository,
    this.onBack,
    required this.onSave,
    this.onDelete,
    required this.onCancel,
  });

  final DateTime date;
  final CalendarEvent? existing;
  /// Предзаполнение из пожелания партнёра (тип секса, партнёр).
  final CalendarEvent? prefillFromWish;
  final List<({String userId, String label})> partnersList;
  final UserToysRepository toysRepository;
  final VoidCallback? onBack;
  final void Function(AddEventDialogSaveSexRecord) onSave;
  final VoidCallback? onDelete;
  final VoidCallback onCancel;

  @override
  State<_SexRecordForm> createState() => _SexRecordFormState();
}

class _SexRecordFormState extends State<_SexRecordForm> {
  String? _partnerId;
  final Set<int> _sexTypeIndices = {};
  final Set<String> _poseIds = {};
  final Set<String> _toyIds = {};
  final _durationController = TextEditingController();
  int? _satisfactionRating;
  final _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _partnerId = e.partnerId;
      for (final t in e.sexTypes) {
        final i = sexTypeLabels.indexOf(t);
        if (i >= 0) _sexTypeIndices.add(i);
      }
      _poseIds.addAll(e.poseIds);
      _toyIds.addAll(e.toyIds);
      if (e.durationMinutes != null) _durationController.text = e.durationMinutes.toString();
      _satisfactionRating = e.satisfactionRating;
      _noteController.text = e.note ?? '';
    } else {
      final prefill = widget.prefillFromWish;
      if (prefill != null) {
        _partnerId = prefill.userId;
        for (final t in prefill.sexTypes) {
          final i = sexTypeLabels.indexOf(t);
          if (i >= 0) _sexTypeIndices.add(i);
        }
      }
    }
  }

  @override
  void dispose() {
    _durationController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  List<String> get _sexTypes => _sexTypeIndices.map((i) => sexTypeLabels[i]).toList();

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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          if (widget.onBack != null)
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: widget.onBack,
            ),
          Expanded(child: Text(widget.existing != null ? 'Редактировать запись о сексе' : 'Запись о сексе')),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 300),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Дата: ${widget.date.day}.${widget.date.month}.${widget.date.year}', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            if (widget.partnersList.isNotEmpty) ...[
              DropdownButtonFormField<String?>(
                value: _partnerId,
                decoration: const InputDecoration(labelText: 'Партнёр', border: OutlineInputBorder()),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Не выбран')),
                  ...widget.partnersList.map((p) => DropdownMenuItem(value: p.userId, child: Text(p.label))),
                ],
                onChanged: (v) => setState(() => _partnerId = v),
              ),
              const SizedBox(height: 16),
            ],
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
              stream: widget.toysRepository.watchToys(),
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
            const SizedBox(height: 16),
            TextField(
              controller: _durationController,
              decoration: const InputDecoration(
                labelText: 'Длительность (минуты)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            Text('Оценка удовлетворённости (1–5)', style: Theme.of(context).textTheme.titleSmall),
            Row(
              children: List.generate(5, (i) {
                final value = i + 1;
                final selected = _satisfactionRating == value;
                return IconButton(
                  icon: Icon(selected ? Icons.star : Icons.star_border),
                  color: selected ? Colors.amber : null,
                  onPressed: () => setState(() => _satisfactionRating = selected ? null : value),
                );
              }),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(labelText: 'Заметка', border: OutlineInputBorder()),
              maxLines: 2,
            ),
          ],
        ),
        ),
      ),
      actions: [
        if (widget.onDelete != null)
          TextButton(
            onPressed: widget.onDelete,
            child: Text('Удалить', style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        TextButton(onPressed: widget.onCancel, child: const Text('Отмена')),
        FilledButton(
          onPressed: () {
            final duration = int.tryParse(_durationController.text.trim());
            widget.onSave(AddEventDialogSaveSexRecord(
              date: widget.date,
              partnerId: _partnerId,
              sexTypes: _sexTypes,
              poseIds: _poseIds.toList(),
              toyIds: _toyIds.toList(),
              durationMinutes: duration,
              satisfactionRating: _satisfactionRating,
              note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
            ));
          },
          child: Text(widget.existing != null ? 'Сохранить' : 'Добавить'),
        ),
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
              await widget.toysRepository.addToy(name);
              if (ctx.mounted) Navigator.of(ctx).pop(true);
            },
            child: const Text('Добавить'),
          ),
        ],
      ),
    );
    if (added == true && mounted) {
      // После добавления список обновится по stream; можно выделить новую игрушку по имени, но id не знаем — пользователь выберет в чипах.
      setState(() {});
    }
  }
}

// --- Wish today form ---

class _WishTodayForm extends StatefulWidget {
  const _WishTodayForm({
    required this.date,
    this.existing,
    required this.uploadImage,
    this.complementToPartnerLabel,
    this.onBack,
    required this.onSave,
    required this.onCancel,
  });

  final DateTime date;
  final CalendarEvent? existing;
  final Future<String?> Function(File file) uploadImage;
  /// Если задано, показываем подпись «В дополнение к пожеланию от [label]».
  final String? complementToPartnerLabel;
  final VoidCallback? onBack;
  final void Function(AddEventDialogSaveWish) onSave;
  final VoidCallback onCancel;

  @override
  State<_WishTodayForm> createState() => _WishTodayFormState();
}

class _WishTodayFormState extends State<_WishTodayForm> {
  final Set<int> _sexTypeIndices = {};
  final _linkController = TextEditingController();
  final _textController = TextEditingController();
  String? _imageUrl;
  File? _pickedFile;
  bool _visibleToPartners = true;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      for (final t in e.sexTypes) {
        final i = sexTypeLabels.indexOf(t);
        if (i >= 0) _sexTypeIndices.add(i);
      }
      _linkController.text = e.contentLink ?? '';
      _textController.text = e.contentText ?? '';
      _imageUrl = e.imageUrl;
      _visibleToPartners = e.visibleToPartners;
    }
  }

  @override
  void dispose() {
    _linkController.dispose();
    _textController.dispose();
    super.dispose();
  }

  List<String> get _sexTypes => _sexTypeIndices.map((i) => sexTypeLabels[i]).toList();

  void _toggleSexType(int index) {
    setState(() {
      if (_sexTypeIndices.contains(index)) {
        _sexTypeIndices.remove(index);
      } else {
        _sexTypeIndices.add(index);
      }
    });
  }

  Future<void> _pickAndUploadImage() async {
    final picker = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picker == null || !mounted) return;
    final file = File(picker.path);
    setState(() => _uploading = true);
    try {
      final url = await widget.uploadImage(file);
      if (mounted) setState(() { _imageUrl = url; _pickedFile = file; _uploading = false; });
    } catch (_) {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final endDate = widget.date.add(const Duration(days: 2));
    return AlertDialog(
      title: Row(
        children: [
          if (widget.onBack != null)
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: widget.onBack,
            ),
          Expanded(child: Text(widget.existing != null ? 'Редактировать пожелание' : 'Пожелание на сегодня')),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 300),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.complementToPartnerLabel != null) ...[
                Card(
                  color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5),
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        Icon(Icons.add_circle_outline, size: 20, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'В дополнение к пожеланию от ${widget.complementToPartnerLabel}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Text(
                'На ближайшие 2 дня: ${widget.date.day}.${widget.date.month} — ${endDate.day}.${endDate.month}.${endDate.year}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
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
            TextField(
              controller: _linkController,
              decoration: const InputDecoration(
                labelText: 'Ссылка на фильм или игрушку',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _textController,
              decoration: const InputDecoration(
                labelText: 'Текст пожелания',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            if (_imageUrl != null || _pickedFile != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    if (_pickedFile != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(_pickedFile!, width: 64, height: 64, fit: BoxFit.cover),
                      )
                    else if (_imageUrl != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(_imageUrl!, width: 64, height: 64, fit: BoxFit.cover),
                      ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => setState(() { _imageUrl = null; _pickedFile = null; }),
                      child: const Text('Удалить'),
                    ),
                  ],
                ),
              ),
            OutlinedButton.icon(
              icon: _uploading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.add_photo_alternate),
              label: Text(_uploading ? 'Загрузка…' : 'Прикрепить изображение'),
              onPressed: _uploading ? null : _pickAndUploadImage,
            ),
            const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('Видно партнёрам'),
                value: _visibleToPartners,
                onChanged: (v) => setState(() => _visibleToPartners = v ?? true),
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: widget.onCancel, child: const Text('Отмена')),
        FilledButton(
          onPressed: () {
            widget.onSave(AddEventDialogSaveWish(
              date: widget.date,
              sexTypes: _sexTypes,
              contentLink: _linkController.text.trim().isEmpty ? null : _linkController.text.trim(),
              contentText: _textController.text.trim().isEmpty ? null : _textController.text.trim(),
              imageUrl: _imageUrl,
              visibleToPartners: _visibleToPartners,
            ));
          },
          child: Text(widget.existing != null ? 'Сохранить' : 'Создать'),
        ),
      ],
    );
  }
}
