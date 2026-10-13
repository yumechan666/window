import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/services.dart';

// Port of game js/game/media.js: atlas + frame loading and drawing helpers.

class Frame {
  final String name;
  final Rect source;
  final Rect content;
  final Offset anchor;
  Frame(this.name, this.source, this.content, this.anchor);

  factory Frame.fromJson(Map<String, dynamic> j) {
    final s = j['source'] as Map<String, dynamic>;
    final c = (j['content'] as Map<String, dynamic>?) ??
        (j['source'] as Map<String, dynamic>);
    final a = (j['anchor'] as Map<String, dynamic>?);
    return Frame(
      j['name'] as String,
      Rect.fromLTWH(s['x'].toDouble(), s['y'].toDouble(),
          s['w'].toDouble(), s['h'].toDouble()),
      Rect.fromLTWH(c['x'].toDouble(), c['y'].toDouble(),
          c['w'].toDouble(), c['h'].toDouble()),
      a != null
          ? Offset(a['x'].toDouble(), a['y'].toDouble())
          : Offset.zero,
    );
  }
}

class Atlas {
  final ui.Image image;
  final List<Frame> frames;
  final Map<String, Frame> byName;
  Atlas(this.image, this.frames) : byName = {for (final f in frames) f.name: f};

  bool contains(String name) => byName.containsKey(name);

  /// Draw a frame scaled into [box]. cover=true fills and crops, otherwise
  /// it fits (contain) and centers.
  void paint(ui.Canvas canvas, String name, Rect box,
      {bool cover = false, bool useContent = true}) {
    final frame = byName[name];
    if (frame == null) return;
    // Tool icons use the complete source tile. Some generated content bounds
    // extend beyond the tile and can make the icon disappear when cropped.
    final crop = useContent ? frame.content : frame.source;
    final scale = cover
        ? math.max(box.width / crop.width, box.height / crop.height)
        : math.min(box.width / crop.width, box.height / crop.height);
    final dw = crop.width * scale;
    final dh = crop.height * scale;
    final dx = box.left + (box.width - dw) / 2;
    final dy = box.top + (box.height - dh) / 2;
    if (cover) {
      canvas.save();
      canvas.clipRect(box);
    }
    canvas.drawImageRect(image, crop, ui.Rect.fromLTWH(dx, dy, dw, dh), ui.Paint());
    if (cover) canvas.restore();
  }
}

const _imageFiles = {
  'WORLD_BACKDROPS': 'world_backdrops-transparent.webp',
  'WORLD_BACKDROPS_EXTRA': 'world_backdrops_extra-transparent.webp',
  'CLEANER_SKINS': 'cleaner_skins-transparent.webp',
  'CLEANER_SKINS_EXTRA': 'cleaner_skins_extra-transparent.webp',
  'CLEANER_SKINS_SET_3': 'cleaner_skins_set_3-transparent.webp',
  'CLEANER_SKINS_SET_4': 'cleaner_skins_set_4-transparent.webp',
  'CLEANER_SKINS_SET_5': 'cleaner_skins_set_5-transparent.webp',
  'CLEANER_SKINS_SET_6': 'cleaner_skins_set_6-transparent.webp',
  'TOOL_ICONS': 'tool_icons-transparent.webp',
  'TOOL_ICONS_EXTRA': 'tool_icons_extra-transparent.webp',
  'GRIME_DECALS': 'grime_decals-transparent.webp',
  'GRIME_DECALS_EXTRA': 'grime_decals_extra-transparent.webp',
  'CLEANING_EFFECTS': 'cleaning_effects-transparent.webp',
  'WINDOW_FRAME': 'window_frame-transparent.webp',
};

const _atlasKeys = [
  'WORLD_BACKDROPS', 'WORLD_BACKDROPS_EXTRA',
  'CLEANER_SKINS', 'CLEANER_SKINS_EXTRA', 'CLEANER_SKINS_SET_3',
  'CLEANER_SKINS_SET_4', 'CLEANER_SKINS_SET_5', 'CLEANER_SKINS_SET_6',
  'TOOL_ICONS', 'TOOL_ICONS_EXTRA',
  'GRIME_DECALS', 'GRIME_DECALS_EXTRA', 'CLEANING_EFFECTS',
];

Future<ui.Image> _loadUiImage(String asset) async {
  final data = await rootBundle.load(asset);
  final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
  final frame = await codec.getNextFrame();
  return frame.image;
}

Future<Atlas> _loadAtlas(String key) async {
  final image = await _loadUiImage('assets/images/${_imageFiles[key]!}');
  final jsonName = _imageFiles[key]!.replaceFirst('.webp', '.frames.json');
  final text = await rootBundle.loadString('assets/json/$jsonName');
  final data = jsonDecode(text) as Map<String, dynamic>;
  final frames = (data['frames'] as List)
      .map((f) => Frame.fromJson(f as Map<String, dynamic>))
      .toList();
  return Atlas(image, frames);
}

class GameMedia {
  late final Atlas worlds;
  late final Atlas extraWorlds;
  late final Atlas skins;
  late final Atlas extraSkins;
  late final List<Atlas> skinAtlases;
  late final Atlas tools;
  late final Atlas extraTools;
  late final Atlas grime;
  late final Atlas extraGrime;
  late final Atlas effects;
  late final ui.Image windowFrame;

  static Future<GameMedia> load() async {
    final m = GameMedia();
    final results = await Future.wait(_atlasKeys.map(_loadAtlas));
    m.worlds = results[0];
    m.extraWorlds = results[1];
    m.skins = results[2];
    m.extraSkins = results[3];
    m.skinAtlases = results.sublist(2, 8);
    m.tools = results[8];
    m.extraTools = results[9];
    m.grime = results[10];
    m.extraGrime = results[11];
    m.effects = results[12];
    m.windowFrame = await _loadUiImage('assets/images/${_imageFiles['WINDOW_FRAME']!}');
    return m;
  }

  Atlas _pair(String name, Atlas primary, Atlas secondary) =>
      primary.contains(name) ? primary : secondary;

  void drawWorld(ui.Canvas canvas, String name, Rect box, {bool cover = true}) =>
      _pair(name, worlds, extraWorlds).paint(canvas, name, box, cover: cover);

  void drawTool(ui.Canvas canvas, String name, Rect box) =>
      _pair(name, tools, extraTools).paint(canvas, name, box);

  void drawGrime(ui.Canvas canvas, String name, Rect box) =>
      _pair(name, grime, extraGrime).paint(canvas, name, box);

  void drawEffect(ui.Canvas canvas, String name, Rect box) =>
      effects.paint(canvas, name, box);

  void drawSkin(ui.Canvas canvas, String skin, String mood, Rect box) {
    final name = '${skin}_$mood';
    for (final atlas in skinAtlases) {
      if (atlas.contains(name)) {
        atlas.paint(canvas, name, box);
        return;
      }
    }
  }
}
