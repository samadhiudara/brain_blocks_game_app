import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:confetti/confetti.dart';
import 'package:google_fonts/google_fonts.dart';
import '../bloc/game_bloc.dart';
import '../models/block_model.dart';
import '../widgets/board_painter.dart';
import '../widgets/game_controls.dart';
import '../widgets/mini_challenge_overlay.dart';
import '../widgets/stats_panel.dart';

// ─────────────────────────────────────────────────────────────────────────────
// GameScreen
// The BlocProvider is created here. GameStarted is fired ONLY inside
// addPostFrameCallback so the navigation transition finishes before any
// heavy work begins.
// ─────────────────────────────────────────────────────────────────────────────
class GameScreen extends StatefulWidget {
  final int highScore;
  const GameScreen({super.key, required this.highScore});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final ConfettiController _confettiCtrl;
  late final GameBloc _bloc;
  bool _gameReady = false;   // ← shows loading until first frame drawn
  Offset? _swipeStart;
  static const double _swipeThreshold = 20;

  static const _bg = DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF07071A), Color(0xFF0D0D2B)],
      ),
    ),
  );

  @override
  void initState() {
    super.initState();
    _confettiCtrl = ConfettiController(duration: const Duration(seconds: 2));
    // Create bloc here — cheap, no heavy work yet
    _bloc = GameBloc(widget.highScore);

    // Fire GameStarted AFTER the navigation transition paints its first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _bloc.add(GameStarted());
      setState(() => _gameReady = true);
    });
  }

  @override
  void dispose() {
    _confettiCtrl.dispose();
    _bloc.close();
    super.dispose();
  }

  void _handleSwipe(Offset delta) {
    if (delta.dx.abs() > delta.dy.abs()) {
      if (delta.dx < -_swipeThreshold) _bloc.add(BlockMoveLeft());
      if (delta.dx >  _swipeThreshold) _bloc.add(BlockMoveRight());
    } else {
      if (delta.dy > _swipeThreshold) _bloc.add(GameTicked());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      // Use .value because we own the lifecycle (closed in dispose)
      value: _bloc,
      child: Scaffold(
        backgroundColor: const Color(0xFF07071A),
        body: Stack(
          fit: StackFit.expand,
          children: [
            const Positioned.fill(child: _bg),

            // ── Show a simple loading screen until first frame ──────────────
            if (!_gameReady)
              const _LoadingScreen()
            else ...[
              SafeArea(
                child: _GameBody(
                  swipeThreshold: _swipeThreshold,
                  onSwipe: _handleSwipe,
                  bloc: _bloc,
                  onTap: () {
                    if (_bloc.state.status == GameStatus.playing) {
                      _bloc.add(BlockRotate());
                    }
                  },
                ),
              ),

              // Overlays — only rebuild when status changes
              BlocBuilder<GameBloc, BBGameState>(
                buildWhen: (p, c) => p.status != c.status,
                builder: (context, state) {
                  return switch (state.status) {
                    GameStatus.miniChallenge when state.currentChallenge != null =>
                        MiniChallengeOverlay(challenge: state.currentChallenge!),
                    GameStatus.paused   => const _PauseOverlay(),
                    GameStatus.gameOver => _GameOverOverlay(
                        score: state.score,
                        highScore: state.highScore,
                        confetti: _confettiCtrl),
                    _ => const SizedBox.shrink(),
                  };
                },
              ),

              // Confetti
              Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confettiCtrl,
                  blastDirectionality: BlastDirectionality.explosive,
                  numberOfParticles: 20,
                  colors: const [
                    Color(0xFF6C63FF), Color(0xFF00D4FF),
                    Color(0xFFFFD93D), Color(0xFF6BCB77), Color(0xFFFF6B6B),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Simple loading screen shown during navigation transition ────────────────
class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              color: Color(0xFF6C63FF),
              strokeWidth: 3,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'LOADING...',
            style: TextStyle(
              color: Color(0xFF6C63FF),
              fontSize: 12,
              letterSpacing: 3,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _GameBody — board + stats + controls
// Must be StatefulWidget because _swipeStartPos is mutable state
// ─────────────────────────────────────────────────────────────────────────────
class _GameBody extends StatefulWidget {
  final double swipeThreshold;
  final void Function(Offset delta) onSwipe;
  final VoidCallback onTap;
  final GameBloc bloc;

  const _GameBody({
    required this.swipeThreshold,
    required this.onSwipe,
    required this.onTap,
    required this.bloc,
  });

  @override
  State<_GameBody> createState() => _GameBodyState();
}

class _GameBodyState extends State<_GameBody> {
  Offset? _swipeStartPos; // mutable — lives in State, not Widget

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final W      = constraints.maxWidth;
      final boardW = W * 0.54;
      final cs     = boardW / 10;
      final boardH = cs * 20;
      final sideW  = (W - boardW) / 2;

      return Column(
        children: [
          // Top bar — only rebuild when level changes
          BlocBuilder<GameBloc, BBGameState>(
            buildWhen: (p, c) => p.level != c.level,
            builder: (_, s) => _TopBar(level: s.level),
          ),
          const SizedBox(height: 6),

          // Main row
          Expanded(
            child: GestureDetector(
              onPanStart:  (d) => _swipeStartPos = d.globalPosition,
              onPanUpdate: (d) {
                if (_swipeStartPos == null) return;
                final delta = d.globalPosition - _swipeStartPos!;
                if (delta.distance > widget.swipeThreshold) {
                  widget.onSwipe(delta);
                  _swipeStartPos = d.globalPosition;
                }
              },
              onTap: widget.onTap,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats (left)
                  SizedBox(
                    width: sideW,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: BlocBuilder<GameBloc, BBGameState>(
                        buildWhen: (p, c) =>
                        p.score        != c.score        ||
                            p.highScore    != c.highScore    ||
                            p.level        != c.level        ||
                            p.linesCleared != c.linesCleared ||
                            p.combo        != c.combo        ||
                            p.nextBlock    != c.nextBlock,
                        builder: (context, s) => StatsPanel(
                          score: s.score,
                          highScore: s.highScore,
                          level: s.level,
                          linesCleared: s.linesCleared,
                          combo: s.combo,
                          nextBlock: s.nextBlock,
                          onPause: () => widget.bloc.add(GamePaused()),
                        ),
                      ),
                    ),
                  ),

                  // Board — isolated in RepaintBoundary
                  RepaintBoundary(
                    child: BlocBuilder<GameBloc, BBGameState>(
                      buildWhen: (p, c) =>
                      !identical(p.board, c.board) ||
                          p.activeBlock != c.activeBlock ||
                          p.flashRows   != c.flashRows,
                      builder: (_, s) => Container(
                        width: boardW,
                        height: boardH,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: const Color(0xFF6C63FF).withOpacity(0.35),
                            width: 1.5,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x266C63FF),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: CustomPaint(
                            painter: BoardPainter.withGhost(
                              board: s.board,
                              activeBlock: s.activeBlock,
                              cellSize: cs,
                              flashRows: s.flashRows,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(width: sideW),
                ],
              ),
            ),
          ),

          // Controls
          BlocBuilder<GameBloc, BBGameState>(
            buildWhen: (p, c) => p.status != c.status,
            builder: (_, s) =>
            (s.status == GameStatus.playing ||
                s.status == GameStatus.paused)
                ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: GameControls(bloc: widget.bloc),
            )
                : const SizedBox(height: 6),
          ),
          const SizedBox(height: 6),
        ],
      );
    });
  }

}

// ─── Top bar ─────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final int level;
  const _TopBar({super.key, required this.level});

  // Cached styles
  static final _titleStyle = GoogleFonts.orbitron(
      color: Colors.white, fontSize: 16,
      fontWeight: FontWeight.w700, letterSpacing: 3);
  static final _lvlStyle = GoogleFonts.orbitron(
      color: const Color(0xFF6C63FF), fontSize: 11,
      fontWeight: FontWeight.w700, letterSpacing: 1);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(children: [
        // Back button
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white54, size: 16),
          ),
        ),
        const SizedBox(width: 12),
        ShaderMask(
          shaderCallback: (b) => const LinearGradient(
              colors: [Color(0xFF6C63FF), Color(0xFF00D4FF)]).createShader(b),
          child: Text('BRAINBLOCKS', style: _titleStyle),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFF6C63FF).withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.4)),
          ),
          child: Text('LVL $level', style: _lvlStyle),
        ),
      ]),
    );
  }
}

// ─── Pause overlay ────────────────────────────────────────────────────────────
class _PauseOverlay extends StatelessWidget {
  const _PauseOverlay();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.80),
      child: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('⏸', style: TextStyle(fontSize: 60)),
          const SizedBox(height: 16),
          Text('PAUSED',
              style: GoogleFonts.orbitron(
                  color: Colors.white, fontSize: 32,
                  fontWeight: FontWeight.w900, letterSpacing: 4)),
          const SizedBox(height: 32),
          _OBtn('RESUME',  const Color(0xFF6C63FF),
                  () => context.read<GameBloc>().add(GameResumed())),
          const SizedBox(height: 14),
          _OBtn('RESTART', Colors.white24,
                  () => context.read<GameBloc>().add(GameRestarted())),
          const SizedBox(height: 14),
          _OBtn('HOME', Colors.white12, () => Navigator.of(context).pop()),
        ]),
      ),
    );
  }
}

// ─── Game over overlay ────────────────────────────────────────────────────────
class _GameOverOverlay extends StatefulWidget {
  final int score;
  final int highScore;
  final ConfettiController confetti;

  const _GameOverOverlay({
    required this.score,
    required this.highScore,
    required this.confetti,
  });

  @override
  State<_GameOverOverlay> createState() => _GameOverOverlayState();
}

class _GameOverOverlayState extends State<_GameOverOverlay> {
  @override
  void initState() {
    super.initState();
    // Play confetti after this overlay's first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.confetti.play();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isRecord = widget.score >= widget.highScore && widget.score > 0;
    return Container(
      color: Colors.black.withOpacity(0.88),
      child: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(isRecord ? '🏆' : '💀',
              style: const TextStyle(fontSize: 70)),
          const SizedBox(height: 14),
          Text(
            isRecord ? 'NEW RECORD!' : 'GAME OVER',
            style: GoogleFonts.orbitron(
                color: isRecord
                    ? const Color(0xFFFFD93D)
                    : const Color(0xFFFF6B6B),
                fontSize: 32,
                fontWeight: FontWeight.w900,
                letterSpacing: 3),
          ),
          const SizedBox(height: 20),
          _ScoreRow('SCORE', widget.score,     const Color(0xFF00D4FF)),
          const SizedBox(height: 8),
          _ScoreRow('BEST',  widget.highScore, const Color(0xFFFFD93D)),
          const SizedBox(height: 36),
          _OBtn('PLAY AGAIN', const Color(0xFF6C63FF),
                  () => context.read<GameBloc>().add(GameRestarted())),
          const SizedBox(height: 14),
          _OBtn('HOME', Colors.white12, () => Navigator.of(context).pop()),
        ]),
      ),
    );
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────
Widget _ScoreRow(String label, int value, Color color) =>
    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text('$label: ',
          style: GoogleFonts.orbitron(
              color: Colors.white54, fontSize: 13, letterSpacing: 2)),
      Text('$value',
          style: GoogleFonts.orbitron(
              color: color, fontSize: 26, fontWeight: FontWeight.w700)),
    ]);

Widget _OBtn(String label, Color color, VoidCallback onTap) => Padding(
  padding: const EdgeInsets.symmetric(horizontal: 60),
  child: GestureDetector(
    onTap: onTap,
    child: Container(
      height: 52,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.35), blurRadius: 12)
        ],
      ),
      child: Center(
        child: Text(label,
            style: GoogleFonts.orbitron(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 2)),
      ),
    ),
  ),
);