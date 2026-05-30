import 'package:flutter/material.dart';
import 'package:sexpedition_application_1/data/kink_quiz_catalog.dart';
import 'package:sexpedition_application_1/l10n/app_localizations.dart';
import 'package:sexpedition_application_1/models/kink_quiz_result.dart';
import 'package:sexpedition_application_1/services/kink_quiz_repository.dart';

class KinkQuizScreen extends StatefulWidget {
  const KinkQuizScreen({super.key});

  @override
  State<KinkQuizScreen> createState() => _KinkQuizScreenState();
}

class _KinkQuizScreenState extends State<KinkQuizScreen> {
  final KinkQuizRepository _repo = KinkQuizRepository();
  final Map<String, KinkQuizAnswer> _answers = {};
  String? _resultId;
  bool _visibleToPartners = false;
  String? _hydratedResultId;
  DateTime? _hydratedUpdatedAt;
  bool _saving = false;

  List<KinkQuizItem> get _items => enabledKinkQuizItems();

  int get _maxScore => kinkQuizMaxScore();

  int get _score {
    var total = 0;
    for (final item in _items) {
      final answer = _answers[item.id] ?? const KinkQuizAnswer();
      if (answer.tried) total += item.weightTried;
      if (answer.loved) total += item.weightLoved;
    }
    return total;
  }

  double get _ratio => _maxScore == 0 ? 0 : _score / _maxScore;

  KinkQuizLevel get _level {
    final ratio = _ratio;
    if (ratio >= 0.85) return KinkQuizLevel.max;
    if (ratio >= 0.55) return KinkQuizLevel.high;
    if (ratio >= 0.25) return KinkQuizLevel.medium;
    return KinkQuizLevel.low;
  }

  void _syncWithStoredResult(KinkQuizResult? result) {
    if (result == null) return;
    if (_hydratedResultId == result.id &&
        _hydratedUpdatedAt == result.updatedAt) {
      return;
    }
    _hydratedResultId = result.id;
    _hydratedUpdatedAt = result.updatedAt;
    _resultId = result.id;
    _visibleToPartners = result.visibleToPartners;
    _answers
      ..clear()
      ..addAll(result.answers);
  }

  void _setTried(String id, bool value) {
    final current = _answers[id] ?? const KinkQuizAnswer();
    setState(() {
      _answers[id] = KinkQuizAnswer(
        tried: value,
        loved: value ? current.loved : false,
      );
    });
  }

  void _setLoved(String id, bool value) {
    setState(() {
      _answers[id] = KinkQuizAnswer(
        tried: value ? true : (_answers[id]?.tried ?? false),
        loved: value,
      );
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final savedId = await _repo.saveResult(
        existingId: _resultId,
        answers: _answers,
        score: _score,
        maxScore: _maxScore,
        scoreRatio: _ratio,
        level: _level,
        visibleToPartners: _visibleToPartners,
      );
      if (!mounted) return;
      setState(() {
        _saving = false;
        _resultId = savedId ?? _resultId;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).saved)),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось сохранить анкету')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.kinkQuizTitle)),
      body: StreamBuilder<KinkQuizResult?>(
        stream: _repo.watchMyResult(),
        builder: (context, snapshot) {
          if (snapshot.hasData ||
              snapshot.connectionState != ConnectionState.waiting) {
            _syncWithStoredResult(snapshot.data);
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _ScoreCard(
                score: _score,
                maxScore: _maxScore,
                ratio: _ratio,
                level: _level,
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                value: _visibleToPartners,
                onChanged: (value) {
                  setState(() => _visibleToPartners = value);
                },
                title: Text(l.showPartner),
              ),
              const SizedBox(height: 12),
              for (final category in KinkQuizCategory.values)
                _CategorySection(
                  category: category,
                  items: _items
                      .where((item) => item.category == category)
                      .toList(),
                  answers: _answers,
                  onTriedChanged: _setTried,
                  onLovedChanged: _setLoved,
                ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(l.save),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({
    required this.score,
    required this.maxScore,
    required this.ratio,
    required this.level,
  });

  final int score;
  final int maxScore;
  final double ratio;
  final KinkQuizLevel level;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.score, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              '$score / $maxScore (${(ratio * 100).round()}%)',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: ratio.clamp(0, 1)),
            const SizedBox(height: 12),
            Text(_levelTitle(l, level)),
            const SizedBox(height: 4),
            Text(_levelDescription(l, level)),
          ],
        ),
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  const _CategorySection({
    required this.category,
    required this.items,
    required this.answers,
    required this.onTriedChanged,
    required this.onLovedChanged,
  });

  final KinkQuizCategory category;
  final List<KinkQuizItem> items;
  final Map<String, KinkQuizAnswer> answers;
  final void Function(String id, bool value) onTriedChanged;
  final void Function(String id, bool value) onLovedChanged;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final l = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _categoryTitle(l, category),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            for (final item in items)
              _QuizItemTile(
                item: item,
                answer: answers[item.id] ?? const KinkQuizAnswer(),
                onTriedChanged: (value) => onTriedChanged(item.id, value),
                onLovedChanged: (value) => onLovedChanged(item.id, value),
              ),
          ],
        ),
      ),
    );
  }
}

class _QuizItemTile extends StatelessWidget {
  const _QuizItemTile({
    required this.item,
    required this.answer,
    required this.onTriedChanged,
    required this.onLovedChanged,
  });

  final KinkQuizItem item;
  final KinkQuizAnswer answer;
  final ValueChanged<bool> onTriedChanged;
  final ValueChanged<bool> onLovedChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(_practiceTitle(l, item.titleKey)),
          Wrap(
            spacing: 8,
            children: [
              FilterChip(
                label: Text(l.tried),
                selected: answer.tried,
                onSelected: onTriedChanged,
              ),
              FilterChip(
                label: Text(l.loved),
                selected: answer.loved,
                onSelected: onLovedChanged,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _categoryTitle(AppLocalizations l, KinkQuizCategory category) {
  switch (category) {
    case KinkQuizCategory.classic:
      return l.categoryClassic;
    case KinkQuizCategory.oral:
      return l.categoryOral;
    case KinkQuizCategory.anal:
      return l.categoryAnal;
    case KinkQuizCategory.bdsm:
      return l.categoryBdsm;
    case KinkQuizCategory.group:
      return l.categoryGroup;
    case KinkQuizCategory.roleplay:
      return l.categoryRoleplay;
    case KinkQuizCategory.toys:
      return l.categoryToys;
    case KinkQuizCategory.sensory:
      return l.categorySensory;
    case KinkQuizCategory.publicFantasy:
      return l.categoryPublicFantasy;
    case KinkQuizCategory.romantic:
      return l.categoryRomantic;
  }
}

String _levelTitle(AppLocalizations l, KinkQuizLevel level) {
  switch (level) {
    case KinkQuizLevel.low:
      return l.levelLow;
    case KinkQuizLevel.medium:
      return l.levelMedium;
    case KinkQuizLevel.high:
      return l.levelHigh;
    case KinkQuizLevel.max:
      return l.levelMax;
  }
}

String _levelDescription(AppLocalizations l, KinkQuizLevel level) {
  switch (level) {
    case KinkQuizLevel.low:
      return l.levelDescriptionLow;
    case KinkQuizLevel.medium:
      return l.levelDescriptionMedium;
    case KinkQuizLevel.high:
      return l.levelDescriptionHigh;
    case KinkQuizLevel.max:
      return l.levelDescriptionMax;
  }
}

String _practiceTitle(AppLocalizations l, String key) {
  switch (key) {
    case 'practiceClassicSex':
      return l.practiceClassicSex;
    case 'practiceMissionary':
      return l.practiceMissionary;
    case 'practiceCowgirl':
      return l.practiceCowgirl;
    case 'practiceSideways':
      return l.practiceSideways;
    case 'practiceSpoons':
      return l.practiceSpoons;
    case 'practiceBlowjob':
      return l.practiceBlowjob;
    case 'practiceCunnilingus':
      return l.practiceCunnilingus;
    case 'practiceSixtyNine':
      return l.practiceSixtyNine;
    case 'practiceOralOnly':
      return l.practiceOralOnly;
    case 'practiceAnalSex':
      return l.practiceAnalSex;
    case 'practiceAnalPlay':
      return l.practiceAnalPlay;
    case 'practiceAnalToys':
      return l.practiceAnalToys;
    case 'practiceBondage':
      return l.practiceBondage;
    case 'practiceDominance':
      return l.practiceDominance;
    case 'practiceSpanking':
      return l.practiceSpanking;
    case 'practiceSafeword':
      return l.practiceSafeword;
    case 'practiceThreesome':
      return l.practiceThreesome;
    case 'practiceGroupSex':
      return l.practiceGroupSex;
    case 'practiceSwing':
      return l.practiceSwing;
    case 'practiceRoleplay':
      return l.practiceRoleplay;
    case 'practiceCostumes':
      return l.practiceCostumes;
    case 'practicePowerScenario':
      return l.practicePowerScenario;
    case 'practiceVibrator':
      return l.practiceVibrator;
    case 'practiceDildo':
      return l.practiceDildo;
    case 'practiceHandcuffs':
      return l.practiceHandcuffs;
    case 'practiceBlindfold':
      return l.practiceBlindfold;
    case 'practiceMassage':
      return l.practiceMassage;
    case 'practiceTemperature':
      return l.practiceTemperature;
    case 'practiceMusicMood':
      return l.practiceMusicMood;
    case 'practiceWindow':
      return l.practiceWindow;
    case 'practiceBalcony':
      return l.practiceBalcony;
    case 'practiceCar':
      return l.practiceCar;
    case 'practiceLongKisses':
      return l.practiceLongKisses;
    case 'practiceSlowTempo':
      return l.practiceSlowTempo;
    case 'practiceAftercare':
      return l.practiceAftercare;
    case 'practiceShowerTogether':
      return l.practiceShowerTogether;
    default:
      return key;
  }
}
