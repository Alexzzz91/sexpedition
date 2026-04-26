import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:sexpedition_application_1/data/kamasutra_poses.dart';
import 'package:sexpedition_application_1/models/game_session.dart';
import 'package:sexpedition_application_1/services/game_stats_repository.dart';

enum _GameMode { scratchPose, dice }

const List<String> _dicePlaces = [
  'Кухня на столе',
  'Диван',
  'Кровать',
  'Ванная комната',
  'У зеркала',
  'На балконе / у окна',
];

const List<String> _dicePoses = [
  'Девушка сверху',
  'Раком',
  'Боком',
  'Миньет',
  'Кунилигус',
  'Миссионерская',
];

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
      appBar: AppBar(
        title: const Text('Игры'),
      ),
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
                : _DiceGame(
                    key: const ValueKey('dice'),
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
          'Сыграйте в случайную позу или бросьте кубики для места и сценария.',
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
                backgroundColor:
                    Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
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

class _ScratchPoseGameState extends State<_ScratchPoseGame> {
  final GameStatsRepository _repo = GameStatsRepository();
  final List<Offset> _scratchPoints = [];
  late final KamasutraPose _pose;
  late final DateTime _startedAt;
  String? _sessionId;
  bool _revealed = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _pose = kamasutraPoses[Random().nextInt(kamasutraPoses.length)];
    _startedAt = DateTime.now();
    _startSession();
  }

  Future<void> _startSession() async {
    _sessionId = await _repo.startScratchPoseSession(
      poseId: _pose.id,
      poseLabel: _pose.label,
      visibleToPartners: widget.visibleToPartners,
    );
  }

  void _scratch(Offset position) {
    setState(() {
      _scratchPoints.add(position);
      if (_scratchPoints.length >= 24) {
        _revealed = true;
      }
    });
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
      padding: const EdgeInsets.all(20),
      children: [
        _BackToGamesButton(onPressed: widget.onBack),
        const SizedBox(height: 12),
        Text('Сотрите слой', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        const Text('Под верхним слоем спрятана случайная поза.'),
        const SizedBox(height: 16),
        AspectRatio(
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
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Expanded(child: SvgPicture.asset(_pose.imageAsset)),
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
                  if (!_revealed)
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onPanDown: (details) => _scratch(details.localPosition),
                      onPanUpdate: (details) => _scratch(details.localPosition),
                      child: CustomPaint(
                        painter: _ScratchLayerPainter(
                          points: _scratchPoints,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        child: const Center(
                          child: Text(
                            'Сотрите пальцем',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        if (!_revealed) ...[
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: (_scratchPoints.length / 24).clamp(0, 1).toDouble(),
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
  const _ScratchLayerPainter({
    required this.points,
    required this.color,
  });

  final List<Offset> points;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final overlayPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          color.withValues(alpha: 0.95),
          const Color(0xFF5A1836),
        ],
      ).createShader(Offset.zero & size);
    canvas.saveLayer(Offset.zero & size, Paint());
    canvas.drawRect(Offset.zero & size, overlayPaint);

    final clearPaint = Paint()
      ..blendMode = BlendMode.clear
      ..style = PaintingStyle.fill;
    for (final point in points) {
      canvas.drawCircle(point, 28, clearPaint);
    }
    canvas.restore();
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
    _shakeSub = userAccelerometerEventStream(
      samplingPeriod: SensorInterval.gameInterval,
    ).listen(
      (event) {
        final force = sqrt(
          event.x * event.x + event.y * event.y + event.z * event.z,
        );
        final now = DateTime.now();
        final canRoll = _lastShakeAt == null ||
            now.difference(_lastShakeAt!).inMilliseconds > 1200;
        if (force > 18 && canRoll && !_rolling && !_saving) {
          _lastShakeAt = now;
          _rollDice();
        }
      },
      onError: (_) {},
    );
  }

  Future<void> _rollDice() async {
    setState(() => _rolling = true);
    final place = _dicePlaces[_random.nextInt(_dicePlaces.length)];
    final dicePose = _dicePoses[_random.nextInt(_dicePoses.length)];
    setState(() {
      _place = place;
      _dicePose = dicePose;
    });

    final sessionId = _sessionId;
    if (sessionId != null) {
      await _repo.recordDiceRoll(
        sessionId: sessionId,
        place: place,
        dicePose: dicePose,
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
            Text(
              value,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
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

