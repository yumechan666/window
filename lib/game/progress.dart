import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import 'data.dart';

// Port of game js/game/store.js — persistent player progress.

class Progress {
  int unlockedLevel = 1;
  int coins = 0;
  Map<int, int> stars = {};
  List<String> ownedSkins = ['cat'];
  String activeSkin = 'cat';
  Map<String, bool> settings = {'music': true, 'sound': true, 'haptics': true};
  bool hasPlayed = false;

  Progress();

  Progress.fromJson(Map<String, dynamic> json) {
    final valid = skins.map((s) => s.key).toSet();
    unlockedLevel = max(1, int.tryParse(json['unlockedLevel']?.toString() ?? '1') ?? 1);
    coins = max(0, int.tryParse(json['coins']?.toString() ?? '0') ?? 0);
    final rawStars = json['stars'] as Map<String, dynamic>?;
    if (rawStars != null) {
      stars = rawStars.map(
        (k, v) =>
            MapEntry(int.parse(k), max(0, int.tryParse(v.toString()) ?? 0)),
      );
    }
    final rawOwnedSkins = json['ownedSkins'] as List<dynamic>?;
    if (rawOwnedSkins != null) {
      ownedSkins = rawOwnedSkins
          .whereType<String>()
          .where((s) => valid.contains(s))
          .toList();
    }
    if (ownedSkins.isEmpty) ownedSkins = ['cat'];
    activeSkin =
        (valid.contains(json['activeSkin']) &&
            ownedSkins.contains(json['activeSkin']))
        ? json['activeSkin'] as String
        : ownedSkins.first;
    hasPlayed = json['hasPlayed'] is bool ? json['hasPlayed'] as bool : false;
    final rawSettings = json['settings'] as Map<String, dynamic>?;
    if (rawSettings != null) {
      for (final key in settings.keys) {
        if (rawSettings[key] is bool) settings[key] = rawSettings[key] as bool;
      }
    }
  }

  Map<String, dynamic> toJson() => {
    'version': 1,
    'unlockedLevel': unlockedLevel,
    'coins': coins,
    'stars': stars.map((k, v) => MapEntry(k.toString(), v)),
    'ownedSkins': ownedSkins,
    'activeSkin': activeSkin,
    'settings': settings,
    'hasPlayed': hasPlayed,
  };

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('window_cleaner_save', jsonEncode(toJson()));
  }

  void resetProgress() {
    unlockedLevel = 1;
    coins = 0;
    stars = {};
    ownedSkins = ['cat'];
    activeSkin = 'cat';
    hasPlayed = false;
  }

  static Future<Progress> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('window_cleaner_save');
    if (raw == null) return Progress();
    try {
      return Progress.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return Progress();
    }
  }
}
