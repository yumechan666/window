import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class AudioManager {
  final Map<String, bool> settings;
  final AudioPlayer _music = AudioPlayer();
  bool unlocked = false;
  bool _musicPlaying = false;
  bool _musicStarting = false;

  static const _assets = <String, String>{
    'tap': 'tap',
    'select': 'select',
    'tool': 'tool',
    'scrub': 'scrub',
    'spray': 'spray',
    'water': 'water',
    'foam': 'foam',
    'polish': 'polish',
    'clean': 'clean',
    'wrong': 'wrong',
    'complete': 'complete',
    'level_start': 'level_start',
    'pause': 'pause',
    'resume': 'resume',
    'purchase': 'purchase',
    'win': 'win',
    'jump': 'jump',
    'hit': 'hit',
    'click': 'click',
    'error': 'error',
    'splash': 'splash',
    'bubble': 'bubble',
    'wipe': 'wipe',
    'coin': 'coin',
    'star': 'star',
    'level_complete': 'level_complete',
  };

  AudioManager(this.settings);

  AudioContext _noFocusContext() => AudioContext(
    android: AudioContextAndroid(
      isSpeakerphoneOn: false,
      stayAwake: false,
      contentType: AndroidContentType.music,
      usageType: AndroidUsageType.media,
      audioFocus: AndroidAudioFocus.none,
    ),
    iOS: AudioContextIOS(
      category: AVAudioSessionCategory.playback,
      options: const <AVAudioSessionOptions>{
        AVAudioSessionOptions.mixWithOthers,
      },
    ),
  );

  void unlock() {
    unlocked = true;
    unawaited(syncMusic());
  }

  Future<void> play(String name) async {
    if (!unlocked || settings['sound'] != true) return;
    // Browsers block autoplay until a user gesture. A tap that triggers an
    // SFX is also a safe moment to retry the background music.
    if (settings['music'] == true && !_musicPlaying) {
      unawaited(syncMusic());
    }
    final asset = _assets[name] ?? 'tap';
    // Each SFX gets its own player so overlapping effects do not cut each
    // other off, while the separate music player keeps playing underneath.
    final player = AudioPlayer();
    try {
      await player.setAudioContext(_noFocusContext());
      player.onPlayerComplete.listen((_) {
        unawaited(player.dispose());
      });
      await player.play(AssetSource('audio/$asset.wav'), volume: 0.8);
    } catch (error) {
      if (kDebugMode) debugPrint('[audio] SFX $asset failed: $error');
      await player.dispose();
    }
  }

  Future<void> syncMusic() async {
    if (!unlocked || settings['music'] != true) {
      if (_musicPlaying) {
        await _music.stop();
        _musicPlaying = false;
      }
      return;
    }
    if (_musicPlaying || _musicStarting) return;
    _musicStarting = true;
    try {
      await _music.setReleaseMode(ReleaseMode.loop);
      await _music.setVolume(0.35);
      if (!unlocked || settings['music'] != true) return;
      await _music.play(AssetSource('audio/bgm.wav'));
      _musicPlaying = true;
    } catch (error) {
      _musicPlaying = false;
      if (kDebugMode) debugPrint('[audio] BGM failed: $error');
    } finally {
      _musicStarting = false;
    }
  }

  Future<void> destroy() async {
    await _music.dispose();
    unlocked = false;
  }
}
