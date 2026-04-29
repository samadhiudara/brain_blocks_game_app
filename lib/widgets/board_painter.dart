import 'package:flutter/material.dart';
import '../models/block_model.dart';

// Cached Paint objects – never allocate inside paint()
class _PC {
  static final Paint grid = Paint()
    ..color = const Color(0x0AFFFFFF)
    ..strokeWidth = 0.5
    ..style = PaintingStyle.stroke;
  static final Paint ghostFill   = Paint()..style = PaintingStyle.fill;
  static final Paint ghostBorder = Paint()..style = PaintingStyle.stroke..strokeWidth = 1;
  static final Paint cellFill    = Paint()..style = PaintingStyle.fill;
  static final Paint cellHL      = Paint()..color = const Color(0x59FFFFFF)..style = PaintingStyle.fill;
  static final Paint cellBorder  = Paint()..style = PaintingStyle.stroke..strokeWidth = 0.8;
}

class BoardPainter extends CustomPainter {
  final List<List<Color?>> board;
  final ActiveBlock? activeBlock;
  final List<int> flashRows;
  final double cellSize;
  final List<List<int>>? ghostCells;
  final Color? ghostColor;

  const BoardPainter({
    required this.board,
    required this.activeBlock,
    required this.cellSize,
    this.flashRows = const [],
    this.ghostCells,
    this.ghostColor,
  });

  // Call this factory from the widget – ghost computed once, not inside paint()
  factory BoardPainter.withGhost({
    required List<List<Color?>> board,
    required ActiveBlock? activeBlock,
    required double cellSize,
    List<int> flashRows = const [],
  }) {
    List<List<int>>? gc;
    Color? gcol;
    if (activeBlock != null) {
      var ghost = activeBlock;
      while (_canMove(board, ghost.copyWith(row: ghost.row + 1))) {
        ghost = ghost.copyWith(row: ghost.row + 1);
      }
      if (ghost.row != activeBlock.row) {
        gc = ghost.absoluteCells;
        gcol = activeBlock.color;
      }
    }
    return BoardPainter(
      board: board, activeBlock: activeBlock, cellSize: cellSize,
      flashRows: flashRows, ghostCells: gc, ghostColor: gcol,
    );
  }

  static bool _canMove(List<List<Color?>> board, ActiveBlock b) {
    final rows = board.length, cols = board[0].length;
    for (final cell in b.absoluteCells) {
      final r = cell[0], c = cell[1];
      if (r < 0 || r >= rows || c < 0 || c >= cols) return false;
      if (board[r][c] != null) return false;
    }
    return true;
  }

  // Gradient colour cache keyed by Color int value
  static final Map<int, List<Color>> _gc = {};
  List<Color> _grad(Color c, bool flash) {
    if (flash) return const [Colors.white, Color(0xB3FFFFFF)];
    return _gc.putIfAbsent(c.value, () => [c.withOpacity(0.95), c.withOpacity(0.70)]);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rows = board.length;
    final cols = board[0].length;
    final cs = cellSize;

    // 1 ── Grid lines
    for (int r = 0; r <= rows; r++)
      canvas.drawLine(Offset(0, r * cs), Offset(cols * cs, r * cs), _PC.grid);
    for (int c = 0; c <= cols; c++)
      canvas.drawLine(Offset(c * cs, 0), Offset(c * cs, rows * cs), _PC.grid);

    // 2 ── Ghost
    if (ghostCells != null && ghostColor != null) {
      _PC.ghostFill.color   = ghostColor!.withOpacity(0.15);
      _PC.ghostBorder.color = ghostColor!.withOpacity(0.40);
      for (final cell in ghostCells!) _drawGhost(canvas, cell[0], cell[1], cs);
    }

    // 3 ── Locked cells
    final flashSet = flashRows.isNotEmpty ? flashRows.toSet() : const <int>{};
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final color = board[r][c];
        if (color != null) {
          final flash = flashSet.contains(r);
          _drawCell(canvas, r, c, flash ? Colors.white : color, cs, flash: flash);
        }
      }
    }

    // 4 ── Active block
    if (activeBlock != null)
      for (final cell in activeBlock!.absoluteCells)
        _drawCell(canvas, cell[0], cell[1], activeBlock!.color, cs);
  }

  void _drawCell(Canvas canvas, int row, int col, Color color, double cs, {bool flash = false}) {
    final l = col * cs, t = row * cs;
    final rect  = Rect.fromLTWH(l + 1, t + 1, cs - 2, cs - 2);
    final rRect = RRect.fromRectAndRadius(rect, const Radius.circular(3));
    _PC.cellFill.shader = LinearGradient(
      begin: Alignment.topLeft, end: Alignment.bottomRight, colors: _grad(color, flash),
    ).createShader(rect);
    canvas.drawRRect(rRect, _PC.cellFill);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(l + 1, t + 1, cs * 0.45, cs * 0.20), const Radius.circular(2)),
      _PC.cellHL,
    );
    _PC.cellBorder.color = color.withOpacity(0.5);
    canvas.drawRRect(rRect, _PC.cellBorder);
  }

  void _drawGhost(Canvas canvas, int row, int col, double cs) {
    final l = col * cs, t = row * cs;
    final rect  = Rect.fromLTWH(l + 1, t + 1, cs - 2, cs - 2);
    final rRect = RRect.fromRectAndRadius(rect, const Radius.circular(3));
    canvas.drawRRect(rRect, _PC.ghostFill);
    canvas.drawRRect(rRect, _PC.ghostBorder);
  }

  @override
  bool shouldRepaint(BoardPainter old) =>
      !identical(old.board, board) ||
          old.activeBlock != activeBlock ||
          old.flashRows != flashRows;
}

// ─── Next-block preview ──────────────────────────────────────────────────────
class NextBlockPainter extends CustomPainter {
  final ActiveBlock? block;
  final double cellSize;
  const NextBlockPainter({this.block, required this.cellSize});

  static final Paint _fill = Paint()..style = PaintingStyle.fill;
  static final Paint _hl   = Paint()..color = const Color(0x4DFFFFFF)..style = PaintingStyle.fill;

  @override
  void paint(Canvas canvas, Size size) {
    if (block == null) return;
    final cells = block!.cells;
    final maxR = cells.map((c) => c[0]).reduce((a, b) => a > b ? a : b) + 1;
    final maxC = cells.map((c) => c[1]).reduce((a, b) => a > b ? a : b) + 1;
    final ox = (size.width  - maxC * cellSize) / 2;
    final oy = (size.height - maxR * cellSize) / 2;
    final color = block!.color;

    for (final cell in cells) {
      final l = ox + cell[1] * cellSize, t = oy + cell[0] * cellSize;
      final rect  = Rect.fromLTWH(l + 1, t + 1, cellSize - 2, cellSize - 2);
      final rRect = RRect.fromRectAndRadius(rect, const Radius.circular(3));
      _fill.shader = LinearGradient(
        begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: [color, color.withOpacity(0.7)],
      ).createShader(rect);
      canvas.drawRRect(rRect, _fill);
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(l + 1, t + 1, cellSize * 0.4, cellSize * 0.18), const Radius.circular(2)),
        _hl,
      );
    }
  }

  @override
  bool shouldRepaint(NextBlockPainter old) => old.block != block;
}