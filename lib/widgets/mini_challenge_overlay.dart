import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../bloc/game_bloc.dart';
import '../models/block_model.dart';

class MiniChallengeOverlay extends StatefulWidget {
  final MiniChallenge challenge;
  const MiniChallengeOverlay({super.key, required this.challenge});
  @override
  State<MiniChallengeOverlay> createState() => _MiniChallengeOverlayState();
}

class _MiniChallengeOverlayState extends State<MiniChallengeOverlay>
    with SingleTickerProviderStateMixin {
  late int _timeLeft;
  Timer? _timer;
  int? _selectedIndex;
  bool _answered = false;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  static const Map<MiniChallengeType, ({String emoji, String label, Color color})> _typeMeta = {
    MiniChallengeType.math: (emoji: '🔢', label: 'MATH BLOCK', color: Color(0xFF00D4FF)),
    MiniChallengeType.word: (emoji: '📝', label: 'WORD BLOCK', color: Color(0xFF6BCB77)),
    MiniChallengeType.pattern: (emoji: '🔮', label: 'PATTERN BLOCK', color: Color(0xFFAA60FF)),
    MiniChallengeType.sequence: (emoji: '🔗', label: 'SEQUENCE BLOCK', color: Color(0xFFFF9A3D)),
  };

  @override
  void initState() {
    super.initState();
    _timeLeft = widget.challenge.timeSeconds;
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.06)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _timeLeft--);
      if (_timeLeft <= 0) { _timer?.cancel(); if (!_answered) _submitAnswer(-1); }
    });
  }

  void _submitAnswer(int index) {
    if (_answered) return;
    _timer?.cancel();
    setState(() { _selectedIndex = index; _answered = true; });
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) context.read<GameBloc>().add(ChallengeAnswered(index));
    });
  }

  @override
  void dispose() { _timer?.cancel(); _pulseCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final meta = _typeMeta[widget.challenge.type]!;
    final progress = _timeLeft / widget.challenge.timeSeconds;
    final isUrgent = _timeLeft <= 5;

    return Container(
      color: Colors.black.withOpacity(0.88),
      child: Center(
        child: AnimatedBuilder(
          animation: _pulseAnim,
          builder: (_, child) => Transform.scale(
              scale: isUrgent && !_answered ? _pulseAnim.value : 1.0, child: child),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: const Color(0xFF0E0E1A),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: meta.color.withOpacity(0.6), width: 1.5),
              boxShadow: [BoxShadow(color: meta.color.withOpacity(0.25), blurRadius: 30)],
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(color: meta.color.withOpacity(0.12),
                    borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24), topRight: Radius.circular(24))),
                child: Row(children: [
                  Text(meta.emoji, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 10),
                  Expanded(child: Text(meta.label, style: GoogleFonts.orbitron(
                      color: meta.color, fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 2))),
                  SizedBox(width: 44, height: 44, child: Stack(alignment: Alignment.center, children: [
                    SizedBox(width: 44, height: 44,
                        child: CircularProgressIndicator(value: progress.clamp(0.0, 1.0),
                            backgroundColor: Colors.white12,
                            valueColor: AlwaysStoppedAnimation(isUrgent ? const Color(0xFFFF6B6B) : meta.color),
                            strokeWidth: 3)),
                    Text('$_timeLeft', style: GoogleFonts.orbitron(
                        color: isUrgent ? const Color(0xFFFF6B6B) : meta.color,
                        fontSize: 13, fontWeight: FontWeight.w700)),
                  ])),
                ]),
              ),
              LinearProgressIndicator(value: progress.clamp(0.0, 1.0),
                  backgroundColor: Colors.white12,
                  valueColor: AlwaysStoppedAnimation(isUrgent ? const Color(0xFFFF6B6B) : meta.color),
                  minHeight: 3),
              // Question
              Padding(padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  child: Text(widget.challenge.question, textAlign: TextAlign.center,
                      style: GoogleFonts.nunito(color: Colors.white, fontSize: 18,
                          fontWeight: FontWeight.w700, height: 1.4))),
              // Options
              Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  child: GridView.count(shrinkWrap: true, crossAxisCount: 2,
                      mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 2.8,
                      physics: const NeverScrollableScrollPhysics(),
                      children: List.generate(widget.challenge.options.length, (i) {
                        final isSelected = _selectedIndex == i;
                        final isCorrect = i == widget.challenge.correctIndex;
                        Color btnColor = Colors.white.withOpacity(0.08);
                        Color borderColor = Colors.white24;
                        Color textColor = Colors.white70;
                        if (_answered) {
                          if (isCorrect) { btnColor = const Color(0xFF6BCB77).withOpacity(0.2);
                          borderColor = const Color(0xFF6BCB77); textColor = const Color(0xFF6BCB77); }
                          else if (isSelected) { btnColor = const Color(0xFFFF6B6B).withOpacity(0.2);
                          borderColor = const Color(0xFFFF6B6B); textColor = const Color(0xFFFF6B6B); }
                        }
                        return GestureDetector(
                          onTap: _answered ? null : () => _submitAnswer(i),
                          child: AnimatedContainer(duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(color: btnColor,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: borderColor, width: 1.5)),
                              child: Center(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                if (_answered && isCorrect) const Padding(padding: EdgeInsets.only(right: 6),
                                    child: Icon(Icons.check_circle, color: Color(0xFF6BCB77), size: 16)),
                                if (_answered && isSelected && !isCorrect) const Padding(
                                    padding: EdgeInsets.only(right: 6),
                                    child: Icon(Icons.cancel, color: Color(0xFFFF6B6B), size: 16)),
                                Flexible(child: Text(widget.challenge.options[i],
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.nunito(color: textColor, fontSize: 15,
                                        fontWeight: FontWeight.w700))),
                              ]))),
                        );
                      }))),
              Padding(padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                      _answered
                          ? (_selectedIndex == widget.challenge.correctIndex
                          ? '🎉 +${widget.challenge.bonusPoints} BONUS POINTS!'
                          : '😅 Better luck next time!')
                          : '⚡ Correct = +${widget.challenge.bonusPoints} bonus pts',
                      style: GoogleFonts.nunito(
                          color: _answered
                              ? (_selectedIndex == widget.challenge.correctIndex
                              ? const Color(0xFFFFD93D) : Colors.white38)
                              : Colors.white38,
                          fontSize: 13, fontWeight: FontWeight.w600))),
            ]),
          ),
        ),
      ),
    );
  }
}