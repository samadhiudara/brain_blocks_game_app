import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/block_model.dart';
import 'board_painter.dart';

class StatsPanel extends StatelessWidget {
  final int score;
  final int highScore;
  final int level;
  final int linesCleared;
  final int combo;
  final ActiveBlock? nextBlock;
  final VoidCallback onPause;

  const StatsPanel({
    super.key,
    required this.score,
    required this.highScore,
    required this.level,
    required this.linesCleared,
    required this.combo,
    required this.nextBlock,
    required this.onPause,
  });

  @override
  Widget build(BuildContext context) {
    // ── Use LayoutBuilder so every child scales to actual available width ──────
    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;

      // Scale font sizes and paddings based on available width
      final labelFs = (w * 0.09).clamp(7.0, 10.0);
      final valueFs = (w * 0.16).clamp(12.0, 20.0);
      final hPad    = (w * 0.08).clamp(4.0, 12.0);
      final vPad    = (w * 0.06).clamp(4.0, 10.0);

      final labelStyle = GoogleFonts.orbitron(fontSize: labelFs, letterSpacing: 0.5);
      final valueStyle = GoogleFonts.orbitron(fontSize: valueFs, fontWeight: FontWeight.w700);
      final pauseStyle = GoogleFonts.orbitron(color: Colors.white60, fontSize: labelFs, letterSpacing: 0.5);
      final nextStyle  = GoogleFonts.orbitron(color: Colors.white38, fontSize: labelFs, letterSpacing: 1);
      final comboLbl   = GoogleFonts.orbitron(color: const Color(0xFFFFD93D), fontSize: labelFs, letterSpacing: 0.5);
      final comboVal   = GoogleFonts.orbitron(color: const Color(0xFFFF6B6B), fontSize: valueFs * 1.1, fontWeight: FontWeight.w900);

      // Next-block preview size scales too
      final previewSize = (w * 0.85).clamp(40.0, 70.0);
      final cellSize    = previewSize / 5;

      return Column(
        children: [
          // ── Pause button — uses FittedBox to prevent overflow ─────────────
          GestureDetector(
            onTap: onPause,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad * 0.8),
              decoration: BoxDecoration(
                color: const Color(0x12FFFFFF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.pause_rounded, color: Colors.white60, size: labelFs + 4),
                  SizedBox(width: w * 0.04),
                  Flexible(
                    child: Text('PAUSE',
                        style: pauseStyle,
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: vPad),

          // ── Stat cards ────────────────────────────────────────────────────
          _StatCard(label: 'SCORE', value: '$score',        color: const Color(0xFFFFD93D), icon: '⭐', hPad: hPad, vPad: vPad, labelStyle: labelStyle, valueStyle: valueStyle),
          SizedBox(height: vPad * 0.6),
          _StatCard(label: 'BEST',  value: '$highScore',    color: const Color(0xFFFF9A3D), icon: '🏆', hPad: hPad, vPad: vPad, labelStyle: labelStyle, valueStyle: valueStyle),
          SizedBox(height: vPad * 0.6),
          _StatCard(label: 'LEVEL', value: '$level',        color: const Color(0xFF6C63FF), icon: '🎯', hPad: hPad, vPad: vPad, labelStyle: labelStyle, valueStyle: valueStyle),
          SizedBox(height: vPad * 0.6),
          _StatCard(label: 'LINES', value: '$linesCleared', color: const Color(0xFF4ECDC4), icon: '📊', hPad: hPad, vPad: vPad, labelStyle: labelStyle, valueStyle: valueStyle),

          // ── Combo ─────────────────────────────────────────────────────────
          if (combo > 1) ...[
            SizedBox(height: vPad * 0.6),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad * 0.6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0x33FF6B6B), Color(0x33FFD93D)]),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0x80FF6B6B)),
              ),
              child: Column(children: [
                Text('🔥 COMBO', style: comboLbl),
                Text('×$combo',  style: comboVal),
              ]),
            ),
          ],
          SizedBox(height: vPad),

          // ── Next block preview ────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(vPad * 0.8),
            decoration: BoxDecoration(
              color: const Color(0x0DFFFFFF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(children: [
              Text('NEXT', style: nextStyle),
              SizedBox(height: vPad * 0.5),
              SizedBox(
                width: previewSize,
                height: previewSize * 0.8,
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: NextBlockPainter(
                      block: nextBlock,
                      cellSize: cellSize,
                    ),
                  ),
                ),
              ),
            ]),
          ),
        ],
      );
    });
  }
}

// ─── Stat card ────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final String icon;
  final double hPad;
  final double vPad;
  final TextStyle labelStyle;
  final TextStyle valueStyle;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    required this.hPad,
    required this.vPad,
    required this.labelStyle,
    required this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad * 0.7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(icon, style: TextStyle(fontSize: labelStyle.fontSize)),
          SizedBox(width: hPad * 0.4),
          Flexible(
            child: Text(label,
                style: labelStyle.copyWith(color: color.withOpacity(0.7)),
                overflow: TextOverflow.ellipsis),
          ),
        ]),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(value, style: valueStyle.copyWith(color: color)),
        ),
      ]),
    );
  }
}