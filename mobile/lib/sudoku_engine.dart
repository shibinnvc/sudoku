import 'dart:math';

enum Difficulty {
  easy(40, 'Easy'),
  medium(34, 'Medium'),
  hard(29, 'Hard');

  const Difficulty(this.clues, this.label);
  final int clues;
  final String label;
}

class Puzzle {
  const Puzzle(this.givens, this.solution);
  final List<int> givens;
  final List<int> solution;
}

class SudokuEngine {
  SudokuEngine({Random? random}) : _random = random ?? Random();
  final Random _random;

  Set<int> peers(int index) {
    final row = index ~/ 9;
    final column = index % 9;
    final result = <int>{};
    for (var n = 0; n < 9; n++) {
      result.add(row * 9 + n);
      result.add(n * 9 + column);
      result.add((row ~/ 3 * 3 + n ~/ 3) * 9 + column ~/ 3 * 3 + n % 3);
    }
    return result..remove(index);
  }

  List<int> candidates(List<int> board, int index) {
    if (board[index] != 0) return [];
    final used = peers(index).map((peer) => board[peer]).toSet();
    return [
      for (var value = 1; value <= 9; value++)
        if (!used.contains(value)) value,
    ];
  }

  Set<int> conflicts(List<int> board) {
    final result = <int>{};
    for (var index = 0; index < 81; index++) {
      if (board[index] == 0) continue;
      for (final peer in peers(index)) {
        if (board[peer] == board[index]) result.addAll([index, peer]);
      }
    }
    return result;
  }

  int countSolutions(List<int> board, {int limit = 2}) {
    final work = List<int>.of(board);
    var count = 0;
    void visit() {
      if (count >= limit) return;
      var target = -1;
      List<int>? options;
      for (var index = 0; index < 81; index++) {
        if (work[index] != 0) continue;
        final next = candidates(work, index);
        if (next.isEmpty) return;
        if (options == null || next.length < options.length) {
          target = index;
          options = next;
          if (next.length == 1) break;
        }
      }
      if (target == -1) {
        count++;
        return;
      }
      for (final value in options!) {
        work[target] = value;
        visit();
        work[target] = 0;
        if (count >= limit) return;
      }
    }

    visit();
    return count;
  }

  List<int> _solution() {
    final bands = [0, 1, 2]..shuffle(_random);
    final rows = bands
        .expand(
          (band) =>
              ([0, 1, 2]..shuffle(_random)).map((offset) => band * 3 + offset),
        )
        .toList();
    final stacks = [0, 1, 2]..shuffle(_random);
    final columns = stacks
        .expand(
          (stack) =>
              ([0, 1, 2]..shuffle(_random)).map((offset) => stack * 3 + offset),
        )
        .toList();
    final digits = [1, 2, 3, 4, 5, 6, 7, 8, 9]..shuffle(_random);
    return [
      for (final row in rows)
        for (final column in columns) digits[(row * 3 + row ~/ 3 + column) % 9],
    ];
  }

  Puzzle generate(Difficulty difficulty) {
    Puzzle? closest;
    for (var attempt = 0; attempt < 5; attempt++) {
      final solution = _solution();
      final givens = List<int>.of(solution);
      final positions = [for (var i = 0; i < 81; i++) i]..shuffle(_random);
      var clues = 81;
      for (final index in positions) {
        if (clues <= difficulty.clues) break;
        final old = givens[index];
        givens[index] = 0;
        if (countSolutions(givens) == 1) {
          clues--;
        } else {
          givens[index] = old;
        }
      }
      final puzzle = Puzzle(givens, solution);
      if (clues == difficulty.clues) return puzzle;
      if (closest == null ||
          clues < closest.givens.where((value) => value != 0).length) {
        closest = puzzle;
      }
    }
    return closest!;
  }
}
