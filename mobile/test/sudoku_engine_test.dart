import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku_studio/sudoku_engine.dart';

void main() {
  final engine = SudokuEngine(random: Random(42));

  for (final level in Difficulty.values) {
    test('${level.label} puzzle has a unique valid solution', () {
      final puzzle = engine.generate(level);
      expect(puzzle.givens, hasLength(81));
      expect(puzzle.solution, hasLength(81));
      expect(engine.countSolutions(puzzle.givens), 1);
      expect(engine.conflicts(puzzle.solution), isEmpty);
      expect(
        puzzle.givens.where((value) => value != 0).length,
        inInclusiveRange(level.clues, level.clues + 6),
      );
      for (var index = 0; index < 81; index++) {
        if (puzzle.givens[index] != 0) {
          expect(puzzle.givens[index], puzzle.solution[index]);
        }
      }
    });
  }

  test('candidates respect row, column, and box', () {
    final board = List<int>.filled(81, 0);
    board[1] = 1;
    board[9] = 2;
    board[10] = 3;
    expect(engine.candidates(board, 0), [4, 5, 6, 7, 8, 9]);
  });
}
