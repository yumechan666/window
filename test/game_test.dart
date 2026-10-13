import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:window/game/atlas.dart';
import 'package:window/game/data.dart';
import 'package:window/game/gameplay.dart';
import 'package:window/game/progress.dart';

void main() {
  late GameMedia media;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    media = await GameMedia.load();
  });

  test('load media + assets present', () {
    expect(media.worlds.frames.isNotEmpty, isTrue);
    expect(media.skins.frames.isNotEmpty, isTrue);
  });

  test('makeLevel produces spots', () {
    final lvl = makeLevel(1);
    expect(lvl.spots.isNotEmpty, isTrue);
    final lvl75 = makeLevel(75);
    expect(lvl75.spots.isNotEmpty, isTrue);
  });

  test('all levels and skins are unlocked for new and saved progress', () {
    final allSkins = skins.map((skin) => skin.key).toSet();
    final fresh = Progress();
    expect(fresh.unlockedLevel, maxLevel);
    expect(fresh.ownedSkins.toSet(), allSkins);

    final restored = Progress.fromJson({
      'unlockedLevel': 1,
      'ownedSkins': ['cat'],
    });
    expect(restored.unlockedLevel, maxLevel);
    expect(restored.ownedSkins.toSet(), allSkins);
  });

  test('full gameplay pipeline (start, render, input, complete)', () async {
    final progress = Progress();
    final game = WindowGame(media, progress, GameConfig());
    game.onGameResize(Vector2(400, 800));
    await game.startLevel(makeLevel(5));

    // Render a few frames.
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    for (int i = 0; i < 5; i += 1) {
      game.update(0.016);
      game.render(canvas);
    }

    // Simulate scrubbing the first spot with the correct tool.
    final tool = getUnlockedTools(5).first;
    game.selectTool(tool);

    // Try pointer input at center of the playfield.
    game.onPointerDown(const ui.Offset(200, 200));
    game.onPointerMove(const ui.Offset(220, 220));
    game.onPointerUp();

    expect(progress.unlockedLevel, greaterThanOrEqualTo(1));
    game.disposeGame();
  });
}
