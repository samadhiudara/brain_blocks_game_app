import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../bloc/game_bloc.dart';

class GameControls extends StatelessWidget {
  // Bloc passed directly — no context.read needed, works from any context
  final GameBloc bloc;

  const GameControls({super.key, required this.bloc});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ControlBtn(
          icon: Icons.rotate_right_rounded,
          label: 'ROTATE',
          color: const Color(0xFFAA60FF),
          onTap: () => bloc.add(BlockRotate()),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _ControlBtn(
              icon: Icons.arrow_back_ios_rounded,
              label: 'LEFT',
              color: const Color(0xFF4ECDC4),
              onTap: () => bloc.add(BlockMoveLeft()),
            ),
            const SizedBox(width: 12),
            _ControlBtn(
              icon: Icons.keyboard_double_arrow_down_rounded,
              label: 'DROP',
              color: const Color(0xFFFF6B6B),
              size: 64,
              onTap: () => bloc.add(BlockDrop()),
            ),
            const SizedBox(width: 12),
            _ControlBtn(
              icon: Icons.arrow_forward_ios_rounded,
              label: 'RIGHT',
              color: const Color(0xFF4ECDC4),
              onTap: () => bloc.add(BlockMoveRight()),
            ),
          ],
        ),
      ],
    );
  }
}

class _ControlBtn extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final double size;

  const _ControlBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.size = 56,
  });

  @override
  State<_ControlBtn> createState() => _ControlBtnState();
}

class _ControlBtnState extends State<_ControlBtn> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Use onTapDown + onTapUp for fastest response (no 300ms delay)
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 60),
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: _pressed
              ? widget.color.withOpacity(0.35)
              : widget.color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(widget.size / 2),
          border: Border.all(
            color: widget.color.withOpacity(_pressed ? 1.0 : 0.45),
            width: 1.5,
          ),
          boxShadow: _pressed
              ? [BoxShadow(color: widget.color.withOpacity(0.5), blurRadius: 14)]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(widget.icon, color: widget.color, size: widget.size * 0.38),
            const SizedBox(height: 2),
            Text(
              widget.label,
              style: GoogleFonts.orbitron(
                color: widget.color.withOpacity(0.85),
                fontSize: widget.size * 0.13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}