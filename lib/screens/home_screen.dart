import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'game_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late final AnimationController _floatCtrl;
  late final AnimationController _glowCtrl;
  late final Animation<double> _floatAnim;
  late final Animation<double> _glowAnim;

  int _highScore = 0;
  bool _ready = false; // animations only start after first frame

  @override
  void initState() {
    super.initState();

    // ── Controllers created but NOT started yet ───────────────────────────────
    _floatCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2200));
    _glowCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600));

    _floatAnim = Tween<double>(begin: -10, end: 10)
        .animate(CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));
    _glowAnim = Tween<double>(begin: 0.4, end: 1.0)
        .animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));

    // ── Load prefs + start animations AFTER first frame is drawn ─────────────
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // SharedPreferences already warmed-up in main(), so this is instant
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() {
        _highScore = prefs.getInt('brainblocks_hs') ?? 0;
        _ready = true;
      });
      _floatCtrl.repeat(reverse: true);
      _glowCtrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  void _startGame() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => GameScreen(highScore: _highScore)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Scaffold bg covers the gradient flicker while loading
      backgroundColor: const Color(0xFF07071A),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF07071A), Color(0xFF0D0D2B), Color(0xFF12112B)],
          ),
        ),
        child: SafeArea(
          child: _ready ? _buildContent() : _buildSplash(),
        ),
      ),
    );
  }

  // ── Shown for the single frame before animations kick in ─────────────────
  Widget _buildSplash() {
    return const Center(
      child: SizedBox(
        width: 32,
        height: 32,
        child: CircularProgressIndicator(
          color: Color(0xFF6C63FF),
          strokeWidth: 2,
        ),
      ),
    );
  }

  // ── Full home content ─────────────────────────────────────────────────────
  Widget _buildContent() {
    return Column(
      children: [
        const SizedBox(height: 30),

        // Logo section — float animation wraps only its own subtree
        AnimatedBuilder(
          animation: _floatAnim,
          builder: (_, child) =>
              Transform.translate(offset: Offset(0, _floatAnim.value), child: child),
          // child is const-equivalent — built once, translated cheaply
          child: Column(children: [
            const _TetrominoIcon(),
            const SizedBox(height: 20),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFF6C63FF), Color(0xFF00D4FF), Color(0xFF6BCB77)],
              ).createShader(bounds),
              child: Text('BRAIN',
                  style: GoogleFonts.orbitron(
                      fontSize: 52,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 6)),
            ),
            Text('BLOCKS',
                style: GoogleFonts.orbitron(
                    fontSize: 32,
                    fontWeight: FontWeight.w300,
                    color: Colors.white38,
                    letterSpacing: 12)),
          ]),
        ),

        const SizedBox(height: 12),
        Text(
          'Stack Blocks. Solve Puzzles. Train Your Brain.',
          textAlign: TextAlign.center,
          style: GoogleFonts.nunito(
              color: Colors.white38, fontSize: 13, letterSpacing: 0.5),
        ),
        const Spacer(),

        // High score (only when non-zero)
        if (_highScore > 0) ...[
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD93D).withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFFD93D).withOpacity(0.3)),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text('🏆', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('BEST SCORE',
                    style: GoogleFonts.orbitron(
                        color: const Color(0xFFFFD93D).withOpacity(0.7),
                        fontSize: 10,
                        letterSpacing: 2)),
                Text('$_highScore',
                    style: GoogleFonts.orbitron(
                        color: const Color(0xFFFFD93D),
                        fontSize: 28,
                        fontWeight: FontWeight.w700)),
              ]),
            ]),
          ),
          const SizedBox(height: 24),
        ] else
          const SizedBox(height: 24),

        // Feature chips — const widgets
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _FeatureChip(emoji: '🧩', label: 'Tetris Blocks'),
            SizedBox(width: 10),
            _FeatureChip(emoji: '🧠', label: 'Brain Puzzles'),
            SizedBox(width: 10),
            _FeatureChip(emoji: '🔥', label: 'Combos'),
          ],
        ),
        const SizedBox(height: 32),

        // Play button — glow animation only re-renders this container
        AnimatedBuilder(
          animation: _glowAnim,
          builder: (_, child) => GestureDetector(
            onTap: _startGame,
            child: Container(
              width: 200,
              height: 62,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(31),
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF4ECDC4)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color.fromARGB(
                        ((_glowAnim.value * 0.6) * 255).round(), 108, 99, 255),
                    blurRadius: 24,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: child, // label never changes → passed as child
            ),
          ),
          child: Center(
            child: Text('PLAY NOW',
                style: GoogleFonts.orbitron(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 3)),
          ),
        ),

        const SizedBox(height: 16),
        TextButton(
          onPressed: () => _showHowToPlay(context),
          child: Text('HOW TO PLAY',
              style: GoogleFonts.orbitron(
                  color: Colors.white30, fontSize: 11, letterSpacing: 2)),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  void _showHowToPlay(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF0E0E1A),
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('HOW TO PLAY',
                style: GoogleFonts.orbitron(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2)),
            const SizedBox(height: 16),
            ...[
              ('🧩', 'Stack falling Tetris blocks to fill rows'),
              ('💥', 'Clear rows to earn points and level up'),
              ('🧠', 'Every 5 blocks — face a Brain Challenge!'),
              ('✅', 'Solve the puzzle for BONUS points'),
              ('🔥', 'Chain clears for epic combo multipliers'),
              ('👆', 'Tap buttons or swipe to control blocks'),
            ].map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(children: [
                Text(e.$1, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 12),
                Expanded(
                    child: Text(e.$2,
                        style: GoogleFonts.nunito(
                            color: Colors.white70, fontSize: 14))),
              ]),
            )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ── Feature chip — const constructor ─────────────────────────────────────────
class _FeatureChip extends StatelessWidget {
  final String emoji;
  final String label;

  const _FeatureChip({required this.emoji, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(emoji, style: const TextStyle(fontSize: 13)),
        const SizedBox(width: 5),
        Text(label,
            style: GoogleFonts.nunito(
                color: Colors.white54,
                fontSize: 11,
                fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

// ── Tetromino icon — const, static paints, never repaints ────────────────────
class _TetrominoIcon extends StatelessWidget {
  const _TetrominoIcon();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 79, // 4 * 18 + 3 * 3 + 2
      height: 79,
      child: RepaintBoundary(
        child: CustomPaint(painter: _MiniGridPainter()),
      ),
    );
  }
}

class _MiniGridPainter extends CustomPainter {
  const _MiniGridPainter();

  static const List<List<Color?>> _grid = [
    [Color(0xFF6C63FF), Color(0xFF6C63FF), null, null],
    [null, Color(0xFF6C63FF), Color(0xFF00D4FF), null],
    [null, null, Color(0xFF00D4FF), Color(0xFFFFD93D)],
    [null, null, null, Color(0xFFFFD93D)],
  ];

  // Static cached paints — allocated once, ever
  static final Paint _colored   = Paint()..style = PaintingStyle.fill;
  static final Paint _empty     = Paint()
    ..color = const Color(0x0FFFFFFF)
    ..style = PaintingStyle.fill;
  static final Paint _border    = Paint()
    ..color = const Color(0x40FFFFFF)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;

  @override
  void paint(Canvas canvas, Size size) {
    const cell = 18.0;
    const gap  = 3.0;
    for (int r = 0; r < 4; r++) {
      for (int c = 0; c < 4; c++) {
        final color = _grid[r][c];
        final rect  = Rect.fromLTWH(c * (cell + gap), r * (cell + gap), cell, cell);
        final rRect = RRect.fromRectAndRadius(rect, const Radius.circular(4));
        if (color != null) {
          _colored.color = color.withOpacity(0.9);
          canvas.drawRRect(rRect, _colored);
          canvas.drawRRect(rRect, _border);
        } else {
          canvas.drawRRect(rRect, _empty);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_) => false; // static content, never repaints
}