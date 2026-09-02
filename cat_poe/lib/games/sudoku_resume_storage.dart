import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

const String _kSudokuPrefsKey = 'cat_poe_sudoku_save_v1';

/// Persisted Sudoku session for resume after leaving the screen.
class SudokuSavedGame {
  SudokuSavedGame({
    required this.schemaVersion,
    required this.solution,
    required this.board,
    required this.fixed,
    required this.notes,
    required this.mistakes,
    required this.score,
    required this.streak,
    required this.isGameOver,
    required this.isPencilMode,
    required this.secondsElapsed,
    required this.catoshiReward,
    required this.freeHintsAvailable,
    required this.difficulty,
    required this.selectedRow,
    required this.selectedCol,
    required this.completedRows,
    required this.completedCols,
    required this.completedBlocks,
    required this.rewardSubmitted,
    required this.normalPadHighlightDigit,
  });

  static const int currentSchema = 1;

  final int schemaVersion;
  final List<List<int>> solution;
  final List<List<int>> board;
  final List<List<bool>> fixed;
  final List<List<List<int>>> notes;
  final int mistakes;
  final int score;
  final int streak;
  final bool isGameOver;
  final bool isPencilMode;
  final int secondsElapsed;
  final int catoshiReward;
  final int freeHintsAvailable;
  final String difficulty;
  final int? selectedRow;
  final int? selectedCol;
  final List<int> completedRows;
  final List<int> completedCols;
  final List<int> completedBlocks;
  final bool rewardSubmitted;
  final int? normalPadHighlightDigit;

  Map<String, dynamic> toJson() => {
        'schema': schemaVersion,
        'solution': solution,
        'board': board,
        'fixed': fixed,
        'notes': notes,
        'mistakes': mistakes,
        'score': score,
        'streak': streak,
        'isGameOver': isGameOver,
        'isPencilMode': isPencilMode,
        'secondsElapsed': secondsElapsed,
        'catoshiReward': catoshiReward,
        'freeHintsAvailable': freeHintsAvailable,
        'difficulty': difficulty,
        'selectedRow': selectedRow,
        'selectedCol': selectedCol,
        'completedRows': completedRows,
        'completedCols': completedCols,
        'completedBlocks': completedBlocks,
        'rewardSubmitted': rewardSubmitted,
        'normalPadHighlightDigit': normalPadHighlightDigit,
      };

  static SudokuSavedGame? tryDecode(String raw) {
    try {
      final m = jsonDecode(raw);
      if (m is! Map<String, dynamic>) return null;
      final schema = m['schema'];
      if (schema is! int || schema != currentSchema) return null;

      List<List<int>> grid(String key) {
        final v = m[key];
        if (v is! List || v.length != 9) throw FormatException(key);
        return [
          for (final row in v)
            if (row is List && row.length == 9)
              [
                for (final x in row) (x as num).toInt(),
              ]
            else
              throw FormatException(key),
        ];
      }

      List<List<bool>> gridBool(String key) {
        final v = m[key];
        if (v is! List || v.length != 9) throw FormatException(key);
        return [
          for (final row in v)
            if (row is List && row.length == 9)
              [
                for (final x in row) x == true,
              ]
            else
              throw FormatException(key),
        ];
      }

      List<List<List<int>>> gridNotes() {
        final v = m['notes'];
        if (v is! List || v.length != 9) throw FormatException('notes');
        return [
          for (final row in v)
            if (row is List && row.length == 9)
              [
                for (final cell in row)
                  if (cell is List)
                    [
                      for (final x in cell) (x as num).toInt(),
                    ]
                  else
                    throw FormatException('notes'),
              ]
            else
              throw FormatException('notes'),
        ];
      }

      final completedRows = <int>[
        for (final x in (m['completedRows'] as List? ?? [])) (x as num).toInt(),
      ];
      final completedCols = <int>[
        for (final x in (m['completedCols'] as List? ?? [])) (x as num).toInt(),
      ];
      final completedBlocks = <int>[
        for (final x in (m['completedBlocks'] as List? ?? [])) (x as num).toInt(),
      ];

      final sr = m['selectedRow'];
      final sc = m['selectedCol'];
      final np = m['normalPadHighlightDigit'];

      return SudokuSavedGame(
        schemaVersion: schema,
        solution: grid('solution'),
        board: grid('board'),
        fixed: gridBool('fixed'),
        notes: gridNotes(),
        mistakes: (m['mistakes'] as num).toInt(),
        score: (m['score'] as num).toInt(),
        streak: (m['streak'] as num?)?.toInt() ?? 6,
        isGameOver: m['isGameOver'] == true,
        isPencilMode: m['isPencilMode'] == true,
        secondsElapsed: (m['secondsElapsed'] as num).toInt(),
        catoshiReward: (m['catoshiReward'] as num).toInt(),
        freeHintsAvailable: (m['freeHintsAvailable'] as num).toInt(),
        difficulty: m['difficulty'] as String? ?? 'Expert',
        selectedRow: sr == null ? null : (sr as num).toInt(),
        selectedCol: sc == null ? null : (sc as num).toInt(),
        completedRows: completedRows,
        completedCols: completedCols,
        completedBlocks: completedBlocks,
        rewardSubmitted: m['rewardSubmitted'] == true,
        normalPadHighlightDigit: np == null ? null : (np as num).toInt(),
      );
    } catch (_) {
      return null;
    }
  }

  bool validate() {
    bool gridOk(List<List<int>> g, {bool allowZero = false}) {
      if (g.length != 9) return false;
      for (final row in g) {
        if (row.length != 9) return false;
        for (final v in row) {
          if (v < (allowZero ? 0 : 1) || v > 9) return false;
        }
      }
      return true;
    }

    if (!gridOk(solution)) return false;
    if (!gridOk(board, allowZero: true)) return false;
    if (fixed.length != 9) return false;
    if (notes.length != 9) return false;
    for (var r = 0; r < 9; r++) {
      if (fixed[r].length != 9 || notes[r].length != 9) return false;
      for (var c = 0; c < 9; c++) {
        if (fixed[r][c]) {
          if (board[r][c] == 0 || board[r][c] != solution[r][c]) {
            return false;
          }
        }
        for (final n in notes[r][c]) {
          if (n < 1 || n > 9) return false;
        }
      }
    }
    if (mistakes < 0 || mistakes > 3) return false;
    if (secondsElapsed < 0 || secondsElapsed > 86400 * 7) return false;
    return true;
  }
}

class SudokuGameStorage {
  SudokuGameStorage._();

  static Future<void> save(SudokuSavedGame game) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kSudokuPrefsKey, jsonEncode(game.toJson()));
  }

  static Future<SudokuSavedGame?> load() async {
    final p = await SharedPreferences.getInstance();
    final s = p.getString(_kSudokuPrefsKey);
    if (s == null || s.isEmpty) return null;
    final g = SudokuSavedGame.tryDecode(s);
    if (g == null || !g.validate()) return null;
    return g;
  }

  static Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kSudokuPrefsKey);
  }
}
