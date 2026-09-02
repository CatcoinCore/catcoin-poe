import 'package:flutter/material.dart';

/// Digit for “matching number” highlights from **main-number context only**.
///
/// - Selected cell’s **committed** value (if non-zero) defines the highlight.
/// - Otherwise the last digit tapped on the pad in **normal** (non-pencil) mode.
///
/// Pencil-mode pad taps must not pass [normalModePadDigit]; they do not affect this.
int? sudokuMainNumberHighlightDigit({
  int? normalModePadDigit,
  int? selectedRow,
  int? selectedCol,
  required List<List<int>> board,
}) {
  if (selectedRow != null && selectedCol != null) {
    final v = board[selectedRow][selectedCol];
    if (v != 0) return v;
  }
  return normalModePadDigit;
}

bool sudokuPencilNoteHighlighted(int noteDigit, int? highlightDigit) =>
    highlightDigit != null && noteDigit == highlightDigit;

class SudokuPencilNotesGrid extends StatelessWidget {
  const SudokuPencilNotesGrid({
    super.key,
    required this.cellNotes,
    required this.accentColor,
    this.highlightDigit,
  });

  final Set<int> cellNotes;
  final Color accentColor;
  final int? highlightDigit;

  static const Color _baseNoteColor = Colors.white;
  static const double _noteFontSize = 11;

  @override
  Widget build(BuildContext context) {
    if (cellNotes.isEmpty) return const SizedBox();
    return GridView.builder(
      padding: const EdgeInsets.all(2),
      gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
      itemCount: 9,
      itemBuilder: (ctx, i) {
        final n = i + 1;
        final hasNote = cellNotes.contains(n);
        final emphasized =
            hasNote && sudokuPencilNoteHighlighted(n, highlightDigit);
        return Center(
          child: Text(
            hasNote ? n.toString() : '',
            style: TextStyle(
              color: emphasized
                  ? accentColor
                  : _baseNoteColor.withValues(alpha: 0.85),
              fontSize: _noteFontSize,
              fontWeight: emphasized ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        );
      },
    );
  }
}
