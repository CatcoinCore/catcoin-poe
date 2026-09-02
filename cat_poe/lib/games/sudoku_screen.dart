import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cat_poe/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../providers/game_provider.dart';
import '../../providers/mining_provider.dart';
import '../../utils/game_screen_capture_guard.dart';
import '../../utils/game_reward_feedback.dart';
import '../../utils/game_session_gate.dart';
import '../../services/ad_service.dart';
import '../../services/game_sfx_service.dart';
import 'sudoku/sudoku_logic.dart';
import 'sudoku/sudoku_note_views.dart';
import 'sudoku_resume_storage.dart';

class SudokuScreen extends StatefulWidget {
  const SudokuScreen({super.key});

  @override
  State<SudokuScreen> createState() => _SudokuScreenState();
}

class _SudokuScreenState extends State<SudokuScreen> with GameScreenCaptureGuard {
  // Game State (filled after resume check or new game)
  List<List<int>> solution =
      List.generate(9, (_) => List.filled(9, 0));
  List<List<int>> board =
      List.generate(9, (_) => List.filled(9, 0));
  List<List<bool>> fixed =
      List.generate(9, (_) => List.filled(9, false));
  List<List<Set<int>>> notes = List.generate(
      9, (r) => List.generate(9, (c) => <int>{}));

  int? selectedRow;
  int? selectedCol;

  /// Last digit tapped on the pad in **normal** mode only (not pencil).
  int? _normalPadHighlightDigit;
  int mistakes = 0;
  int score = 0;
  int streak = 6; // Mock streak for UI
  bool isGameOver = false;
  bool isSubmitting = false;
  bool _winCompletionBusy = false;
  bool isPencilMode = false;
  bool _rewardSubmitted = false;
  bool _resumeReady = false;

  Timer? _timer;
  int _secondsElapsed = 0;
  int _catoshiReward = 100;
  int _freeHintsAvailable = 1;
  String difficulty = "Expert"; // Default for mockup

  // Error State for timed red display
  int? _errorRow;
  int? _errorCol;
  int? _errorValue;
  Timer? _errorTimer;

  // Animation State
  final List<List<int>> _cellAnimationKeys =
      List.generate(9, (_) => List.generate(9, (_) => 0));
  final Set<int> _completedRows = {};
  final Set<int> _completedCols = {};
  final Set<int> _completedBlocks = {};

  // History for Undo
  final List<List<List<int>>> _boardHistory = [];
  final List<List<List<Set<int>>>> _notesHistory = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!await ensureGamePlayAllowed(context, gameType: 'SUDOKU')) return;
      if (!mounted) return;
      await _startSession();
      if (!mounted) return;
      AdService().loadInterstitialAd(context);
      final restored = await SudokuGameStorage.load();
      if (!mounted) return;
      if (restored != null && restored.validate()) {
        setState(() {
          _applySudokuRestore(restored);
          _resumeReady = true;
        });
        _startTimer();
        if (_shouldResumeSudokuWinFlow()) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) unawaited(_completeSudokuWin());
          });
        }
      } else {
        if (restored != null) await SudokuGameStorage.clear();
        _startNewGame();
        _startTimer();
        if (mounted) {
          setState(() {
            _resumeReady = true;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    unawaited(_persistSudoku());
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!isGameOver) {
        setState(() {
          _secondsElapsed++;
        });
        if (_secondsElapsed % 30 == 0) {
          unawaited(_persistSudoku());
        }
      }
    });
  }

  SudokuSavedGame _captureSudokuSavedGame() {
    return SudokuSavedGame(
      schemaVersion: SudokuSavedGame.currentSchema,
      solution: List.generate(9, (r) => List.from(solution[r])),
      board: List.generate(9, (r) => List.from(board[r])),
      fixed: List.generate(9, (r) => List.from(fixed[r])),
      notes: List.generate(
        9,
        (r) => List.generate(
          9,
          (c) => (notes[r][c].toList()..sort()),
        ),
      ),
      mistakes: mistakes,
      score: score,
      streak: streak,
      isGameOver: isGameOver,
      isPencilMode: isPencilMode,
      secondsElapsed: _secondsElapsed,
      catoshiReward: _catoshiReward,
      freeHintsAvailable: _freeHintsAvailable,
      difficulty: difficulty,
      selectedRow: selectedRow,
      selectedCol: selectedCol,
      completedRows: _completedRows.toList()..sort(),
      completedCols: _completedCols.toList()..sort(),
      completedBlocks: _completedBlocks.toList()..sort(),
      rewardSubmitted: _rewardSubmitted,
      normalPadHighlightDigit: _normalPadHighlightDigit,
    );
  }

  Future<void> _persistSudoku() async {
    try {
      await SudokuGameStorage.save(_captureSudokuSavedGame());
    } catch (_) {}
  }

  void _schedulePersistSudoku() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_persistSudoku());
    });
  }

  void _applySudokuRestore(SudokuSavedGame g) {
    solution = List.generate(9, (r) => List.from(g.solution[r]));
    board = List.generate(9, (r) => List.from(g.board[r]));
    fixed = List.generate(9, (r) => List.from(g.fixed[r]));
    notes = List.generate(
      9,
      (r) => List.generate(
        9,
        (c) => Set<int>.from(g.notes[r][c]),
      ),
    );
    mistakes = g.mistakes;
    score = g.score;
    streak = g.streak;
    isGameOver = g.isGameOver;
    isPencilMode = g.isPencilMode;
    _secondsElapsed = g.secondsElapsed;
    _catoshiReward = g.catoshiReward;
    _freeHintsAvailable = g.freeHintsAvailable;
    difficulty = g.difficulty;
    selectedRow = g.selectedRow;
    selectedCol = g.selectedCol;
    _normalPadHighlightDigit = g.normalPadHighlightDigit;
    _completedRows
      ..clear()
      ..addAll(g.completedRows);
    _completedCols
      ..clear()
      ..addAll(g.completedCols);
    _completedBlocks
      ..clear()
      ..addAll(g.completedBlocks);
    _rewardSubmitted = g.rewardSubmitted;
    _boardHistory.clear();
    _notesHistory.clear();
    _errorRow = null;
    _errorCol = null;
    _errorValue = null;
    _errorTimer?.cancel();
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        _cellAnimationKeys[r][c] = 0;
      }
    }
  }

  bool _shouldResumeSudokuWinFlow() {
    return isGameOver &&
        _isBoardFull() &&
        !_rewardSubmitted &&
        mistakes < 3;
  }

  Future<void> _confirmExitSudoku() async {
    await _persistSudoku();
    if (!mounted) return;
    final l = AppLocalizations.of(context);
    final leave = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(l.gameSudokuExitTitle),
        content: Text(l.gameSudokuExitBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.gameTwenty48Stay),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.gameTwenty48Leave),
          ),
        ],
      ),
    );
    if (leave == true && mounted) {
      Navigator.of(context).pop();
    }
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _startNewGame() {
    solution = SudokuLogic.generateFullBoard();
    int emptyCells = 45; // Expert level
    board = SudokuLogic.createPuzzle(solution, emptyCells);
    fixed = List.generate(9, (r) => List.generate(9, (c) => board[r][c] != 0));
    notes = List.generate(9, (r) => List.generate(9, (c) => <int>{}));
    mistakes = 0;
    score = 0;
    _secondsElapsed = 0;
    _catoshiReward = 100;
    _freeHintsAvailable = 1;
    _rewardSubmitted = false;
    isGameOver = false;
    selectedRow = null;
    selectedCol = null;
    _normalPadHighlightDigit = null;
    _errorRow = null;
    _errorCol = null;
    _errorValue = null;
    _errorTimer?.cancel();
    _boardHistory.clear();
    _notesHistory.clear();
    _completedRows.clear();
    _completedCols.clear();
    _completedBlocks.clear();
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        _cellAnimationKeys[r][c] = 0;
      }
    }
    setState(() {});
    _schedulePersistSudoku();
  }

  Future<void> _startSession() async {
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    await gameProvider.startSession();
  }

  void _saveHistory() {
    _boardHistory.add(List.generate(9, (r) => List.from(board[r])));
    _notesHistory.add(List.generate(
        9, (r) => List.generate(9, (c) => Set.from(notes[r][c]))));
    if (_boardHistory.length > 20) {
      _boardHistory.removeAt(0);
      _notesHistory.removeAt(0);
    }
  }

  void _undo() {
    if (_boardHistory.isEmpty || isGameOver) return;
    setState(() {
      board = _boardHistory.removeLast();
      notes = _notesHistory.removeLast();
    });
    _schedulePersistSudoku();
  }

  void _onCellTap(int r, int c) {
    if (isGameOver) return;
    GameSfxService.instance.play(GameSfx.softTap, volume: 0.38);
    setState(() {
      selectedRow = r;
      selectedCol = c;
    });
    _schedulePersistSudoku();
  }

  void _onNumberTap(int n) {
    if (isGameOver) return;
    if (!isPencilMode) {
      setState(() {
        _normalPadHighlightDigit = n;
      });
    }
    if (selectedRow == null || selectedCol == null) return;
    if (fixed[selectedRow!][selectedCol!]) return;

    if (isPencilMode) {
      final allowed = SudokuLogic.localCandidatesForCell(
        board,
        selectedRow!,
        selectedCol!,
      );
      if (!allowed.contains(n)) {
        return;
      }
      _saveHistory();
      setState(() {
        if (notes[selectedRow!][selectedCol!].contains(n)) {
          notes[selectedRow!][selectedCol!].remove(n);
        } else {
          notes[selectedRow!][selectedCol!].add(n);
        }
      });
      GameSfxService.instance.play(GameSfx.softTap, volume: 0.45);
      _schedulePersistSudoku();
      return;
    }

    if (board[selectedRow!][selectedCol!] == n) return; // Already there

    _saveHistory();
    setState(() {
      if (solution[selectedRow!][selectedCol!] == n) {
        board[selectedRow!][selectedCol!] = n;
        notes[selectedRow!][selectedCol!]
            .clear(); // Clear notes on correct entry
        SudokuLogic.removePencilDigitFromPeers(
          notes,
          selectedRow!,
          selectedCol!,
          n,
        );
        score += 100;

        // Check for row/column/block completion animations
        _checkCompletions(selectedRow!, selectedCol!);

        GameSfxService.instance.play(GameSfx.tap, volume: 0.55);
        GameSfxService.instance.play(GameSfx.coin, volume: 0.32);

        if (_isBoardFull()) {
          isGameOver = true;
          _triggerCenterAnimation();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) unawaited(_completeSudokuWin());
          });
        }
      } else {
        HapticFeedback.mediumImpact();
        GameSfxService.instance.play(GameSfx.bump, volume: 0.48);
        mistakes++;

        // Set error state for timed red display
        _errorRow = selectedRow;
        _errorCol = selectedCol;
        _errorValue = n;
        _errorTimer?.cancel();
        _errorTimer = Timer(const Duration(milliseconds: 1500), () {
          if (mounted) {
            setState(() {
              if (_errorRow == selectedRow && _errorCol == selectedCol) {
                _errorValue = null;
              }
            });
          }
        });

        if (mistakes >= 3) {
          isGameOver = true;
          _showGameOver();
        } else {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text("Incorrect number!"),
                duration: Duration(milliseconds: 500)),
          );
        }
      }
    });
    _schedulePersistSudoku();
  }

  void _checkCompletions(int r, int c) {
    // Row completion
    bool rowComplete = true;
    for (int i = 0; i < 9; i++) {
      if (board[r][i] == 0) rowComplete = false;
    }
    if (rowComplete && !_completedRows.contains(r)) {
      _completedRows.add(r);
      _triggerGroupAnimation(List.generate(9, (i) => [r, i]), r, c);
    }

    // Col completion
    bool colComplete = true;
    for (int i = 0; i < 9; i++) {
      if (board[i][c] == 0) colComplete = false;
    }
    if (colComplete && !_completedCols.contains(c)) {
      _completedCols.add(c);
      _triggerGroupAnimation(List.generate(9, (i) => [i, c]), r, c);
    }

    // Block completion
    bool blockComplete = true;
    int br = (r ~/ 3) * 3;
    int bc = (c ~/ 3) * 3;
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        if (board[br + i][bc + j] == 0) blockComplete = false;
      }
    }
    int blockIdx = (r ~/ 3) * 3 + (c ~/ 3);
    if (blockComplete && !_completedBlocks.contains(blockIdx)) {
      _completedBlocks.add(blockIdx);
      List<List<int>> cells = [];
      for (int i = 0; i < 3; i++) {
        for (int j = 0; j < 3; j++) {
          cells.add([br + i, bc + j]);
        }
      }
      _triggerGroupAnimation(cells, r, c);
    }
  }

  void _triggerGroupAnimation(List<List<int>> cells, int startR, int startC) {
    for (var cell in cells) {
      int r = cell[0];
      int c = cell[1];
      // Staggered delay based on Manhattan distance from the source cell
      int distance = (r - startR).abs() + (c - startC).abs();
      Future.delayed(Duration(milliseconds: distance * 50), () {
        if (mounted) {
          setState(() {
            _cellAnimationKeys[r][c]++;
          });
        }
      });
    }
  }

  void _triggerCenterAnimation() {
    // Start ripple from center (r=4, c=4)
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        int distance = (r - 4).abs() + (c - 4).abs();
        Future.delayed(Duration(milliseconds: distance * 100), () {
          if (mounted) {
            setState(() {
              _cellAnimationKeys[r][c]++;
            });
          }
        });
      }
    }
  }

  void _fastPencilFill() {
    if (isGameOver) return;
    if (selectedRow == null || selectedCol == null) return;
    final r = selectedRow!;
    final c = selectedCol!;
    if (fixed[r][c]) return;
    if (board[r][c] != 0) return;

    _saveHistory();
    setState(() {
      final candidates = SudokuLogic.localCandidatesForCell(board, r, c);
      notes[r][c]
        ..clear()
        ..addAll(candidates);
    });
    _schedulePersistSudoku();
  }

  void _erase() {
    if (selectedRow == null || selectedCol == null || isGameOver) return;
    if (fixed[selectedRow!][selectedCol!]) return;

    _saveHistory();
    setState(() {
      board[selectedRow!][selectedCol!] = 0;
      notes[selectedRow!][selectedCol!].clear();
    });
    _schedulePersistSudoku();
  }

  void _hint() {
    if (selectedRow == null || selectedCol == null || isGameOver) return;
    if (board[selectedRow!][selectedCol!] != 0) return;

    if (_freeHintsAvailable > 0) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("Use FREE Hint?",
              style: TextStyle(color: Colors.white)),
          content: const Text(
            "You have one free hint per game. Use it to reveal the correct number for this cell?",
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child:
                  const Text("Cancel", style: TextStyle(color: Colors.white60)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _executeHint(isFree: true);
              },
              child: const Text("Use Free Hint",
                  style: TextStyle(
                      color: Colors.orange, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Use Hint?", style: TextStyle(color: Colors.white)),
        content: const Text(
          "Using a hint will reveal the correct number for the selected cell, but it will reduce your final reward by 10 Catoshi.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                const Text("Cancel", style: TextStyle(color: Colors.white60)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _executeHint(isFree: false);
            },
            child:
                const Text("Use Hint", style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
  }

  void _executeHint({bool isFree = false}) {
    if (selectedRow == null || selectedCol == null || isGameOver) return;

    _saveHistory();
    setState(() {
      final r = selectedRow!;
      final c = selectedCol!;
      final v = solution[r][c];
      board[r][c] = v;
      notes[r][c].clear();
      SudokuLogic.removePencilDigitFromPeers(notes, r, c, v);
      if (isFree) {
        _freeHintsAvailable--;
      } else {
        _catoshiReward = (_catoshiReward - 10).clamp(0, 100);
        score -= 50; // Keep the score penalty as well
      }
      _checkCompletions(selectedRow!, selectedCol!);
    });
    GameSfxService.instance.play(GameSfx.coin, volume: 0.42);
    _schedulePersistSudoku();
  }

  bool _isBoardFull() {
    for (var r in board) {
      if (r.contains(0)) return false;
    }
    return true;
  }

  void _showGameOver() {
    GameSfxService.instance.play(GameSfx.lose, volume: 0.5);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Game Over",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text("You've reached the limit of 3 mistakes.",
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _startNewGame();
            },
            child: const Text("Try Again",
                style: TextStyle(
                    color: Colors.orange, fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close", style: TextStyle(color: Colors.white60)),
          ),
        ],
      ),
    );
  }

  void _showWinDialog() {
    final boost =
        Provider.of<GameProvider>(context, listen: false).lastGameBoostAward;
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Column(
          children: [
            Icon(Icons.emoji_events, color: Colors.amber, size: 48),
            SizedBox(height: 10),
            Text("Puzzle Solved!",
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Congratulations! You've successfully completed the Sudoku puzzle.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
              ),
              const SizedBox(height: 20),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.stars, color: Colors.amber, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      "+$_catoshiReward Catoshi",
                      style: const TextStyle(
                          color: Colors.amber,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              if (boost != null)
                ...gameBoostBonusSection(dialogContext, l10n, boost),
            ],
          ),
        ),
        actions: [
          Center(
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    _startNewGame();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Text("Play New Game",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text("Back to Games",
                      style: TextStyle(color: Colors.white60)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _completeSudokuWin() async {
    if (_winCompletionBusy) return;
    GameSfxService.instance.play(GameSfx.win, volume: 0.72);
    _winCompletionBusy = true;
    try {
      await AdService().showRewardGateAd(context, gameType: 'SUDOKU');
      if (!mounted) return;
      await _submitResult();
    } finally {
      _winCompletionBusy = false;
    }
  }

  Future<void> _submitResult() async {
    setState(() {
      isSubmitting = true;
    });

    final gameProvider = Provider.of<GameProvider>(context, listen: false);

    final success = await gameProvider.submitScore(
      score: score,
      coinsCollected: _catoshiReward,
      gameType: "SUDOKU",
    );

    if (success && mounted) {
      Provider.of<MiningProvider>(context, listen: false).fetchStats();
      setState(() {
        _rewardSubmitted = true;
      });
      _schedulePersistSudoku();
      _showWinDialog();
    }

    if (mounted) {
      setState(() {
        isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    const backgroundColor = Color(0xFF0F1113);
    const accentColor = Colors.orange;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        unawaited(_confirmExitSudoku());
      },
      child: Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: !_resumeReady
            ? const Center(
                child: CircularProgressIndicator(color: accentColor),
              )
            : Column(
          children: [
            _buildHeader(l, accentColor),
            _buildStatusRow(l, accentColor),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    _buildBoard(accentColor),
                    const SizedBox(height: 20),
                    _buildControlBar(l, accentColor),
                    const SizedBox(height: 20),
                    _buildNumberPad(accentColor),
                    const SizedBox(height: 30),
                    if (isGameOver)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            ElevatedButton.icon(
                              onPressed: _startNewGame,
                              icon: const Icon(Icons.replay),
                              label: Text(l.gamePlayAgain),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 40, vertical: 15),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30)),
                                minimumSize: const Size(double.infinity, 50),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: () => unawaited(_confirmExitSudoku()),
                              child: Text(l.commonClose,
                                  style: const TextStyle(
                                      color: Colors.white60, fontSize: 16)),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildHeader(AppLocalizations l, Color accentColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => unawaited(_confirmExitSudoku()),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(AppLocalizations l, Color accentColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            l.gameSudokuMistakes(mistakes.toString()),
            style: const TextStyle(color: Colors.white60, fontSize: 14),
          ),
          Row(
            children: [
              Text(
                _formatTime(_secondsElapsed),
                style: const TextStyle(color: Colors.white60, fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBoard(Color accentColor) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white24, width: 2),
          borderRadius: BorderRadius.circular(4),
        ),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 81,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 9),
          itemBuilder: (context, index) {
            int r = index ~/ 9;
            int c = index % 9;
            bool isSelected = selectedRow == r && selectedCol == c;
            bool isFixed = fixed[r][c];
            int value = board[r][c];

            // Highlight same group/number
            bool inSelectionGroup = false;
            if (selectedRow != null && selectedCol != null) {
              if (r == selectedRow || c == selectedCol) {
                inSelectionGroup = true;
              }
              if ((r ~/ 3 == selectedRow! ~/ 3) &&
                  (c ~/ 3 == selectedCol! ~/ 3)) {
                inSelectionGroup = true;
              }
            }
            final digitHighlight = sudokuMainNumberHighlightDigit(
              normalModePadDigit: _normalPadHighlightDigit,
              selectedRow: selectedRow,
              selectedCol: selectedCol,
              board: board,
            );
            final isSameNumber =
                value != 0 && digitHighlight != null && value == digitHighlight;

            // Check if this cell is currently showing an error
            bool isErrorCell =
                _errorRow == r && _errorCol == c && _errorValue != null;
            int displayValue = isErrorCell ? _errorValue! : value;

            return GestureDetector(
              onTap: () => _onCellTap(r, c),
              child: TweenAnimationBuilder<double>(
                  key: ValueKey("cell_${r}_${c}_${_cellAnimationKeys[r][c]}"),
                  duration: const Duration(milliseconds: 400),
                  tween: Tween<double>(
                      begin: _cellAnimationKeys[r][c] > 0 ? 1.2 : 1.0,
                      end: 1.0),
                  builder: (context, scale, child) {
                    return Transform.scale(
                      scale: scale,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        decoration: BoxDecoration(
                          border: Border(
                            right: BorderSide(
                                color: (c + 1) % 3 == 0
                                    ? Colors.white38
                                    : Colors.white12,
                                width: (c + 1) % 3 == 0 ? 2 : 1),
                            bottom: BorderSide(
                                color: (r + 1) % 3 == 0
                                    ? Colors.white38
                                    : Colors.white12,
                                width: (r + 1) % 3 == 0 ? 2 : 1),
                          ),
                          color: isSelected
                              ? accentColor.withValues(alpha: 0.4)
                              : isSameNumber
                                  ? accentColor.withValues(alpha: 0.2)
                                  : inSelectionGroup
                                      ? Colors.white.withValues(alpha: 0.05)
                                      : Colors.transparent,
                        ),
                        child: Center(
                          child: displayValue != 0
                              ? Text(
                                  displayValue.toString(),
                                  style: TextStyle(
                                    color: isErrorCell
                                        ? Colors.red
                                        : (isFixed
                                            ? Colors.white
                                            : accentColor),
                                    fontSize: 22,
                                    fontWeight: (isFixed || isErrorCell)
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                )
                              : SudokuPencilNotesGrid(
                                  cellNotes: notes[r][c],
                                  accentColor: accentColor,
                                  highlightDigit: digitHighlight,
                                ),
                        ),
                      ),
                    );
                  }),
            );
          },
        ),
      ),
    );
  }

  Widget _buildControlBar(AppLocalizations l, Color accentColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildControlButton(Icons.undo_outlined, l.gameSudokuUndo, _undo),
          _buildControlButton(
              Icons.backspace_outlined, l.gameSudokuErase, _erase),
          _buildControlButton(
            Icons.edit_note,
            l.gameSudokuFastPencil,
            _fastPencilFill,
          ),
          _buildControlButton(
            Icons.edit_outlined,
            l.gameSudokuPencil,
            () {
              setState(() => isPencilMode = !isPencilMode);
              _schedulePersistSudoku();
            },
            isActive: isPencilMode,
            showInactiveOffBadge: true,
          ),
          _buildControlButton(
            Icons.lightbulb_outline,
            l.gameSudokuHint,
            _hint,
            badge: _freeHintsAvailable > 0 ? "1" : null,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton(
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool isActive = false,
    String? badge,
    bool showInactiveOffBadge = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Stack(
            alignment: Alignment.topRight,
            children: [
              Icon(icon,
                  color: isActive ? Colors.orange : Colors.white70, size: 28),
              if (isActive)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(4)),
                  child: const Text("ON",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold)),
                ),
              if (!isActive && showInactiveOffBadge)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(4)),
                  child: const Text("OFF",
                      style: TextStyle(
                          color: Colors.white60,
                          fontSize: 8,
                          fontWeight: FontWeight.bold)),
                ),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                      color: Colors.orange, shape: BoxShape.circle),
                  child: Text(badge,
                      style: const TextStyle(
                          color: Colors.black,
                          fontSize: 8,
                          fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 11)),
        ],
      ),
    );
  }

  int _getRemainingCount(int n) {
    int count = 0;
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (board[r][c] == n) count++;
      }
    }
    return 9 - count;
  }

  /// When pencil mode is on, digits allowed for the selected empty cell (peer
  /// occupancy only). Empty set means the keypad is all disabled for pencil.
  Set<int> _pencilAllowedForSelectedCell() {
    if (selectedRow == null || selectedCol == null) return {};
    if (fixed[selectedRow!][selectedCol!]) return {};
    return SudokuLogic.localCandidatesForCell(
        board, selectedRow!, selectedCol!);
  }

  Widget _buildNumberPad(Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: List.generate(9, (index) {
          final n = index + 1;
          final bool pencilMode = isPencilMode;
          late final bool enabled;
          late final int? remainingLabel;

          if (pencilMode) {
            final allowed = _pencilAllowedForSelectedCell();
            enabled = allowed.contains(n);
            remainingLabel = null;
          } else {
            final remaining = _getRemainingCount(n);
            if (remaining <= 0) return const SizedBox.shrink();
            enabled = true;
            remainingLabel = remaining;
          }

          final Color digitColor =
              enabled ? accentColor : accentColor.withValues(alpha: 0.25);

          return GestureDetector(
            onTap: enabled ? () => _onNumberTap(n) : null,
            child: Opacity(
              opacity: enabled ? 1.0 : 0.45,
              child: Container(
                width: (MediaQuery.of(context).size.width - 64) / 5,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        n.toString(),
                        style: TextStyle(
                          color: digitColor,
                          fontSize: 24,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      if (remainingLabel != null)
                        Text(
                          remainingLabel.toString(),
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 10),
                        )
                      else
                        const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
