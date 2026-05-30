import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:sexpedition_application_1/data/game_options.dart';
import 'package:sexpedition_application_1/data/kamasutra_poses.dart';
import 'package:sexpedition_application_1/data/truth_or_dare_prompts.dart';
import 'package:sexpedition_application_1/models/game_session.dart';
import 'package:sexpedition_application_1/services/game_sound_service.dart';
import 'package:sexpedition_application_1/services/game_stats_repository.dart';

enum _GameMode { scratchPose, dice, truthOrDare }

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  _GameMode? _mode;
  bool _visibleToPartners = false;

  @override
  Widget build(BuildContext context) {
    final mode = _mode;
    return Scaffold(
      appBar: AppBar(title: const Text('Игры')),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: mode == null
            ? _GameHub(
                visibleToPartners: _visibleToPartners,
                onVisibilityChanged: (value) {
                  setState(() => _visibleToPartners = value);
                },
                onSelect: (nextMode) => setState(() => _mode = nextMode),
              )
            : mode == _GameMode.scratchPose
            ? _ScratchPoseGame(
                key: const ValueKey('scratch'),
                visibleToPartners: _visibleToPartners,
                onBack: () => setState(() => _mode = null),
              )
            : mode == _GameMode.dice
            ? _DiceGame(
                key: const ValueKey('dice'),
                visibleToPartners: _visibleToPartners,
                onBack: () => setState(() => _mode = null),
              )
            : _TruthOrDareGame(
                key: const ValueKey('truth_or_dare'),
                visibleToPartners: _visibleToPartners,
                onBack: () => setState(() => _mode = null),
              ),
      ),
    );
  }
}

class _GameHub extends StatelessWidget {
  const _GameHub({
    required this.visibleToPartners,
    required this.onVisibilityChanged,
    required this.onSelect,
  });

  final bool visibleToPartners;
  final ValueChanged<bool> onVisibilityChanged;
  final ValueChanged<_GameMode> onSelect;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Выберите игру на сегодня',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          'Сыграйте в случайную позу, бросьте кубики или выберите «Правду или действие».',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          value: visibleToPartners,
          onChanged: onVisibilityChanged,
          title: const Text('Сохранять как видимое партнёру'),
          subtitle: const Text(
            'Статистика сохранится с флагом видимости для будущего общего просмотра.',
          ),
        ),
        const SizedBox(height: 16),
        _GameModeCard(
          icon: Icons.auto_awesome,
          title: 'Рандомная поза',
          description:
              'Сотрите верхний слой, откройте позу из камасутры и решите: принять или пропустить.',
          onTap: () => onSelect(_GameMode.scratchPose),
        ),
        const SizedBox(height: 12),
        _GameModeCard(
          icon: Icons.casino,
          title: 'Кубики',
          description:
              'Бросьте два кубика: один подскажет место, второй — позу или практику.',
          onTap: () => onSelect(_GameMode.dice),
        ),
        const SizedBox(height: 12),
        _GameModeCard(
          icon: Icons.question_answer,
          title: 'Правда или действие',
          description:
              'Тяните карточки с вопросами и заданиями, чтобы разогреть разговор и настроение.',
          onTap: () => onSelect(_GameMode.truthOrDare),
        ),
      ],
    );
  }
}

class _GameModeCard extends StatelessWidget {
  const _GameModeCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.2),
                child: Icon(icon, color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(description),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScratchPoseGame extends StatefulWidget {
  const _ScratchPoseGame({
    super.key,
    required this.visibleToPartners,
    required this.onBack,
  });

  final bool visibleToPartners;
  final VoidCallback onBack;

  @override
  State<_ScratchPoseGame> createState() => _ScratchPoseGameState();
}

class _ScratchPoseGameState extends State<_ScratchPoseGame>
    with SingleTickerProviderStateMixin {
  final GameStatsRepository _repo = GameStatsRepository();
  final List<Offset?> _scratchPoints = [];
  late final AnimationController _revealController;
  late final KamasutraPose _pose;
  late final DateTime _startedAt;
  Offset? _lastScratchPoint;
  double _scratchDistance = 0;
  String? _sessionId;
  bool _revealed = false;
  bool _saving = false;
  bool _isScratching = false;

  @override
  void initState() {
    super.initState();
    _pose = kamasutraPoses[Random().nextInt(kamasutraPoses.length)];
    _startedAt = DateTime.now();
    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _startSession();
  }

  @override
  void dispose() {
    _revealController.dispose();
    super.dispose();
  }

  Future<void> _startSession() async {
    _sessionId = await _repo.startScratchPoseSession(
      poseId: _pose.id,
      poseLabel: _pose.label,
      visibleToPartners: widget.visibleToPartners,
    );
  }

  void _scratch(Offset position) {
    if (_revealed) return;
    GameSoundService.instance.playScratch();
    setState(() {
      final previous = _lastScratchPoint;
      if (previous != null) {
        final distance = (position - previous).distance;
        if (distance < 3) return;
        _scratchDistance += distance;
      }
      _lastScratchPoint = position;
      _scratchPoints.add(position);
      if (_scratchProgress >= 1 && !_revealed) {
        _revealed = true;
        _isScratching = false;
        _lastScratchPoint = null;
        _revealController.forward();
      }
    });
  }

  void _startScratch(Offset position) {
    if (_revealed) return;
    setState(() {
      _isScratching = true;
      _scratchPoints.add(null);
      _lastScratchPoint = null;
    });
    _scratch(position);
  }

  void _stopScratch() {
    if (!_isScratching) return;
    setState(() {
      _isScratching = false;
      _lastScratchPoint = null;
    });
  }

  double get _scratchProgress {
    return (_scratchDistance / 2200).clamp(0, 1).toDouble();
  }

  Future<void> _complete(GameSessionStatus status) async {
    final sessionId = _sessionId;
    setState(() => _saving = true);
    if (sessionId != null) {
      await _repo.completeScratchPoseSession(
        sessionId: sessionId,
        status: status,
        startedAt: _startedAt,
      );
    }
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          status == GameSessionStatus.accepted
              ? 'Поза принята и сохранена в статистике'
              : 'Поза пропущена и сохранена в статистике',
        ),
      ),
    );
    widget.onBack();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: _isScratching ? const NeverScrollableScrollPhysics() : null,
      padding: const EdgeInsets.all(20),
      children: [
        _BackToGamesButton(onPressed: widget.onBack),
        const SizedBox(height: 12),
        Text('Сотрите слой', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        const Text('Под верхним слоем спрятана случайная поза.'),
        const SizedBox(height: 16),
        RepaintBoundary(
          child: AspectRatio(
            aspectRatio: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    FadeTransition(
                      opacity: Tween<double>(begin: 0.74, end: 1).animate(
                        CurvedAnimation(
                          parent: _revealController,
                          curve: Curves.easeOutCubic,
                        ),
                      ),
                      child: ScaleTransition(
                        scale: Tween<double>(begin: 0.97, end: 1).animate(
                          CurvedAnimation(
                            parent: _revealController,
                            curve: Curves.easeOutBack,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              Expanded(
                                child: SvgPicture.asset(_pose.imageAsset),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _pose.label,
                                style: Theme.of(context).textTheme.titleLarge,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _pose.description,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    AnimatedBuilder(
                      animation: _revealController,
                      builder: (context, _) {
                        final overlayOpacity = _revealed
                            ? 1 - _revealController.value
                            : 1.0;
                        if (overlayOpacity <= 0) return const SizedBox.shrink();

                        final overlay = Opacity(
                          opacity: overlayOpacity,
                          child: CustomPaint(
                            painter: _ScratchLayerPainter(
                              points: List<Offset?>.of(_scratchPoints),
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            child: Center(
                              child: AnimatedOpacity(
                                opacity: _scratchProgress < 0.18 ? 1 : 0,
                                duration: const Duration(milliseconds: 180),
                                child: const Text(
                                  'Сотрите пальцем',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),
                          ),
                        );

                        if (_revealed) {
                          return IgnorePointer(child: overlay);
                        }
                        return Listener(
                          behavior: HitTestBehavior.opaque,
                          onPointerDown: (event) =>
                              _startScratch(event.localPosition),
                          onPointerMove: (event) =>
                              _scratch(event.localPosition),
                          onPointerUp: (_) => _stopScratch(),
                          onPointerCancel: (_) => _stopScratch(),
                          child: overlay,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (!_revealed || _revealController.value < 1) ...[
          const SizedBox(height: 12),
          LinearProgressIndicator(value: _scratchProgress),
          const SizedBox(height: 6),
          Text(
            'Стирайте в разных местах: слой исчезает только по вашей траектории.',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
        if (_revealed) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _saving
                      ? null
                      : () => _complete(GameSessionStatus.skipped),
                  child: const Text('Пропускаю'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _saving
                      ? null
                      : () => _complete(GameSessionStatus.accepted),
                  child: const Text('Принимаю'),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _ScratchLayerPainter extends CustomPainter {
  const _ScratchLayerPainter({required this.points, required this.color});

  final List<Offset?> points;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    var overlayPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(24)),
      );

    final cutPath = Path();
    final scratchLinePath = Path();
    Offset? previous;
    for (final point in points) {
      if (point == null) {
        previous = null;
        continue;
      }
      cutPath.addOval(Rect.fromCircle(center: point, radius: 30));
      if (previous == null) {
        scratchLinePath.moveTo(point.dx, point.dy);
      }
      if (previous != null) {
        _addCapsule(cutPath, previous, point, 30);
        final mid = Offset(
          (previous.dx + point.dx) / 2,
          (previous.dy + point.dy) / 2,
        );
        scratchLinePath.quadraticBezierTo(
          previous.dx,
          previous.dy,
          mid.dx,
          mid.dy,
        );
      }
      previous = point;
    }

    if (points.whereType<Offset>().isNotEmpty) {
      overlayPath = Path.combine(
        PathOperation.difference,
        overlayPath,
        cutPath,
      );
    }

    final overlayPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: const [
          Color(0xFFE7D5DF),
          Color(0xFF9E7F90),
          Color(0xFFF7ECF2),
          Color(0xFF6F4B60),
        ],
        stops: const [0, 0.36, 0.58, 1],
      ).createShader(Offset.zero & size);
    canvas.drawPath(overlayPath, overlayPaint);

    final shinePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.28),
          Colors.transparent,
          color.withValues(alpha: 0.18),
        ],
      ).createShader(Offset.zero & size)
      ..strokeWidth = 34
      ..style = PaintingStyle.stroke;
    canvas.save();
    canvas.clipPath(overlayPath);
    for (var y = -size.height; y < size.height * 2; y += 74) {
      canvas.drawLine(
        Offset(-20, y.toDouble()),
        Offset(size.width + 20, y + size.width * 0.35),
        shinePaint,
      );
    }
    canvas.restore();

    if (points.whereType<Offset>().isNotEmpty) {
      final rimPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.42)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = 7;
      canvas.drawPath(scratchLinePath, rimPaint);

      final dustPaint = Paint()
        ..color = const Color(0xFFFFD6EA).withValues(alpha: 0.54)
        ..style = PaintingStyle.fill;
      var index = 0;
      for (final point in points.whereType<Offset>()) {
        if (index % 5 == 0) {
          canvas.drawCircle(
            point + Offset((index % 3 - 1) * 7, (index % 4 - 1.5) * 5),
            2.4,
            dustPaint,
          );
        }
        index++;
      }
    }
  }

  void _addCapsule(Path path, Offset from, Offset to, double radius) {
    final delta = to - from;
    if (delta.distance == 0) {
      path.addOval(Rect.fromCircle(center: from, radius: radius));
      return;
    }
    final normal = Offset(-delta.dy, delta.dx) / delta.distance * radius;
    path
      ..moveTo(from.dx + normal.dx, from.dy + normal.dy)
      ..lineTo(to.dx + normal.dx, to.dy + normal.dy)
      ..lineTo(to.dx - normal.dx, to.dy - normal.dy)
      ..lineTo(from.dx - normal.dx, from.dy - normal.dy)
      ..close();
  }

  @override
  bool shouldRepaint(covariant _ScratchLayerPainter oldDelegate) {
    return oldDelegate.points.length != points.length ||
        oldDelegate.color != color;
  }
}

class _DiceGame extends StatefulWidget {
  const _DiceGame({
    super.key,
    required this.visibleToPartners,
    required this.onBack,
  });

  final bool visibleToPartners;
  final VoidCallback onBack;

  @override
  State<_DiceGame> createState() => _DiceGameState();
}

class _DiceGameState extends State<_DiceGame> {
  final GameStatsRepository _repo = GameStatsRepository();
  final Random _random = Random();
  late final List<GameDiceOption> _placeOptions;
  late final List<GameDiceOption> _poseOptions;
  StreamSubscription<UserAccelerometerEvent>? _shakeSub;

  late final DateTime _startedAt;
  String? _sessionId;
  String? _place;
  String? _dicePose;
  DateTime? _lastShakeAt;
  bool _saving = false;
  bool _rolling = false;

  @override
  void initState() {
    super.initState();
    _placeOptions = enabledDiceOptions(GameDiceOptionCategory.place);
    _poseOptions = enabledDiceOptions(GameDiceOptionCategory.pose);
    _startedAt = DateTime.now();
    _startSession();
    _startShakeListener();
  }

  @override
  void dispose() {
    _shakeSub?.cancel();
    super.dispose();
  }

  Future<void> _startSession() async {
    _sessionId = await _repo.startDiceSession(
      visibleToPartners: widget.visibleToPartners,
    );
  }

  void _startShakeListener() {
    if (kIsWeb) return;
    _shakeSub =
        userAccelerometerEventStream(
          samplingPeriod: SensorInterval.gameInterval,
        ).listen((event) {
          final force = sqrt(
            event.x * event.x + event.y * event.y + event.z * event.z,
          );
          final now = DateTime.now();
          final canRoll =
              _lastShakeAt == null ||
              now.difference(_lastShakeAt!).inMilliseconds > 1200;
          if (force > 18 && canRoll && !_rolling && !_saving) {
            _lastShakeAt = now;
            _rollDice();
          }
        }, onError: (_) {});
  }

  Future<void> _rollDice() async {
    if (_rolling || _saving) return;
    setState(() => _rolling = true);

    GameDiceOption place = _placeOptions[_random.nextInt(_placeOptions.length)];
    GameDiceOption dicePose =
        _poseOptions[_random.nextInt(_poseOptions.length)];
    const spinCount = 24;
    for (var i = 0; i < spinCount; i++) {
      if (!mounted) return;
      place = _placeOptions[_random.nextInt(_placeOptions.length)];
      dicePose = _poseOptions[_random.nextInt(_poseOptions.length)];
      setState(() {
        _place = place.label;
        _dicePose = dicePose.label;
      });
      GameSoundService.instance.playDiceTick();
      final delayMs = 38 + (i * i * 3.2).round();
      await Future<void>.delayed(Duration(milliseconds: delayMs));
    }

    if (!mounted) return;
    GameSoundService.instance.playDiceFinal();
    setState(() {
      _place = place.label;
      _dicePose = dicePose.label;
    });

    final sessionId = _sessionId;
    if (sessionId != null) {
      await _repo.recordDiceRoll(
        sessionId: sessionId,
        place: place.label,
        dicePose: dicePose.label,
      );
    }
    if (mounted) setState(() => _rolling = false);
  }

  Future<void> _complete(GameSessionStatus status) async {
    final sessionId = _sessionId;
    setState(() => _saving = true);
    if (sessionId != null) {
      await _repo.completeDiceSession(
        sessionId: sessionId,
        status: status,
        startedAt: _startedAt,
      );
    }
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          status == GameSessionStatus.accepted
              ? 'Результат принят и сохранён в статистике'
              : 'Результат пропущен и сохранён в статистике',
        ),
      ),
    );
    widget.onBack();
  }

  @override
  Widget build(BuildContext context) {
    final hasResult = _place != null && _dicePose != null;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _BackToGamesButton(onPressed: widget.onBack),
        const SizedBox(height: 12),
        Text('Кубики', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          kIsWeb
              ? 'На web используйте кнопку броска. На телефоне дополнительно работает встряхивание.'
              : 'Встряхните телефон или нажмите кнопку, чтобы бросить кубики.',
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _DiceCard(
                label: 'Место',
                value: _place ?? '???',
                icon: Icons.place,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DiceCard(
                label: 'Поза',
                value: _dicePose ?? '???',
                icon: Icons.favorite,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _rolling || _saving ? null : _rollDice,
          icon: const Icon(Icons.casino),
          label: Text(_rolling ? 'Бросаем...' : 'Бросить кубики'),
        ),
        if (hasResult) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _saving || _rolling
                      ? null
                      : () => _complete(GameSessionStatus.skipped),
                  child: const Text('Пропускаю'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _saving || _rolling
                      ? null
                      : () => _complete(GameSessionStatus.accepted),
                  child: const Text('Принимаю'),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _DiceCard extends StatelessWidget {
  const _DiceCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(label, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 120),
              transitionBuilder: (child, animation) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.28),
                    end: Offset.zero,
                  ).animate(animation),
                  child: FadeTransition(opacity: animation, child: child),
                );
              },
              child: Text(
                value,
                key: ValueKey(value),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BackToGamesButton extends StatelessWidget {
  const _BackToGamesButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.arrow_back),
        label: const Text('К выбору игры'),
      ),
    );
  }
}

class _TruthOrDareGame extends StatefulWidget {
  const _TruthOrDareGame({
    super.key,
    required this.visibleToPartners,
    required this.onBack,
  });

  final bool visibleToPartners;
  final VoidCallback onBack;

  @override
  State<_TruthOrDareGame> createState() => _TruthOrDareGameState();
}

class _TruthOrDareGameState extends State<_TruthOrDareGame> {
  final GameStatsRepository _repo = GameStatsRepository();
  final Random _random = Random();
  late final DateTime _startedAt;

  String? _sessionId;
  TruthOrDarePrompt? _currentPrompt;
  String? _currentKind;
  TruthOrDareLevel _selectedLevel = TruthOrDareLevel.soft;
  bool _drawing = false;
  bool _saving = false;

  String _levelHint(TruthOrDareLevel level) {
    switch (level) {
      case TruthOrDareLevel.soft:
        return 'Soft: легкий флирт, комфортные вопросы и задания.';
      case TruthOrDareLevel.hot:
        return 'Hot: более откровенный тон и смелые формулировки.';
      case TruthOrDareLevel.extreme:
        return 'Extreme: максимально дерзкий уровень, выбирайте по взаимному согласию.';
    }
  }

  @override
  void initState() {
    super.initState();
    _startedAt = DateTime.now();
    _startSession();
  }

  Future<void> _startSession() async {
    _sessionId = await _repo.startTruthOrDareSession(
      visibleToPartners: widget.visibleToPartners,
    );
  }

  Future<void> _drawPrompt({String? forcedKind}) async {
    if (_drawing || _saving) return;
    final kind = forcedKind ?? (_random.nextBool() ? 'truth' : 'dare');
    final baseSource = kind == 'truth' ? truthPrompts : darePrompts;
    final source = baseSource
        .where((prompt) => prompt.level == _selectedLevel)
        .toList();
    final effectiveSource = source.isEmpty ? baseSource : source;
    if (effectiveSource.isEmpty) return;
    final prompt = effectiveSource[_random.nextInt(effectiveSource.length)];

    setState(() {
      _drawing = true;
    });
    await Future<void>.delayed(const Duration(milliseconds: 220));
    if (!mounted) return;

    setState(() {
      _currentKind = kind;
      _currentPrompt = prompt;
      _drawing = false;
    });

    final sessionId = _sessionId;
    if (sessionId != null) {
      await _repo.recordTruthOrDareRound(
        sessionId: sessionId,
        kind: kind,
        level: _selectedLevel.name,
        promptId: prompt.id,
        promptText: prompt.text,
      );
    }
  }

  Future<void> _complete(GameSessionStatus status) async {
    final sessionId = _sessionId;
    setState(() => _saving = true);
    if (sessionId != null) {
      await _repo.completeTruthOrDareSession(
        sessionId: sessionId,
        status: status,
        startedAt: _startedAt,
      );
    }
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          status == GameSessionStatus.accepted
              ? 'Игра сохранена как удачная'
              : 'Игра завершена и сохранена',
        ),
      ),
    );
    widget.onBack();
  }

  @override
  Widget build(BuildContext context) {
    final prompt = _currentPrompt;
    final kind = _currentKind;
    final truthCount = truthPrompts
        .where((prompt) => prompt.level == _selectedLevel)
        .length;
    final dareCount = darePrompts
        .where((prompt) => prompt.level == _selectedLevel)
        .length;
    final kindLabel = kind == 'truth' ? 'Правда' : 'Действие';
    final kindColor = kind == 'truth'
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.secondary;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _BackToGamesButton(onPressed: widget.onBack),
        const SizedBox(height: 12),
        Text(
          'Правда или действие',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        const Text(
          'Выберите тип карточки или доверьтесь случаю. Можно тянуть несколько карточек подряд.',
        ),
        const SizedBox(height: 12),
        SegmentedButton<TruthOrDareLevel>(
          segments: const [
            ButtonSegment(
              value: TruthOrDareLevel.soft,
              label: Text('Soft'),
            ),
            ButtonSegment(
              value: TruthOrDareLevel.hot,
              label: Text('Hot'),
            ),
            ButtonSegment(
              value: TruthOrDareLevel.extreme,
              label: Text('Extreme'),
            ),
          ],
          selected: {_selectedLevel},
          onSelectionChanged: (selection) {
            final level = selection.first;
            setState(() {
              _selectedLevel = level;
            });
          },
        ),
        const SizedBox(height: 6),
        Text(
          'Карточек: правда $truthCount, действие $dareCount',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 4),
        Text(
          _levelHint(_selectedLevel),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _drawing || _saving
                    ? null
                    : () => _drawPrompt(forcedKind: 'truth'),
                child: const Text('Правда'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton(
                onPressed: _drawing || _saving
                    ? null
                    : () => _drawPrompt(forcedKind: 'dare'),
                child: const Text('Действие'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                onPressed: _drawing || _saving ? null : _drawPrompt,
                child: Text(_drawing ? '...' : 'Случайно'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: prompt == null
                  ? const SizedBox(
                      key: ValueKey('empty_prompt'),
                      height: 120,
                      child: Center(
                        child: Text(
                          'Нажмите кнопку выше, чтобы получить карточку',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : Column(
                      key: ValueKey('${prompt.id}_$kind'),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: kindColor.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            kindLabel,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: kindColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          prompt.text,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
            ),
          ),
        ),
        if (prompt != null) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _saving ? null : () => _complete(GameSessionStatus.skipped),
                  child: const Text('Завершить'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _saving ? null : () => _complete(GameSessionStatus.accepted),
                  child: const Text('Отлично, берём'),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
