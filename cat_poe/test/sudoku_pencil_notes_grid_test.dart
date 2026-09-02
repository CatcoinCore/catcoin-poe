import 'package:cat_poe/games/sudoku/sudoku_note_views.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const accent = Colors.orange;

  Text textFor(String digit, WidgetTester tester) =>
      tester.widget<Text>(find.text(digit));

  testWidgets('matching pencil note uses accent for main-number highlight',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 90,
            height: 90,
            child: SudokuPencilNotesGrid(
              cellNotes: {1, 9},
              accentColor: accent,
              highlightDigit: 1,
            ),
          ),
        ),
      ),
    );

    expect(textFor('1', tester).style?.color, accent);
    expect(textFor('9', tester).style?.color, isNot(accent));
  });

  testWidgets('no highlight digit: no accent on notes', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 90,
            height: 90,
            child: SudokuPencilNotesGrid(
              cellNotes: {3, 4},
              accentColor: accent,
              highlightDigit: null,
            ),
          ),
        ),
      ),
    );

    expect(textFor('3', tester).style?.color, isNot(accent));
    expect(textFor('4', tester).style?.color, isNot(accent));
  });
}
