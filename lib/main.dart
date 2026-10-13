import 'package:flutter/material.dart';

import 'game/atlas.dart';
import 'game/audio.dart';
import 'game/gameplay.dart';
import 'game/progress.dart';
import 'ui/app.dart';

void main() => runApp(const BootApp());

class BootApp extends StatefulWidget {
  const BootApp({super.key});

  @override
  State<BootApp> createState() => _BootAppState();
}

class _BootAppState extends State<BootApp> {
  bool _loading = true;
  String? _error;
  GameMedia? _media;
  Progress _progress = Progress();
  final GameConfig _config = GameConfig();
  late AudioManager _audio;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    try {
      _progress = await Progress.load();
      _audio = AudioManager(_progress.settings);
      _audio.unlock();
      _media = await GameMedia.load();
    } catch (e) {
      _error = 'Aset permainan belum berhasil dimuat.';
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const MaterialApp(
        home: Scaffold(
          backgroundColor: Color(0xff16324a),
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Color(0xff6fe3ff)),
                SizedBox(height: 16),
                Text('Menyiapkan kaca…', style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
        ),
      );
    }
    if (_error != null || _media == null) {
      return MaterialApp(
        home: Scaffold(
          backgroundColor: const Color(0xff16324a),
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Belum siap',
                  style: TextStyle(color: Colors.white, fontSize: 24),
                ),
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    _error ?? '',
                    style: const TextStyle(color: Color(0xff9fb6c8)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AppHome(_media!, _progress, _config, _audio),
    );
  }
}
