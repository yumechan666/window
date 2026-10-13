import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'package:window/game/audio.dart';
import 'package:window/game/atlas.dart';
import 'package:window/game/data.dart';
import 'package:window/game/gameplay.dart';
import 'package:window/game/progress.dart';
import 'level_1_tutorial.dart';

enum Screen { main, levels, skins, settings }

class _FramePainter extends CustomPainter {
  final void Function(ui.Canvas, ui.Rect) draw;
  _FramePainter(this.draw);
  @override
  void paint(ui.Canvas canvas, ui.Size size) =>
      draw(canvas, ui.Rect.fromLTWH(0, 0, size.width, size.height));
  @override
  bool shouldRepaint(covariant _FramePainter old) => false;
}

class AppHome extends StatefulWidget {
  final GameMedia media;
  final Progress progress;
  final GameConfig config;
  final AudioManager audio;
  const AppHome(
    this.media,
    this.progress,
    this.config,
    this.audio, {
    super.key,
  });

  @override
  State<AppHome> createState() => _AppHomeState();
}

class _AppHomeState extends State<AppHome> {
  Screen _screen = Screen.main;
  int? _activeLevel;
  int? _pendingLevel;
  bool _showHowTo = false;

  @override
  void initState() {
    super.initState();
    widget.audio.unlock();
  }

  void _go(Screen s) {
    setState(() {
      _activeLevel = null;
      _screen = s;
    });
  }

  void _play(int level) {
    widget.audio.play('select');
    widget.progress.hasPlayed = true;
    widget.progress.save();
    setState(() => _activeLevel = level);
  }

  void _startAfterHowTo() {
    widget.progress.hasPlayed = true;
    widget.progress.save();
    final level = _pendingLevel ?? 1;
    setState(() {
      _showHowTo = false;
      _pendingLevel = null;
      _activeLevel = level;
    });
  }

  void _resetGame() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xff16324a),
        title: const Text(
          'Reset Permainan?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Semua progres, koin, dan skin akan dikembalikan ke awal.',
          style: TextStyle(color: Color(0xff9fb6c8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'BATAL',
              style: TextStyle(color: Color(0xff9fd4ff)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff37c2ff),
            ),
            onPressed: () {
              widget.progress.resetProgress();
              widget.progress.save();
              Navigator.of(ctx).pop();
              setState(() {
                _activeLevel = null;
                _screen = Screen.main;
              });
            },
            child: const Text('RESET'),
          ),
        ],
      ),
    );
  }

  void _nextLevel() {
    if (_activeLevel == null || _activeLevel! >= maxLevel) return;
    setState(() => _activeLevel = _activeLevel! + 1);
  }

  @override
  Widget build(BuildContext context) {
    final Widget body;
    if (_activeLevel != null) {
      body = GameScreen(
        key: ValueKey<int>(_activeLevel!),
        media: widget.media,
        progress: widget.progress,
        config: widget.config,
        audio: widget.audio,
        level: _activeLevel!,
        onHome: () => _go(Screen.main),
        onLevels: () => _go(Screen.levels),
        onSkins: () => _go(Screen.skins),
        onNextLevel: _nextLevel,
      );
    } else {
      switch (_screen) {
        case Screen.main:
          body = _mainMenu(context);
        case Screen.levels:
          body = _levelSelect(context);
        case Screen.skins:
          body = _skins(context);
        case Screen.settings:
          body = _settings(context);
      }
    }
    return Stack(
      children: [
        body,
        if (_showHowTo) Positioned.fill(child: _howToOverlay()),
      ],
    );
  }

  Widget _howToOverlay() => Container(
    color: const Color(0xdd0b1722),
    child: LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: constraints.maxHeight - 48,
            maxWidth: 360,
          ),
          child: Center(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: const Color(0xff16324a),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x55000000),
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'CARA BERMAIN',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Bersihkan semua noda di kaca!',
                    style: TextStyle(color: Color(0xff9fd4ff), fontSize: 13),
                  ),
                  const SizedBox(height: 18),
                  _howToStep(
                    Icons.gesture,
                    'Gosok & geser',
                    'Usap noda di kaca dengan jari atau kuas.',
                  ),
                  _howToStep(
                    Icons.build,
                    'Pilih alatnya',
                    'Setiap noda butuh alat yang tepat. Coba satu bila ragu.',
                  ),
                  _howToStep(
                    Icons.water_drop,
                    'Semprot cairan',
                    'Gunakan spray/foam bila perlu, tunggu, lalu gosok.',
                  ),
                  _howToStep(
                    Icons.stars,
                    'Selesaikan level',
                    'Bersihkan semua noda untuk dapat bintang & koin.',
                  ),
                  const SizedBox(height: 22),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff37c2ff),
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _startAfterHowTo,
                    child: const Text(
                      'MULAI',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _howToStep(IconData icon, String title, String desc) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0x3329d8ff),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: const Color(0xff6fe3ff), size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: const TextStyle(color: Color(0xff9fb6c8), fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _coinBadge() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: const Color(0xff2a3a4d),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      children: [
        const Icon(Icons.circle, size: 12, color: Color(0xffffe26b)),
        const SizedBox(width: 6),
        Text(
          widget.progress.coins.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );

  Widget _mainMenu(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xff1a1a1a),
    body: SafeArea(
      child: Center(
        child: AspectRatio(
          aspectRatio: 9 / 16,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final h = constraints.maxHeight;

              return Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      'assets/images/main_menu.png',
                      fit: BoxFit.fill,
                      errorBuilder: (context, error, stackTrace) => Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xff16324a), Color(0xff0b1722)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                                'SQUEEGE SQUAD',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Bersihkan semua noda di kaca',
                              style: TextStyle(color: Color(0xff9fd4ff)),
                            ),
                            Spacer(),
                            Padding(
                              padding: EdgeInsets.only(bottom: 30),
                              child: Text(
                                'MAIN       SKINS',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // SETTINGS
                  Positioned(
                    left: w * 0.06,
                    top: h * 0.035,
                    width: w * 0.15,
                    height: h * 0.075,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () => _go(Screen.settings),
                      child: const SizedBox.expand(),
                    ),
                  ),

                  // RESET
                  Positioned(
                    left: w * 0.5 - w * 0.12,
                    top: h * 0.035,
                    width: w * 0.24,
                    height: h * 0.05,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: _resetGame,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0x3329d8ff),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xff6fe3ff),
                            width: 1.5,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'RESET',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // MAIN / PLAY
                  Positioned(
                    left: w * 0.065,
                    bottom: h * 0.018,
                    width: w * 0.485,
                    height: h * 0.075,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () => _go(Screen.levels),
                      child: const SizedBox.expand(),
                    ),
                  ),

                  // SKINS
                  Positioned(
                    right: w * 0.065,
                    bottom: h * 0.018,
                    width: w * 0.37,
                    height: h * 0.075,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () => _go(Screen.skins),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    ),
  );

  Widget _levelSelect(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xff16324a),
    body: SafeArea(
      child: Column(
        children: [
          _pageHeader(
            'PILIH TEMA & LEVEL',
            () => _go(Screen.main),
            _coinBadge(),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: worlds.length,
              itemBuilder: (ctx, wi) {
                final world = worlds[wi];
                final first = wi * 5 + 1;
                final locked = first > widget.progress.unlockedLevel;
                return Opacity(
                  opacity: locked ? 0.5 : 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Stack(
                              children: [
                                SizedBox(
                                  width: 48,
                                  height: 42,
                                  child: CustomPaint(
                                    painter: _FramePainter(
                                      (c, r) =>
                                          widget.media.drawWorld(c, world.key, r),
                                    ),
                                  ),
                                ),
                                if (locked)
                                  Positioned.fill(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: const Color(0x77000000),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      alignment: Alignment.center,
                                      child: const Icon(
                                        Icons.lock,
                                        size: 20,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'TEMA ${wi + 1}',
                              style: const TextStyle(color: Color(0xff9fd4ff)),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    world.label,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (locked)
                                    const Text(
                                      'Selesaikan tema sebelumnya',
                                      style: TextStyle(
                                        color: Color(0xffff6b6b),
                                        fontSize: 11,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Text(
                              'LEVEL ${world.range}',
                              style: const TextStyle(color: Color(0xff9fb6c8)),
                            ),
                          ],
                        ),
                      ),
                      GridView.count(
                        crossAxisCount: 5,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        children: List.generate(5, (i) {
                          final level = first + i;
                          final unlocked =
                              level <= widget.progress.unlockedLevel;
                          final stars = widget.progress.stars[level] ?? 0;
                          return InkWell(
                            onTap: unlocked ? () => _play(level) : null,
                            child: Container(
                              decoration: BoxDecoration(
                                color: unlocked
                                    ? const Color(0xff2a3a4d)
                                    : const Color(0xff1d2a38),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    unlocked ? '$level' : '●',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                    ),
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(
                                      3,
                                      (si) => Icon(
                                        Icons.star,
                                        size: 12,
                                        color: si < stars
                                            ? const Color(0xffffe26b)
                                            : const Color(0xff44566a),
                                      ),
                                    ),
                                  ),
                                ],
      ),
                ),
              );
                        }),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ),
  );

  Widget _skins(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xff16324a),
    body: SafeArea(
      child: Column(
        children: [
          _pageHeader('SKINS', () => _go(Screen.main), _coinBadge()),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.8,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
              ),
              itemCount: skins.length,
              itemBuilder: (ctx, i) {
                final skin = skins[i];
                final owned = widget.progress.ownedSkins.contains(skin.key);
                final equipped = widget.progress.activeSkin == skin.key;
                return Container(
                  decoration: BoxDecoration(
                    color: equipped
                        ? const Color(0xff2f5a44)
                        : const Color(0xff223445),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: equipped
                          ? const Color(0xff6fe3ff)
                          : Colors.transparent,
                    ),
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: Stack(
                          children: [
                            if (equipped)
                              const Positioned(
                                top: 6,
                                left: 6,
                                child: Text(
                                  'AKTIF',
                                  style: TextStyle(
                                    color: Color(0xff6fe3ff),
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            Positioned.fill(
                              child: CustomPaint(
                                painter: _FramePainter(
                                  (c, r) => widget.media.drawSkin(
                                    c,
                                    skin.key,
                                    'idle',
                                    r,
                                  ),
                                ),
                              ),
                            ),
                            if (!owned)
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xaa000000),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    Icons.lock,
                                    size: 32,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            if (!owned && skin.price > 0)
                              Positioned(
                                bottom: 6,
                                right: 6,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xffffe26b),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.circle,
                                        size: 10,
                                        color: Color(0xffff8c00),
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        '${skin.price}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xff1a1a1a),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Text(
                        skin.label,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: owned ? FontWeight.normal : FontWeight.bold,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8, top: 4),
                        child: equipped
                            ? const Text(
                                'DIPAKAI',
                                style: TextStyle(color: Color(0xff9fd4ff)),
                              )
                            : ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: owned
                                      ? const Color(0xff37c2ff)
                                      : (widget.progress.coins >= skin.price
                                          ? const Color(0xff37c2ff)
                                          : const Color(0xff3a4b5e)),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                ),
                                onPressed: () => _useSkin(skin),
                                child: Text(
                                  owned
                                      ? 'PAKAI'
                                      : (widget.progress.coins >= skin.price
                                          ? 'BELI'
                                          : '${skin.price}'),
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ),
  );

  void _useSkin(SkinDef skin) {
    final p = widget.progress;
    if (p.ownedSkins.contains(skin.key)) {
      p.activeSkin = skin.key;
      p.save();
      widget.audio.play('tool');
      setState(() {});
      return;
    }
    if (skin.price == 0) {
      p.ownedSkins.add(skin.key);
      p.activeSkin = skin.key;
      p.save();
      widget.audio.play('purchase');
      setState(() {});
      return;
    }
    if (p.coins < skin.price) {
      widget.audio.play('wrong');
      _showNotEnoughCoins(skin.price - p.coins);
      return;
    }
    p.coins -= skin.price;
    p.ownedSkins.add(skin.key);
    p.activeSkin = skin.key;
    p.save();
    widget.audio.play('purchase');
    setState(() {});
  }

  void _showNotEnoughCoins(int needed) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xff16324a),
        title: const Text(
          'Koin Tidak Cukup',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Butuh $needed koin lagi untuk membeli skin ini.',
          style: const TextStyle(color: Color(0xff9fb6c8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'OK',
              style: TextStyle(color: Color(0xff9fd4ff)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _settings(BuildContext context) {
    final s = widget.progress.settings;
    return Scaffold(
      backgroundColor: const Color(0xff16324a),
      body: SafeArea(
        child: Column(
          children: [
            _pageHeader('PENGATURAN', () => _go(Screen.main), const SizedBox()),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _toggle('music', 'Musik', 'Melodi arcade ringan', s),
                  _toggle(
                    'sound',
                    'Efek suara',
                    'Spray, scrub, dan sparkle',
                    s,
                  ),
                  _toggle(
                    'haptics',
                    'Getaran',
                    'Pulse pada progress penting',
                    s,
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Semua level bisa diselesaikan tanpa batas cairan atau nyawa.',
                style: TextStyle(color: Color(0xff9fb6c8)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _toggle(String key, String label, String desc, Map<String, bool> s) =>
      InkWell(
        onTap: () {
          s[key] = !s[key]!;
          widget.progress.save();
          widget.audio.syncMusic();
          setState(() {});
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xff223445),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      desc,
                      style: const TextStyle(
                        color: Color(0xff9fb6c8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 44,
                height: 24,
                decoration: BoxDecoration(
                  color: s[key]!
                      ? const Color(0xff37c2ff)
                      : const Color(0xff44566a),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Align(
                  alignment: s[key]!
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.all(3),
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _pageHeader(String title, VoidCallback back, Widget trailing) =>
      Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            IconButton(
              onPressed: back,
              icon: const Icon(Icons.arrow_back, color: Colors.white),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            trailing,
          ],
        ),
      );
}

class GameScreen extends StatefulWidget {
  final GameMedia media;
  final Progress progress;
  final GameConfig config;
  final AudioManager audio;
  final int level;
  final VoidCallback onHome;
  final VoidCallback onLevels;
  final VoidCallback onSkins;
  final VoidCallback onNextLevel;
  const GameScreen({
    super.key,
    required this.media,
    required this.progress,
    required this.config,
    required this.audio,
    required this.level,
    required this.onHome,
    required this.onLevels,
    required this.onSkins,
    required this.onNextLevel,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final WindowGame _game;
  String _progress = '0%';
  String _time = '0.0s';
  int _mistakes = 0;
  String _selectedTool = '';
  String _stageTip = 'Kenali nodanya';
  bool _paused = false;
  ResultSummary? _result;
  late bool _showLevel1Tutorial;
  bool _showHowTo = false;

  @override
  void initState() {
    super.initState();
    _game = WindowGame(
      widget.media,
      widget.progress,
      widget.config,
      widget.audio,
    );
    _game.hud.onProgress = (v) => setState(() => _progress = v);
    _game.hud.onTime = (v) => setState(() => _time = v);
    _game.hud.onMistakes = (v) => setState(() => _mistakes = v);
    _game.hud.onSelectedTool = (v) => setState(() => _selectedTool = v);
    _game.hud.onStageTip = (v) => setState(() => _stageTip = v);
    _game.hud.onPause = () => setState(() => _paused = true);
    _game.hud.onComplete = (r) => setState(() => _result = r);
    widget.audio.unlock();
    _showLevel1Tutorial = widget.level == 1;
    _game.startLevel(makeLevel(widget.level));
  }

  @override
  void dispose() {
    widget.progress.save();
    _game.disposeGame();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final toolKeys = getUnlockedTools(widget.level);
    return Scaffold(
      backgroundColor: const Color(0xff16324a),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Stack(
                              children: [
                                Container(
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: const Color(0xff223445),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: FractionallySizedBox(
                                    alignment: Alignment.centerLeft,
                                    widthFactor: _parseProgress(_progress),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: const Color(0xff37c2ff),
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned.fill(
                                  child: Center(
                                    child: Text(
                                      _progress,
                                      style: const TextStyle(
                                        fontSize: 9,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_game.levelData.world.label} • ${_game.levelData.windowType.label} • ${_game.levelData.difficulty.name} • ${_game.levelData.spots.length} NODA',
                              style: const TextStyle(
                                color: Color(0xff9fb6c8),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      _badge('◷', _time),
                      const SizedBox(width: 6),
                      _badge('×', '$_mistakes'),
                      IconButton(
                        onPressed: () => setState(() => _showHowTo = true),
                        icon: const Icon(Icons.help_outline, color: Colors.white),
                        tooltip: 'Cara Bermain',
                      ),
                      IconButton(
                        onPressed: () {
                          final s = widget.progress.settings;
                          s['music'] = !s['music']!;
                          s['sound'] = !s['sound']!;
                          widget.progress.save();
                          widget.audio.syncMusic();
                          setState(() {});
                        },
                        icon: Icon(
                          (widget.progress.settings['music']! || widget.progress.settings['sound']!)
                              ? Icons.volume_up
                              : Icons.volume_off,
                          color: Colors.white,
                        ),
                        tooltip: 'Volume',
                      ),
                      IconButton(
                        onPressed: () => _game.pause(),
                        icon: const Icon(Icons.pause, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Stack(
                    children: [
                      GameWidget(game: _game),
                      Positioned.fill(
                        child: Listener(
                          behavior: HitTestBehavior.opaque,
                          onPointerDown: (e) =>
                              _game.onPointerDown(e.localPosition),
                          onPointerMove: (e) =>
                              _game.onPointerMove(e.localPosition),
                          onPointerUp: (_) => _game.onPointerUp(),
                          onPointerCancel: (_) => _game.onPointerUp(),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text(
                            _selectedTool,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _stageTip,
                            style: const TextStyle(
                              color: Color(0xff9fd4ff),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 64,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: toolKeys.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (ctx, i) {
                            final tool = toolKeys[i];
                            final selected = tool == _game.selectedTool;
                            return GestureDetector(
                              onTap: () => _game.selectTool(tool),
                              child: Container(
                                width: 60,
                                decoration: BoxDecoration(
                                  color: selected
                                      ? const Color(0xff37c2ff)
                                      : const Color(0xff223445),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  children: [
                                    SizedBox(
                                      height: 42,
                                      width: 58,
                                      child: CustomPaint(
                                        painter: _FramePainter(
                                          (c, r) =>
                                              widget.media.drawTool(c, tool, r),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      tools[tool]!.short,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
      ),
    );

                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_showLevel1Tutorial)
              Level1TutorialOverlay(
                media: widget.media,
                onSkip: () => setState(() => _showLevel1Tutorial = false),
              ),
            if (_showHowTo) _howToOverlay(),
            if (_paused) _pauseOverlay(),
            if (_result != null) _resultOverlay(),
          ],
        ),
      ),
    );
  }

  double _parseProgress(String p) =>
      (double.tryParse(p.replaceAll('%', '')) ?? 0) / 100;

  Widget _badge(String icon, String value) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: const Color(0xff2a3a4d),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      children: [
        Text(icon, style: const TextStyle(color: Color(0xff9fd4ff))),
        const SizedBox(width: 4),
        Text(value, style: const TextStyle(color: Colors.white)),
      ],
    ),
  );

  Widget _pauseOverlay() => Container(
    color: const Color(0xaa0b1722),
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'DIJEDA',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff37c2ff),
            ),
            onPressed: () {
              _game.resume();
              setState(() => _paused = false);
            },
            child: const Text('LANJUT'),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xff9fd4ff)),
            ),
            onPressed: widget.onLevels,
            child: const Text(
              'PILIH LEVEL',
              style: TextStyle(color: Color(0xff9fd4ff)),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _howToOverlay() => Container(
    color: const Color(0xdd0b1722),
    child: Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: const Color(0xff16324a),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x55000000),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'CARA BERMAIN',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _showHowTo = false),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
              const Text(
                'Bersihkan semua noda di kaca!',
                style: TextStyle(color: Color(0xff9fd4ff), fontSize: 13),
              ),
              const SizedBox(height: 18),
              _howToStep(
                Icons.gesture,
                'Gosok & geser',
                'Usap noda di kaca dengan jari atau kuas.',
              ),
              _howToStep(
                Icons.build,
                'Pilih alatnya',
                'Setiap noda butuh alat yang tepat. Coba satu bila ragu.',
              ),
              _howToStep(
                Icons.water_drop,
                'Semprot cairan',
                'Gunakan spray/foam bila perlu, tunggu, lalu gosok.',
              ),
              _howToStep(
                Icons.stars,
                'Selesaikan level',
                'Bersihkan semua noda untuk dapat bintang & koin.',
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _howToStep(IconData icon, String title, String desc) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0x3329d8ff),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: const Color(0xff6fe3ff), size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: const TextStyle(color: Color(0xff9fb6c8), fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _resultOverlay() => Container(
    color: const Color(0xaa0b1722),
    child: Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xff16324a),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '✨ 100% CLEAN ✨',
              style: TextStyle(color: Color(0xff9fd4ff)),
            ),
            const Text(
              'JENDELA BERSIH!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                3,
                (i) => Icon(
                  Icons.star,
                  size: 36,
                  color: i < _result!.stars
                      ? const Color(0xffffe26b)
                      : const Color(0xff44566a),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'WAKTU ${_result!.seconds.toStringAsFixed(1)}s   '
              'MISTAKES $_mistakes   SKOR ${_result!.score}   +${_result!.coinGain} KOIN',
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xff9fd4ff)),
                    ),
                    onPressed: () {
                      _result = null;
                      _game.startLevel(makeLevel(widget.level));
                    },
                    child: const Text(
                      'ULANGI',
                      style: TextStyle(color: Color(0xff9fd4ff)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff37c2ff),
                    ),
                    onPressed: () {
                      if (widget.level >= maxLevel) {
                        widget.onLevels();
                      } else {
                        widget.onNextLevel();
                      }
                    },
                    child: Text(
                      widget.level >= maxLevel
                          ? 'PILIH LEVEL'
                          : 'LEVEL BERIKUTNYA',
                    ),
                  ),
                ),
              ],
            ),
            ],
          ),
        ),
      ),
      );
}
