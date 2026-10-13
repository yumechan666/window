import 'package:flutter/material.dart';
import 'package:window/game/atlas.dart';

class Level1TutorialOverlay extends StatefulWidget {
  final GameMedia media;
  final VoidCallback onSkip;
  const Level1TutorialOverlay({
    super.key,
    required this.media,
    required this.onSkip,
  });

  @override
  State<Level1TutorialOverlay> createState() => _Level1TutorialOverlayState();
}

class _Level1TutorialOverlayState extends State<Level1TutorialOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _pageController = PageController();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      widget.onSkip();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xdd0b1722),
      child: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentPage = index),
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildPage1(),
              _buildPage2(),
              _buildPage3(),
              _buildPage4(),
            ],
          ),
          Positioned(
            top: 16,
            right: 16,
            child: GestureDetector(
              onTap: widget.onSkip,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0x4429d8ff),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xff6fe3ff), width: 1),
                ),
                child: const Text(
                  'SKIP',
                  style: TextStyle(
                    color: Color(0xff6fe3ff),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    4,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: index == _currentPage
                            ? const Color(0xff37c2ff)
                            : const Color(0xff44566a),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff37c2ff),
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _nextPage,
                    child: Text(
                      _currentPage == 3 ? 'MULAI BERMAIN' : 'LANJUT',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage1() => Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xff16324a).withValues(alpha: 0.8),
          const Color(0xff0b1722).withValues(alpha: 0.9),
        ],
      ),
    ),
    child: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            const Text(
              'SELAMAT DATANG! 👋',
              style: TextStyle(
                color: Color(0xff6fe3ff),
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'WINDOW CLEANING',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Anda akan belajar cara membersihkan kaca dengan benar!',
              style: TextStyle(
                color: Color(0xff9fd4ff),
                fontSize: 15,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: const Color(0xff223445),
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x3329d8ff),
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Image.asset(
                'assets/images/window_frame.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.window,
                  size: 80,
                  color: Color(0xff6fe3ff),
                ),
              ),
            ),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0x1f6fe3ff),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xff6fe3ff),
                  width: 1,
                ),
              ),
              child: const Text(
                '💡 Tip: Kaca kotor akan muncul di layar. Tugasmu adalah membersihkannya menggunakan alat-alat yang tepat.',
                style: TextStyle(
                  color: Color(0xff9fd4ff),
                  fontSize: 13,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    ),
  );

  Widget _buildPage2() => Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xff16324a).withValues(alpha: 0.8),
          const Color(0xff0b1722).withValues(alpha: 0.9),
        ],
      ),
    ),
    child: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            const Text(
              'STEP 1: IDENTIFIKASI NODA',
              style: TextStyle(
                color: Color(0xff6fe3ff),
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xff223445),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  const Text(
                    'Setiap noda memiliki TANDA PENGENAL',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: const Color(0xff1d2a38),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.blur_on,
                          size: 40,
                          color: Color(0xffd9a574),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'NODA DEBU',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Warna kuning/cokelat, halus dan ringan',
                              style: TextStyle(
                                color: Color(0xff9fd4ff),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Color(0xff44566a)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: const Color(0xff1d2a38),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.opacity,
                          size: 40,
                          color: Color(0xff7fa8c7),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'BEKAS AIR',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Garis putih, perlu spray & squeegee',
                              style: TextStyle(
                                color: Color(0xff9fd4ff),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Color(0xff44566a)),
                  const SizedBox(height: 16),
                  const Text(
                    '🏷️ Setiap noda akan menunjukkan BADGE dengan alat yang dibutuhkan!',
                    style: TextStyle(
                      color: Color(0xff6fe3ff),
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    ),
  );

  Widget _buildPage3() => Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xff16324a).withValues(alpha: 0.8),
          const Color(0xff0b1722).withValues(alpha: 0.9),
        ],
      ),
    ),
    child: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            const Text(
              'STEP 2: GUNAKAN ALAT YANG BENAR',
              style: TextStyle(
                color: Color(0xff6fe3ff),
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 24),
            _buildToolExplanation(
              'ALAT USAP (Wipe)',
              ['Sponge', 'Squeegee', 'Cloth'],
              const Color(0xff9fd4ff),
              Icons.pan_tool,
              'TARIK/DRAG di atas noda dengan gerakan perlahan dan berulang.',
            ),
            const SizedBox(height: 20),
            _buildToolExplanation(
              'ALAT CAIR (Liquid)',
              ['Glass Cleaner', 'Water', 'Spray'],
              const Color(0xff6fd8ff),
              Icons.water_drop,
              'TAP/TEKAN pada noda untuk menyemprotkan cairan pembersih.',
            ),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0x1ffff4a8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xfffff4a8),
                  width: 1,
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info, color: Color(0xfffff4a8), size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Lihat BADGE di noda untuk tahu alat mana yang diperlukan!',
                      style: TextStyle(
                        color: Color(0xfffff4a8),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    ),
  );

  Widget _buildToolExplanation(
    String title,
    List<String> tools,
    Color color,
    IconData icon,
    String description,
  ) =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xff223445),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: tools
                  .map(
                    (tool) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0x1f6fe3ff),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xff6fe3ff),
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        tool,
                        style: const TextStyle(
                          color: Color(0xff9fd4ff),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      );

  Widget _buildPage4() => Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xff16324a).withValues(alpha: 0.8),
          const Color(0xff0b1722).withValues(alpha: 0.9),
        ],
      ),
    ),
    child: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            const Text(
              'STEP 3: SELESAIKAN LEVEL',
              style: TextStyle(
                color: Color(0xff6fe3ff),
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xff223445),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  _buildStepCard(
                    '1',
                    'Baca HINT',
                    'Petunjuk di bawah akan mengatakan alat apa yang dibutuhkan',
                    const Color(0xffffe26b),
                  ),
                  const SizedBox(height: 16),
                  _buildStepCard(
                    '2',
                    'Bersihkan Setiap Noda',
                    'Ikuti recipe yang ditunjukkan badge sampai noda hilang',
                    const Color(0xff6fd8ff),
                  ),
                  const SizedBox(height: 16),
                  _buildStepCard(
                    '3',
                    'Dapatkan Bintang',
                    'Semakin cepat dan akurat, semakin banyak bintang ⭐',
                    const Color(0xff6fe3ff),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0x1f37c2ff),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xff37c2ff),
                  width: 1.5,
                ),
              ),
              child: Column(
                children: const [
                  Text(
                    '⭐⭐⭐ SEMPURNA! ⭐⭐⭐',
                    style: TextStyle(
                      color: Color(0xffffe26b),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Waktu cepat + Tanpa kesalahan',
                    style: TextStyle(
                      color: Color(0xff37c2ff),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0x1f6fe3ff),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xff6fe3ff),
                  width: 1,
                ),
              ),
              child: const Column(
                children: [
                  Text(
                    '🎮 SIAP BERMAIN?',
                    style: TextStyle(
                      color: Color(0xff6fe3ff),
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tekan "MULAI BERMAIN" untuk memulai Level 1 dan bersihkan kaca pertamamu!',
                    style: TextStyle(
                      color: Color(0xff9fd4ff),
                      fontSize: 13,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    ),
  );

  Widget _buildStepCard(
    String number,
    String title,
    String description,
    Color accentColor,
  ) =>
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: accentColor, width: 2),
            ),
            alignment: Alignment.center,
            child: Text(
              number,
              style: TextStyle(
                color: accentColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: Color(0xff9fb6c8),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
}
