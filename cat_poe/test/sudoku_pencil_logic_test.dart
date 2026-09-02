import 'package:cat_poe/games/sudoku/sudoku_logic.dart';
import 'package:flutter_test/flutter_test.dart';

List<List<int>> _emptyBoard() =>
    List.generate(9, (_) => List<int>.filled(9, 0));

void main() {
  group('SudokuLogic.allowedPencilDigits', () {
    test('blocks digit present in same row', () {
      final board = _emptyBoard();
      board[3][1] = 5;
      final allowed = SudokuLogic.allowedPencilDigits(board, 3, 4);
      expect(allowed.contains(5), isFalse);
    });

    test('blocks digit present in same column', () {
      final board = _emptyBoard();
      board[1][4] = 5;
      final allowed = SudokuLogic.allowedPencilDigits(board, 6, 4);
      expect(allowed.contains(5), isFalse);
    });

    test('blocks digit present in same 3x3 box', () {
      final board = _emptyBoard();
      board[1][1] = 5;
      final allowed = SudokuLogic.allowedPencilDigits(board, 2, 2);
      expect(allowed.contains(5), isFalse);
    });

    test('allows digit not in row, column, or box', () {
      final board = _emptyBoard();
      board[0][0] = 1;
      board[0][1] = 2;
      board[0][2] = 3;
      board[1][0] = 4;
      board[1][1] = 5;
      board[1][2] = 6;
      board[2][0] = 7;
      board[2][1] = 8;
      // Top-left box uses 1–8; (2,2) is empty. Row 2 missing 9, col 2 missing 9.
      final allowed = SudokuLogic.allowedPencilDigits(board, 2, 2);
      expect(allowed.contains(9), isTrue);
    });

    test('does not use solution — empty board allows any digit 1–9', () {
      final board = _emptyBoard();
      final solution = SudokuLogic.generateFullBoard();
      final allowed = SudokuLogic.allowedPencilDigits(board, 4, 4);
      final wrong =
          <int>{1, 2, 3, 4, 5, 6, 7, 8, 9}.difference({solution[4][4]}).first;
      expect(allowed.contains(wrong), isTrue);
      expect(allowed.length, 9);
    });

    test('ignores hypothetical pencil marks — only committed board values', () {
      final board = _emptyBoard();
      board[0][0] = 5;
      final allowed = SudokuLogic.allowedPencilDigits(board, 0, 1);
      expect(allowed.contains(5), isFalse);
      // No other digits in peers of (0,1); pencil marks would not be on [board].
      expect(allowed.contains(1), isTrue);
    });

    test('localCandidatesForCell matches allowedPencilDigits', () {
      final board = _emptyBoard();
      board[4][4] = 2;
      expect(
        SudokuLogic.localCandidatesForCell(board, 4, 5),
        SudokuLogic.allowedPencilDigits(board, 4, 5),
      );
    });
  });

  group('SudokuLogic.removePencilDigitFromPeers', () {
    test('removes only that digit from row, column, and box peers', () {
      final notes = List.generate(
        9,
        (_) => List.generate(9, (_) => <int>{1, 2, 3, 4, 5}),
      );
      SudokuLogic.removePencilDigitFromPeers(notes, 4, 4, 5);
      expect(notes[4][4].contains(5), isTrue);
      expect(notes[4][0].contains(5), isFalse);
      expect(notes[0][4].contains(5), isFalse);
      expect(notes[3][3].contains(5), isFalse);
      expect(notes[0][0].contains(5), isTrue);
      expect(notes[0][0].contains(1), isTrue);
    });
  });

  group('Fast Pencil fill set', () {
    test('equals localCandidatesForCell for empty cell', () {
      final board = _emptyBoard();
      board[0][0] = 1;
      board[0][1] = 2;
      board[1][0] = 3;
      final fill = SudokuLogic.localCandidatesForCell(board, 0, 2);
      expect(fill.length, 6);
      expect(fill.contains(1), isFalse);
      expect(fill.contains(2), isFalse);
      expect(fill.contains(3), isFalse);
    });
  });
}
