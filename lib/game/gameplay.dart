import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flame/game.dart';

import 'atlas.dart';
import 'audio.dart';
import 'data.dart';
import 'progress.dart';

// Port of game js/game/renderer.js + session.js into a Flame game.

const int artSize = 256;
const int sampleGrid = 28;
const double wipeCompletionThreshold = 0.2;

class GameConfig {
  double brushRadius = 34;
  double softenDelay = 900; // ms
  double effectIntensity = 1;
  double targetTimeScale = 1;
}

class ResultSummary {
  final double seconds;
  final int stars;
  final int coinGain;
  final int score;
  ResultSummary(this.seconds, this.stars, this.coinGain, this.score);
}

class GameHud {
  void Function(String)? onProgress;
  void Function(String)? onTime;
  void Function(int)? onMistakes;
  void Function(String)? onStageTip;
  void Function(String)? onSelectedTool;
  void Function(String)? onHint;
  void Function(ResultSummary)? onComplete;
  void Function()? onPause;
}

class _Stroke {
  final ui.Offset from;
  final ui.Offset to;
  final double radius;
  final int durability;
  _Stroke(this.from, this.to, this.radius, this.durability);
}

class _Layer {
  ui.Image image;
  final int durability;
  final Uint8List health;
  final int total;
  int remaining;
  bool _rebuilding = false;
  bool _pending = false;
  final List<_Stroke> _pendingStrokes = [];
  _Layer(this.image, this.durability, this.health, this.total)
      : remaining = total;
}

class _Spot {
  final SpotDef def;
  final List<_Layer> layers;
  int stage = 0;
  int completedWipes = 0;
  double readyAt = 0;
  bool clean = false;
  ui.Rect? rect;
  double shakeUntil = 0;
  double revealHintUntil = 0;
  double focusUntil = 0;
  _Spot(this.def, this.layers);
}

class _Particle {
  double x, y, vx, vy, age, life, size;
  final ui.Color color;
  _Particle(this.x, this.y, this.vx, this.vy, this.age, this.life, this.size,
      this.color);
}

class _Effect {
  final String name;
  double x, y, size, age, life;
  _Effect(this.name, this.x, this.y, this.size, this.age, this.life);
}

class _Run {
  final LevelData levelData;
  final List<_Spot> spots = [];
  final String skin;
  String selectedTool = 'sponge';
  double startedAt = 0;
  double endedAt = 0;
  bool paused = false;
  double pausedAt = 0;
  double pausedDuration = 0;
  int mistakes = 0;
  double progress = 0;
  int milestone = 0;
  double moodUntil = 0;
  bool complete = false;
  _Run(this.levelData, this.skin);
}

double _distanceToSegment(
    double px, double py, double x1, double y1, double x2, double y2) {
  final dx = x2 - x1;
  final dy = y2 - y1;
  final lengthSq = dx * dx + dy * dy;
  if (lengthSq == 0) return math.sqrt((px - x1) * (px - x1) + (py - y1) * (py - y1));
  final t = ((px - x1) * dx + (py - y1) * dy) / lengthSq;
  final tc = t.clamp(0.0, 1.0);
  return math.sqrt((px - (x1 + tc * dx)) * (px - (x1 + tc * dx)) +
      (py - (y1 + tc * dy)) * (py - (y1 + tc * dy)));
}

Future<ui.Image> _renderToImage(int size, void Function(ui.Canvas, double) paint) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  paint(canvas, size.toDouble());
  return recorder.endRecording().toImage(size, size);
}

Future<ui.Image> _eraseImage(ui.Image src, ui.Offset from, ui.Offset to,
    double radius, int durability) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawImage(src, ui.Offset.zero, ui.Paint());
  // Match the JS renderer: each pass removes only 1/durability of the grime
  // so the visible image stays in sync with the health grid. A full-alpha
  // erase would wipe the picture in one stroke while health still had
  // remaining counts, leaving spots invisible but never marked clean.
  final stroke = ui.Paint()
    ..blendMode = ui.BlendMode.dstOut
    ..style = ui.PaintingStyle.stroke
    ..strokeCap = ui.StrokeCap.round
    ..strokeJoin = ui.StrokeJoin.round
    ..strokeWidth = radius * 2
    ..color =
        ui.Color.fromARGB((255 / durability).round().clamp(1, 255), 0, 0, 0);
  canvas.drawLine(from, to, stroke);
  return recorder.endRecording().toImage(src.width, src.height);
}

class WindowGame extends FlameGame {
  final GameMedia media;
  final Progress progress;
  final GameConfig config;
  final AudioManager? audio;
  final GameHud hud = GameHud();

  _Run? _run;
  late LevelData _levelData;
  bool _active = false;
  double _now = 0;
  double _lastHud = -1;

  final List<_Particle> _particles = [];
  final List<_Effect> _effects = [];

  ui.Rect _frame = ui.Rect.zero;
  ui.Rect _windowBox = ui.Rect.zero;

  bool _dragging = false;
  _Spot? _activeSpot;
  ui.Offset? _previousPoint;
  String _selectedTool = 'sponge';
  double _lastScrubSound = 0;
  double _hintTimer = 0;
  double _resultTimer = 0;

  final Map<String, ui.Image> _grimeBaseCache = {};
  final Map<String, Uint8List> _grimeHealthCache = {};
  ui.Image? _transparent;

  WindowGame(this.media, this.progress, this.config, [this.audio]);

  Future<void> startLevel(LevelData levelData) async {
    _levelData = levelData;
    final scaled = LevelData(
        levelData.level,
        levelData.world,
        levelData.spots,
        (levelData.targetTime * config.targetTimeScale).round(),
        levelData.difficulty,
        levelData.windowType);
    final tools = getUnlockedTools(levelData.level);
    _selectedTool = tools.first;
    _run = _Run(scaled, progress.activeSkin);
    _transparent ??= await _renderToImage(artSize, (_, __) {});
    final spots = await Future.wait(
        levelData.spots.map((sp) => _createSpot(sp)));
    _run!.spots.addAll(spots);
    _active = true;
    _now = 0;
    _lastHud = -1;
    _particles.clear();
    _effects.clear();
    _dragging = false;
    _activeSpot = null;
    selectTool(_selectedTool);
    audio?.play('level_start');
  }

  Future<_Spot> _createSpot(SpotDef def) async {
    final wipeCount = def.recipe.where((t) => tools[t]!.kind == 'wipe').length;
    final base = await _grimeBase(def.type);
    final healthTemplate = await _grimeHealth(def.type, def.durability);
    final layers = <_Layer>[];
    for (int i = 0; i < wipeCount; i += 1) {
      final image = await _cloneImage(base);
      final health = Uint8List.fromList(healthTemplate);
      int total = 0;
      for (final h in health) total += h;
      layers.add(_Layer(image, def.durability, health, total));
    }
    if (layers.isEmpty) {
      layers.add(_Layer(_transparent!, def.durability, Uint8List(sampleGrid * sampleGrid), 0));
    }
    return _Spot(def, layers);
  }

  Future<ui.Image> _grimeBase(String type) async {
    if (_grimeBaseCache.containsKey(type)) return _grimeBaseCache[type]!;
    final img = await _renderToImage(artSize, (canvas, s) {
      media.drawGrime(
          canvas, type, ui.Rect.fromLTWH(4, 4, s - 8, s - 8));
    });
    _grimeBaseCache[type] = img;
    return img;
  }

  Future<Uint8List> _grimeHealth(String type, int durability) async {
    final key = '$type:$durability';
    if (_grimeHealthCache.containsKey(key)) return _grimeHealthCache[key]!;
    final base = await _grimeBase(type);
    final bytes =
        await base.toByteData(format: ui.ImageByteFormat.rawRgba);
    final px = bytes!.buffer.asUint8List();
    final health = Uint8List(sampleGrid * sampleGrid);
    for (int row = 0; row < sampleGrid; row += 1) {
      for (int col = 0; col < sampleGrid; col += 1) {
        final x = ((col + 0.5) / sampleGrid * base.width).floor();
        final y = ((row + 0.5) / sampleGrid * base.height).floor();
        final alpha = px[(y * base.width + x) * 4 + 3];
        if (alpha > 24) health[row * sampleGrid + col] = durability;
      }
    }
    _grimeHealthCache[key] = health;
    return health;
  }

  Future<ui.Image> _cloneImage(ui.Image src) async =>
      _renderToImage(src.width, (canvas, _) {
        canvas.drawImage(src, ui.Offset.zero, ui.Paint());
      });

  void selectTool(String tool) {
    if (!tools.containsKey(tool) || _run == null || _run!.paused || _run!.complete) {
      return;
    }
    _selectedTool = tool;
    _run!.selectedTool = tool;
    audio?.play('tool');
    hud.onSelectedTool?.call(tools[tool]!.label);
    _updateStageTip(_activeSpot);
  }

  void pause() {
    if (_run == null || _run!.paused || _run!.complete) return;
    _run!.paused = true;
    _run!.pausedAt = _now;
    _stopDrag();
    audio?.play('pause');
    hud.onPause?.call();
  }

  void resume() {
    if (_run == null || !_run!.paused) return;
    _run!.pausedDuration += _now - _run!.pausedAt;
    _run!.paused = false;
    _run!.pausedAt = 0;
    audio?.play('resume');
  }

  void _stopDrag() {
    _dragging = false;
    _activeSpot = null;
    _previousPoint = null;
  }

  void onPointerDown(ui.Offset point) {
    if (_run == null || _run!.paused || _run!.complete) return;
    final spot = _getSpotAt(point);
    if (spot == null) return;
    if (tools[_selectedTool]!.kind == 'liquid') {
      _applyLiquid(spot);
      return;
    }
    _run!.startedAt = _run!.startedAt == 0 ? _now : _run!.startedAt;
    if (!_toolsMatch(_expectedTool(spot), _selectedTool)) {
      _markWrong(spot);
      return;
    }
    if (spot.readyAt > _now) {
      _setHint('Tunggu sampai busanya penuh…');
      return;
    }
    _dragging = true;
    _activeSpot = spot;
    _previousPoint = point;
    _eraseSpot(spot, point, ui.Offset(point.dx + 0.1, point.dy + 0.1));
    _finishWipeIfReady(spot);
  }

  void onPointerMove(ui.Offset point) {
    if (!_dragging || _activeSpot == null || _run == null ||
        _run!.paused || _run!.complete) return;
    final removed = _eraseSpot(_activeSpot!, _previousPoint!, point);
    _previousPoint = point;
    if (removed == 0) return;
    if (_now - _lastScrubSound > 115) {
      _lastScrubSound = _now;
      audio?.play('scrub');
    }
    _updateProgress();
    if (_finishWipeIfReady(_activeSpot!)) {
      _stopDrag();
    }
  }

  void onPointerUp() => _stopDrag();

  String _expectedTool(_Spot spot) => spot.def.recipe[spot.stage];

  bool _toolsMatch(String expected, String selected) {
    final alternatives = {
      'sponge': ['sponge', 'cloth'],
      'scrub_brush': ['scrub_brush', 'small_brush', 'electric_scrubber'],
      'cleaning_spray': ['cleaning_spray', 'foam_sprayer'],
      'water': ['water', 'steam_cleaner'],
    };
    return expected == selected || (alternatives[expected]?.contains(selected) ?? false);
  }

  void _updateStageTip(_Spot? spot) {
    final tool = spot != null ? _expectedTool(spot) : null;
    hud.onStageTip?.call(tool != null ? 'Berikutnya: ${tools[tool]!.label}' : 'Kenali nodanya');
  }

  void _markWrong(_Spot spot) {
    audio?.play('wrong');
    _run!.mistakes += 1;
    hud.onMistakes?.call(_run!.mistakes);
    spot.shakeUntil = _now + 380;
    spot.revealHintUntil = _now + 2400;
    spot.focusUntil = _now + 1300;
    _run!.moodUntil = _now + 1200;
    final expected = _expectedTool(spot);
    _setHint('Hmm… butuh ${tools[expected]!.label}');
    _updateStageTip(spot);
  }

  double _runTime() {
    if (_run == null || _run!.startedAt == 0) return 0;
    final end = _run!.complete ? _run!.endedAt : (_run!.paused ? _run!.pausedAt : _now);
    return math.max(0, (end - _run!.startedAt - _run!.pausedDuration) / 1000);
  }

  void _applyLiquid(_Spot spot) {
    _run!.startedAt = _run!.startedAt == 0 ? _now : _run!.startedAt;
    final expected = _expectedTool(spot);
    if (!_toolsMatch(expected, _selectedTool) ||
        tools[_selectedTool]!.kind != 'liquid') {
      _markWrong(spot);
      return;
    }
    final dirtDef = dirt[spot.def.type]!;
    audio?.play(_selectedTool == 'water' || _selectedTool == 'steam_cleaner'
        ? 'water'
        : _selectedTool == 'foam_sprayer' ? 'foam' : 'spray');
    spot.stage += 1;
    _run!.moodUntil = 0;
    spot.revealHintUntil = _now + 2600;
    spot.focusUntil = _now + 1400;
    final softening = [
      'degreaser', 'cleaning_spray', 'descaler', 'paint_remover',
      'heavy_duty', 'foam_sprayer'
    ];
    if (dirtDef.waitAfter?.contains(_selectedTool) == true ||
        softening.contains(_selectedTool)) {
      spot.readyAt = _now + config.softenDelay;
      _setHint('Tunggu busanya bekerja…',
          math.min(1500, config.softenDelay + 250).round());
    } else {
      _setHint('Bagus! Sekarang pakai ${tools[_expectedTool(spot)]!.label}');
    }
    final liquidEffect = _selectedTool == 'water' || _selectedTool == 'steam_cleaner'
        ? 'water_splash'
        : _selectedTool == 'foam_sprayer'
            ? 'foam'
            : 'soap_bubbles';
    _flashEffect(liquidEffect, spot.rect!.center.dx, spot.rect!.center.dy,
        math.max(58, spot.rect!.width * 0.9));
    _burst(spot.rect!.center.dx, spot.rect!.center.dy, const ui.Color(0xffdffcff), 7);
    _updateStageTip(spot);
  }

  int _eraseSpot(_Spot spot, ui.Offset from, ui.Offset to) {
    final layer = spot.layers[spot.completedWipes];
    if (layer == null || spot.rect == null) return 0;
    final r = spot.rect!;
    final radius = config.brushRadius;
    final localFrom = ui.Offset(
        (from.dx - r.left) / r.width * artSize,
        (from.dy - r.top) / r.height * artSize);
    final localTo = ui.Offset((to.dx - r.left) / r.width * artSize,
        (to.dy - r.top) / r.height * artSize);
    final stroke = _Stroke(localFrom, localTo, radius * artSize / r.width,
        layer.durability);
    layer._pendingStrokes.add(stroke);
    _rebuildLayer(layer);
    int removed = 0;
    for (int row = 0; row < sampleGrid; row += 1) {
      for (int col = 0; col < sampleGrid; col += 1) {
        final index = row * sampleGrid + col;
        if (layer.health[index] == 0) continue;
        final sx = (col + 0.5) / sampleGrid * artSize;
        final sy = (row + 0.5) / sampleGrid * artSize;
        if (_distanceToSegment(sx, sy, localFrom.dx, localFrom.dy,
                localTo.dx, localTo.dy) <=
            radius * artSize / r.width) {
          layer.health[index] -= 1;
          layer.remaining -= 1;
          removed += 1;
        }
      }
    }
    if (removed > 0) spot.focusUntil = _now + 1000;
    return removed;
  }

  void _rebuildLayer(_Layer layer) {
    if (layer._rebuilding) {
      layer._pending = true;
      return;
    }
    layer._rebuilding = true;
    _consumeStrokes(layer);
  }

  Future<void> _consumeStrokes(_Layer layer) async {
    while (layer._pendingStrokes.isNotEmpty) {
      final s = layer._pendingStrokes.removeAt(0);
      layer.image = await _eraseImage(layer.image, s.from, s.to, s.radius,
          s.durability);
    }
    layer._rebuilding = false;
    if (layer._pending) {
      layer._pending = false;
      _consumeStrokes(layer);
    }
  }

  double _layerRatio(_Spot spot) {
    if (spot.completedWipes >= spot.layers.length) return 0;
    final layer = spot.layers[spot.completedWipes];
    if (layer.total == 0) return 0;
    return layer.remaining / layer.total;
  }

  bool _finishWipeIfReady(_Spot spot) {
    if (spot.clean || spot.stage >= spot.def.recipe.length) return true;
    if (_layerRatio(spot) > wipeCompletionThreshold) return false;
    _finishWipeStage(spot);
    return true;
  }

  double _spotProgress(_Spot spot) {
    int total = 0;
    int remaining = 0;
    for (final layer in spot.layers) {
      total += layer.total;
      remaining += layer.remaining;
    }
    return total == 0 ? (spot.clean ? 1 : 0) : 1 - remaining / total;
  }

  void _updateProgress() {
    if (_run == null) return;
    for (final spot in _run!.spots) {
      if (!spot.clean && _spotProgress(spot) >= 0.8) {
        for (final layer in spot.layers) {
          layer.image = _transparent!;
          layer.remaining = 0;
          layer.health.fillRange(0, layer.health.length, 0);
        }
        spot.completedWipes = spot.layers.length;
        spot.stage = spot.def.recipe.length;
        spot.clean = true;
      }
    }
    double total = 0;
    for (final spot in _run!.spots) total += _spotProgress(spot);
    _run!.progress = total / _run!.spots.length;
    final percent =
        _run!.complete ? 100 : math.min(99, (_run!.progress * 100).floor());
    hud.onProgress?.call('$percent%');
    final next = percent >= 100
        ? 100
        : percent >= 90
            ? 90
            : percent >= 50
                ? 50
                : 0;
    if (next > _run!.milestone) _run!.milestone = next;
    if (!_run!.complete && _run!.spots.every((s) => s.clean)) _completeLevel();
  }

  void _finishWipeStage(_Spot spot) {
    if (spot.completedWipes >= spot.layers.length) return;
    final layer = spot.layers[spot.completedWipes];
    layer.image = _transparent!;
    for (int i = 0; i < layer.health.length; i++) layer.health[i] = 0;
    layer.remaining = 0;
    spot.completedWipes += 1;
    spot.stage += 1;
    _run!.moodUntil = 0;
    audio?.play(_selectedTool == 'glass_polisher' ? 'polish' : 'clean');
    spot.readyAt = 0;
    spot.revealHintUntil = _now + 2800;
    spot.focusUntil = _now + 1500;
    _burst(spot.rect!.center.dx, spot.rect!.center.dy, const ui.Color(0xfffff4a8), 11);
    final finishEffects = {
      'grease': 'oil_dissolve',
      'scale': 'scale_break',
      'mold': 'mold_vanish',
      'water_mark': 'wipe_trail',
      'fingerprint': 'wipe_trail',
    };
    _flashEffect(finishEffects[spot.def.type] ?? 'scrub_particles',
        spot.rect!.center.dx, spot.rect!.center.dy, math.max(62, spot.rect!.width));
    if (spot.stage >= spot.def.recipe.length) {
      spot.clean = true;
      _setHint('${dirt[spot.def.type]!.label} bersih!');
    } else {
      _setHint('Lanjut: ${tools[_expectedTool(spot)]!.label}');
    }
    _updateStageTip(spot);
    _updateProgress();
  }

  _Spot? _getSpotAt(ui.Offset point) {
    if (_run == null) return null;
    for (int i = _run!.spots.length - 1; i >= 0; i -= 1) {
      final spot = _run!.spots[i];
      if (spot.clean || spot.rect == null) continue;
      final r = spot.rect!;
      if (point.dx >= r.left - 8 &&
          point.dx <= r.right + 8 &&
          point.dy >= r.top - 8 &&
          point.dy <= r.bottom + 8) {
        return spot;
      }
    }
    return null;
  }

  void _burst(double x, double y, ui.Color color, int count) {
    final intensity = config.effectIntensity;
    final n = (count * intensity).round();
    for (int i = 0; i < n; i += 1) {
      final angle = math.pi * 2 * i / count + math.Random().nextDouble() * 0.35;
      final speed = 35 + math.Random().nextDouble() * 55;
      _particles.add(_Particle(x, y, math.cos(angle) * speed,
          math.sin(angle) * speed - 15, 0, 0.45 + math.Random().nextDouble() * 0.35,
          2 + math.Random().nextDouble() * 4, color));
    }
  }

  void _flashEffect(String name, double x, double y, double size, [double life = 0.55]) {
    _effects.add(_Effect(name, x, y, size, 0, life));
  }

  void _setHint(String message, [int duration = 1600]) {
    hud.onHint?.call(message);
    _hintTimer = _now + duration;
  }

  int _calculateStars(double seconds, int mistakes, int target) {
    if (seconds <= target && mistakes <= 1) return 3;
    if (seconds <= target * 1.5 && mistakes <= 3) return 2;
    return 1;
  }

  int _visibleScore(int level, int stars, double seconds, int mistakes) =>
      math.max(0, (level * 1000 + stars * 500 - seconds * 10 - mistakes * 100).round());

  void _completeLevel() {
    if (_run == null || _run!.complete) return;
    _run!.complete = true;
    audio?.play('complete');
    _run!.endedAt = _now;
    _run!.progress = 1;
    hud.onProgress?.call('100%');
    final seconds = _runTime();
    final stars = _calculateStars(seconds, _run!.mistakes, _levelData.targetTime);
    final previousStars = progress.stars[_levelData.level] ?? 0;
    final coinGain = math.max(
        0, rewardForStars(stars) - rewardForStars(previousStars));
    progress.stars[_levelData.level] =
        math.max(previousStars, stars);
    progress.coins += coinGain;
    progress.unlockedLevel = math.max(
        progress.unlockedLevel, math.min(maxLevel, _levelData.level + 1));
    progress.save();
    final score = _visibleScore(_levelData.level, stars, seconds, _run!.mistakes);
    _burst(size.x * 0.5, size.y * 0.45, const ui.Color(0xfffff4a8), 24);
    _flashEffect('star_burst', size.x * 0.5, size.y * 0.43,
        math.min(size.x, size.y) * 0.42, 0.8);
    _resultTimer = _now + 700;
    _pendingResult = ResultSummary(seconds, stars, coinGain, score);
  }

  ResultSummary? _pendingResult;

  @override
  void update(double dt) {
    if (!_active || _run == null) return;
    _now += dt * 1000;
    if (!_run!.paused && !_run!.complete) {
      final seconds = _runTime();
      if ((seconds - _lastHud).abs() >= 0.05) {
        hud.onTime?.call(formatTime(seconds));
        _lastHud = seconds;
      }
    }
    for (int i = _particles.length - 1; i >= 0; i -= 1) {
      final p = _particles[i];
      p.age += dt;
      if (p.age >= p.life) {
        _particles.removeAt(i);
        continue;
      }
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.vy += 70 * dt;
    }
    for (int i = _effects.length - 1; i >= 0; i -= 1) {
      final e = _effects[i];
      e.age += dt;
      if (e.age >= e.life) _effects.removeAt(i);
    }
    if (_hintTimer > 0 && _now > _hintTimer) {
      _hintTimer = 0;
      hud.onHint?.call('');
    }
    if (_pendingResult != null && _now >= _resultTimer) {
      final r = _pendingResult!;
      _pendingResult = null;
      hud.onComplete?.call(r);
    }
  }

  ui.Path _glassPath() {
    final shape = _run!.levelData.windowType.shape;
    final path = ui.Path();
    if (shape == 'round') {
      final radius = math.min(_frame.width, _frame.height) / 2;
      path.addOval(ui.Rect.fromCircle(
          center: ui.Offset(_frame.left + _frame.width / 2,
              _frame.top + _frame.height / 2),
          radius: radius));
    } else if (shape == 'arched') {
      final arch = math.min(_frame.height * 0.28, _frame.width * 0.48);
      path.moveTo(_frame.left, _frame.top + arch);
      path.quadraticBezierTo(_frame.left + _frame.width / 2,
          _frame.top - arch * 0.65, _frame.right, _frame.top + arch);
      path.lineTo(_frame.right, _frame.bottom);
      path.lineTo(_frame.left, _frame.bottom);
      path.close();
    } else {
      path.addRRect(ui.RRect.fromRectAndRadius(_frame,
          ui.Radius.circular(_clamp(_frame.width * 0.025, 5, 14))));
    }
    return path;
  }

  double _clamp(double v, double min, double max) => v.clamp(min, max);

  void _drawWorld(ui.Canvas canvas) {
    final w = size.x;
    final h = size.y;
    final pad = _clamp(math.min(w, h) * 0.025, 6, 14);
    final availW = w - pad * 2;
    final availH = h - pad * 2;
    final aspect = _run!.levelData.windowType.aspect;
    final scale = _run!.levelData.windowType.scale;
    double outerW = availW * scale;
    double outerH = outerW / aspect;
    if (outerH > availH * scale) {
      outerH = availH * scale;
      outerW = outerH * aspect;
    }
    _windowBox = ui.Rect.fromLTWH((w - outerW) / 2, (h - outerH) / 2, outerW, outerH);
    _frame = ui.Rect.fromLTWH(
        _windowBox.left + _windowBox.width * 0.14,
        _windowBox.top + _windowBox.height * 0.12,
        _windowBox.width * 0.72,
        _windowBox.height * 0.71);

    canvas.drawRect(ui.Rect.fromLTWH(0, 0, w, h),
        ui.Paint()..color = const ui.Color(0xffffd2ad));
    canvas.save();
    canvas.clipRect(ui.Rect.fromLTWH(0, 0, w, h));
    final stripe = ui.Paint()..color = const ui.Color(0x33ffffff);
    for (double s = -h; s < w; s += 46) {
      canvas.save();
      canvas.translate(s, 0);
      canvas.rotate(0.22);
      canvas.drawRect(ui.Rect.fromLTWH(0, -h * 0.2, 15, h * 1.5), stripe);
      canvas.restore();
    }
    canvas.restore();

    final path = _glassPath();
    canvas.save();
    canvas.clipPath(path);
    canvas.drawRect(_frame, ui.Paint()..color = const ui.Color(0xff8de9f0));
    media.drawWorld(canvas, _run!.levelData.world.key, _frame, cover: true);
    final tint = ui.Gradient.linear(
        ui.Offset(_frame.left, _frame.top),
        ui.Offset(_frame.right, _frame.bottom),
        [
          const ui.Color(0x2173f5ff),
          const ui.Color(0x0affffff),
          const ui.Color(0x1f0dacdd),
        ],
        [0.0, 0.5, 1.0]);
    canvas.drawRect(_frame, ui.Paint()..shader = tint);
    canvas.restore();

    final stroke = ui.Paint()
      ..color = const ui.Color(0x7a1c3043)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = _clamp(math.min(_frame.width, _frame.height) * 0.018, 2, 6);
    canvas.drawPath(path, stroke);
  }

  void _drawWindowFrame(ui.Canvas canvas) {
    final shape = _run!.levelData.windowType.shape;
    if (shape == 'round' || shape == 'arched') {
      final gradient = ui.Gradient.linear(
          ui.Offset(_frame.left, _frame.top),
          ui.Offset(_frame.right, _frame.bottom),
          [
            const ui.Color(0xffffffff),
            const ui.Color(0xffd9e1e5),
            const ui.Color(0xff7f929d),
            const ui.Color(0xfff7fafb),
          ],
          [0.0, 1 / 3, 2 / 3, 1.0]);
      final path = _glassPath();
      final outer = ui.Paint()
        ..color = const ui.Color(0xff40556a)
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = _clamp(math.min(_frame.width, _frame.height) * 0.11, 14, 34);
      canvas.drawPath(path, outer);
      final inner = ui.Paint()
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = _clamp(math.min(_frame.width, _frame.height) * 0.075, 10, 26)
        ..shader = gradient;
      canvas.drawPath(path, inner);
    } else {
      final img = media.windowFrame;
      final sw = img.width.toDouble();
      final sh = img.height.toDouble();
      final sideF = 0.14;
      final topF = 0.12;
      final botF = 0.17;
      final midF = 1 - topF - botF;
      canvas.drawImageRect(img, ui.Rect.fromLTWH(0, 0, sw, sh * topF),
          ui.Rect.fromLTWH(_windowBox.left, _windowBox.top, _windowBox.width, _windowBox.height * topF), ui.Paint());
      canvas.drawImageRect(img, ui.Rect.fromLTWH(0, sh * (1 - botF), sw, sh * botF),
          ui.Rect.fromLTWH(_windowBox.left, _windowBox.top + _windowBox.height * (1 - botF),
              _windowBox.width, _windowBox.height * botF), ui.Paint());
      canvas.drawImageRect(img, ui.Rect.fromLTWH(0, sh * topF, sw * sideF, sh * midF),
          ui.Rect.fromLTWH(_windowBox.left, _windowBox.top + _windowBox.height * topF,
              _windowBox.width * sideF, _windowBox.height * midF), ui.Paint());
      canvas.drawImageRect(img, ui.Rect.fromLTWH(sw * (1 - sideF), sh * topF, sw * sideF, sh * midF),
          ui.Rect.fromLTWH(_windowBox.left + _windowBox.width * (1 - sideF),
              _windowBox.top + _windowBox.height * topF,
              _windowBox.width * sideF, _windowBox.height * midF), ui.Paint());
    }
    final mullion = ui.Paint()
      ..color = const ui.Color(0xb8314659)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = _clamp(math.min(_frame.width, _frame.height) * 0.025, 5, 12);
    final fill = ui.Paint()..color = const ui.Color(0xe6eef5f7);
    canvas.save();
    canvas.clipPath(_glassPath());
    if (shape == 'double' || shape == 'sliding') {
      final center = _frame.left + _frame.width / 2;
      canvas.drawLine(ui.Offset(center, _frame.top),
          ui.Offset(center, _frame.bottom), mullion);
      canvas.drawRect(ui.Rect.fromLTWH(center - 2, _frame.top, 4, _frame.height), fill);
    }
    if (shape == 'french') {
      for (int c = 1; c < 3; c += 1) {
        final x = _frame.left + _frame.width * c / 3;
        canvas.drawRect(ui.Rect.fromLTWH(x - 2, _frame.top, 4, _frame.height), fill);
      }
      for (int r = 1; r < 4; r += 1) {
        final y = _frame.top + _frame.height * r / 4;
        canvas.drawRect(ui.Rect.fromLTWH(_frame.left, y - 2, _frame.width, 4), fill);
      }
    }
    canvas.restore();
  }

  void _drawSpot(ui.Canvas canvas, _Spot spot) {
    if (spot.clean) return;

    final short = math.min(_frame.width, _frame.height);
    final side = short * spot.def.size;
    final baseX = _frame.left + _frame.width * spot.def.x - side / 2;
    final baseY = _frame.top + _frame.height * spot.def.y - side / 2;
    final shake = _now < spot.shakeUntil ? math.sin(_now * 0.08) * 5 : 0;
    spot.rect = ui.Rect.fromLTWH(baseX + shake, baseY, side, side);

    final alpha = (0.2 + 0.78 / math.max(1, spot.layers.length) * 255).round();
    for (final layer in spot.layers) {
      canvas.save();
      canvas.drawImageRect(layer.image, ui.Rect.fromLTWH(0, 0, artSize.toDouble(), artSize.toDouble()),
          spot.rect!, ui.Paint()..color = ui.Color.fromARGB(alpha, 255, 255, 255));
      canvas.restore();
    }

    if (spot.readyAt > _now) {
      final waitProgress = _clamp(
          1 - (spot.readyAt - _now) / config.softenDelay, 0, 1);
      final paint = ui.Paint()
        ..color = const ui.Color(0xff6fe3ff)
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 5;
      canvas.drawArc(
          ui.Rect.fromCircle(
              center: ui.Offset(spot.rect!.center.dx, spot.rect!.center.dy),
              radius: side * 0.37),
          -math.pi / 2,
          math.pi * 2 * waitProgress,
          false,
          paint);
      for (int i = 0; i < 5; i += 1) {
        final angle = _now * 0.0016 + i * 1.3;
        final bx = spot.rect!.center.dx + math.cos(angle) * side * 0.26;
        final by = spot.rect!.center.dy + math.sin(angle * 1.2) * side * 0.25;
        canvas.drawCircle(ui.Offset(bx, by), 2.5 + (i % 3),
            ui.Paint()..color = const ui.Color(0xc8ffffff));
      }
    }

    if ((spot.stage > 0 || _now < spot.revealHintUntil) &&
        spot.stage < spot.def.recipe.length) {
      final expected = spot.def.recipe[spot.stage];
      final badge = _clamp(side * 0.26, 24, 42);
      final bx = spot.rect!.right - badge * 0.72;
      final by = spot.rect!.top - badge * 0.15;
      canvas.drawCircle(ui.Offset(bx, by), badge * 0.54,
          ui.Paint()..color = const ui.Color(0xffffffff));
      canvas.drawCircle(ui.Offset(bx, by), badge * 0.54,
          ui.Paint()
            ..color = const ui.Color(0xff071b55)
            ..style = ui.PaintingStyle.stroke
            ..strokeWidth = 3);
      media.drawTool(canvas, expected,
          ui.Rect.fromLTWH(bx - badge * 0.4, by - badge * 0.4, badge * 0.8, badge * 0.8));
    }
  }

  void _drawCharacter(ui.Canvas canvas) {
    final run = _run!;
    final characterSize =
        _clamp(math.min(_windowBox.width * 0.5, _windowBox.height * 0.34), 88, 168);
    final bounce = run.complete
        ? math.sin(_now * 0.012).abs() * 12
        : 0;
    final annoyed = !run.complete && _now < run.moodUntil;
    final grumble = annoyed ? math.sin(_now * 0.055) * 3 : 0;
    media.drawSkin(
        canvas,
        run.skin,
        annoyed ? 'annoyed' : 'idle',
        ui.Rect.fromLTWH(
            math.max(-characterSize * 0.08,
                _windowBox.left - characterSize * 0.32 + grumble),
            _windowBox.top + _windowBox.height - characterSize * 0.8 - bounce,
            characterSize,
            characterSize));
    final gleam = ui.Paint()..color = const ui.Color(0x2effffff);
    final gleamPath = ui.Path();
    gleamPath.moveTo(_frame.left + _frame.width * 0.12, _frame.top + 8);
    gleamPath.lineTo(_frame.left + _frame.width * 0.34, _frame.top + 8);
    gleamPath.lineTo(_frame.left + _frame.width * 0.18, _frame.top + _frame.height * 0.52);
    gleamPath.lineTo(_frame.left + _frame.width * 0.05, _frame.top + _frame.height * 0.52);
    gleamPath.close();
    canvas.drawPath(gleamPath, gleam);
  }

  void _drawParticles(ui.Canvas canvas) {
    for (final p in _particles) {
      final alpha = 1 - p.age / p.life;
      final paint = ui.Paint()
        ..color = ui.Color.fromARGB((alpha * 255).round(),
            p.color.red, p.color.green, p.color.blue);
      _starPath(canvas, p.x, p.y, p.size, paint);
    }
  }

  void _drawEffects(ui.Canvas canvas) {
    for (final e in _effects) {
      final progress = e.age / e.life;
      final size = e.size * (0.75 + progress * 0.35);
      final alpha = (math.sin(progress * math.pi) * 255).round();
      canvas.saveLayer(
          null, ui.Paint()..color = ui.Color.fromARGB(alpha, 255, 255, 255));
      media.drawEffect(canvas, e.name,
          ui.Rect.fromLTWH(e.x - size / 2, e.y - size / 2, size, size));
      canvas.restore();
    }
  }

  void _starPath(ui.Canvas canvas, double x, double y, double radius, ui.Paint paint) {
    final path = ui.Path();
    for (int i = 0; i < 10; i += 1) {
      final angle = -math.pi / 2 + i * math.pi / 5;
      final len = i % 2 == 0 ? radius : radius * 0.45;
      final px = x + math.cos(angle) * len;
      final py = y + math.sin(angle) * len;
      if (i == 0) {
        path.moveTo(px, py);
      } else {
        path.lineTo(px, py);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  void render(ui.Canvas canvas) {
    if (!_active || _run == null) {
      canvas.drawRect(
          ui.Rect.fromLTWH(0, 0, size.x, size.y),
          ui.Paint()..color = const ui.Color(0xff1b2b3a));
      return;
    }
    _drawWorld(canvas);
    canvas.save();
    canvas.clipPath(_glassPath());
    for (final spot in _run!.spots) _drawSpot(canvas, spot);
    _drawEffects(canvas);
    canvas.restore();
    _drawWindowFrame(canvas);
    _drawCharacter(canvas);
    _drawParticles(canvas);
    if (_run!.complete) {
      final pulse = 0.75 + math.sin(_now * 0.01) * 0.2;
      final paint = ui.Paint()
        ..color = ui.Color.fromARGB(
            (pulse * 255).round(), 255, 244, 168);
      for (int i = 0; i < 6; i += 1) {
        final x = _frame.left + _frame.width * (0.18 + (i % 3) * 0.31);
        final y = _frame.top + _frame.height * (0.2 + (i ~/ 3) * 0.45);
        _starPath(canvas, x, y, 7 + (i % 2) * 4, paint);
      }
    }
  }

  void disposeGame() {
    _active = false;
    _run = null;
    _particles.clear();
    _effects.clear();
  }

  LevelData get levelData => _levelData;
  String get selectedTool => _selectedTool;
}
