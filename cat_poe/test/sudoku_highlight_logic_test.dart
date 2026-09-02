import 'package:cat_poe/games/sudoku/sudoku_note_views.dart';
import 'package:flutter_test/flutter_test.dart';

List<List<int>> _board() => List.generate(9, (_) => List<int>.filled(9, 0));

void main() {
  group('sudokuMainNumberHighlightDigit', () {
    test('selected cell main value takes precedence over normal pad digit', () {
      final board = _board();
      board[2][3] = 7;
      expect(
        sudokuMainNumberHighlightDigit(
          normalModePadDigit: 4,
          selectedRow: 2,
          selectedCol: 3,
          board: board,
        ),
        7,
      );
    });

    test('uses normal pad digit when selected cell is empty', () {
      expect(
        sudokuMainNumberHighlightDigit(
          normalModePadDigit: 6,
          selectedRow: 0,
          selectedCol: 0,
          board: _board(),
        ),
        6,
      );
    });

    test('null when no pad digit and empty selected cell', () {
      expect(
        sudokuMainNumberHighlightDigit(
          normalModePadDigit: null,
          selectedRow: 0,
          selectedCol: 0,
          board: _board(),
        ),
        isNull,
      );
    });

    test('changing normal pad digit updates highlight when cell empty', () {
      final board = _board();
      expect(
        sudokuMainNumberHighlightDigit(
          normalModePadDigit: 3,
          selectedRow: 4,
          selectedCol: 4,
          board: board,
        ),
        3,
      );
      expect(
        sudokuMainNumberHighlightDigit(
          normalModePadDigit: 8,
          selectedRow: 4,
          selectedCol: 4,
          board: board,
        ),
        8,
      );
    });

    /// Pencil-mode taps must not update [normalModePadDigit] in the screen;
    /// this helper only reflects what the UI passes in.
    test('pencil "no pad update" simulated by unchanged null pad digit', () {
      final board = _board();
      board[0][0] = 9;
      expect(
        sudokuMainNumberHighlightDigit(
          normalModePadDigit: null,
          selectedRow: 0,
          selectedCol: 0,
          board: board,
        ),
        9,
      );
    });
  });

  group('sudokuPencilNoteHighlighted', () {
    test('matches highlight digit only', () {
      expect(sudokuPencilNoteHighlighted(2, 2), isTrue);
      expect(sudokuPencilNoteHighlighted(5, 2), isFalse);
      expect(sudokuPencilNoteHighlighted(2, null), isFalse);
    });
  });
}
