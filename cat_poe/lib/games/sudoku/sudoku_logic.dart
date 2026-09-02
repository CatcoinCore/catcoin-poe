import 'dart:math';

class SudokuLogic {
  static const int size = 9;
  static const int boxSize = 3;

  /// Generates a complete, valid Sudoku board using backtracking.
  static List<List<int>> generateFullBoard() {
    List<List<int>> board = List.generate(size, (_) => List.filled(size, 0));
    _fillBoard(board);
    return board;
  }

  static bool _fillBoard(List<List<int>> board) {
    for (int row = 0; row < size; row++) {
      for (int col = 0; col < size; col++) {
        if (board[row][col] == 0) {
          List<int> numbers = List.generate(size, (i) => i + 1)..shuffle();
          for (int n in numbers) {
            if (_isValid(board, row, col, n)) {
              board[row][col] = n;
              if (_fillBoard(board)) return true;
              board[row][col] = 0;
            }
          }
          return false;
        }
      }
    }
    return true;
  }

  static bool _isValid(List<List<int>> board, int row, int col, int n) {
    // Check row
    for (int i = 0; i < size; i++) {
      if (board[row][i] == n) return false;
    }
    // Check col
    for (int i = 0; i < size; i++) {
      if (board[i][col] == n) return false;
    }
    // Check box
    int startRow = (row ~/ boxSize) * boxSize;
    int startCol = (col ~/ boxSize) * boxSize;
    for (int i = 0; i < boxSize; i++) {
      for (int j = 0; j < boxSize; j++) {
        if (board[startRow + i][startCol + j] == n) return false;
      }
    }
    return true;
  }

  /// Creates a puzzle by removing numbers from a full board.
  /// [emptyCells] controls the difficulty.
  static List<List<int>> createPuzzle(
      List<List<int>> fullBoard, int emptyCells) {
    List<List<int>> puzzle =
        List.generate(size, (r) => List.from(fullBoard[r]));
    Random random = Random();
    int removed = 0;
    while (removed < emptyCells) {
      int r = random.nextInt(size);
      int c = random.nextInt(size);
      if (puzzle[r][c] != 0) {
        puzzle[r][c] = 0;
        removed++;
      }
    }
    return puzzle;
  }

  /// Checks if a value is correct at a specific position.
  static bool isCorrect(List<List<int>> solution, int row, int col, int value) {
    return solution[row][col] == value;
  }

  /// Digits 1–9 allowed as pencil marks at [row],[col] using only committed
  /// values in the same row, column, and 3×3 box. Empty cells are [0].
  /// Pencil marks in other cells are not considered.
  static Set<int> allowedPencilDigits(List<List<int>> board, int row, int col) {
    final used = <int>{};
    for (int c = 0; c < size; c++) {
      final v = board[row][c];
      if (v != 0) used.add(v);
    }
    for (int r = 0; r < size; r++) {
      final v = board[r][col];
      if (v != 0) used.add(v);
    }
    final br = (row ~/ boxSize) * boxSize;
    final bc = (col ~/ boxSize) * boxSize;
    for (int r = 0; r < boxSize; r++) {
      for (int c = 0; c < boxSize; c++) {
        final v = board[br + r][bc + c];
        if (v != 0) used.add(v);
      }
    }
    return {for (var d = 1; d <= size; d++) d}.difference(used);
  }

  /// Locally valid candidates for [row],[col] (same rules as [allowedPencilDigits]).
  static Set<int> localCandidatesForCell(
      List<List<int>> board, int row, int col) {
    return allowedPencilDigits(board, row, col);
  }

  /// Removes [value] from pencil [notes] in every peer of ([row],[col]) except the cell itself.
  static void removePencilDigitFromPeers(
    List<List<Set<int>>> notes,
    int row,
    int col,
    int value,
  ) {
    for (int c = 0; c < size; c++) {
      if (c != col) notes[row][c].remove(value);
    }
    for (int r = 0; r < size; r++) {
      if (r != row) notes[r][col].remove(value);
    }
    final br = (row ~/ boxSize) * boxSize;
    final bc = (col ~/ boxSize) * boxSize;
    for (int r = 0; r < boxSize; r++) {
      for (int c = 0; c < boxSize; c++) {
        final rr = br + r;
        final cc = bc + c;
        if (rr == row && cc == col) continue;
        notes[rr][cc].remove(value);
      }
    }
  }
}
