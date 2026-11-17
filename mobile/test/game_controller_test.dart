import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sudoku_studio/game_controller.dart';
import 'package:sudoku_studio/sudoku_engine.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  test(
    'move history and saved progress survive a controller restart',
    () async {
      final game = GameController(engine: SudokuEngine(random: Random(7)));
      game.newGame(Difficulty.easy);
      final index = game.givens.indexOf(0);
      final answer = game.solution[index];
      game.select(index);
      game.place(answer);
      expect(game.values[index], answer);
      game.undo();
      expect(game.values[index], 0);
      game.redo();
      expect(game.values[index], answer);
      await game.saveNow();

      final restored = GameController(engine: SudokuEngine(random: Random(8)));
      await restored.load();
      expect(restored.values[index], answer);
      expect(restored.givens, game.givens);
      game.dispose();
      restored.dispose();
    },
  );

  test('hint fills a square with the correct answer', () {
    final game = GameController(engine: SudokuEngine(random: Random(9)));
    final index = game.givens.indexOf(0);
    game.select(index);
    game.hint();
    expect(game.values[index], game.solution[index]);
    expect(game.hints, contains(index));
    game.dispose();
  });

  test('replaced games appear in persistent history', () async {
    final game = GameController(engine: SudokuEngine(random: Random(11)));
    game.newGame(Difficulty.medium);
    game.newGame(Difficulty.hard);
    expect(game.history, hasLength(1));
    expect(game.history.first.difficulty, Difficulty.medium);
    expect(game.history.first.completed, isFalse);
    await game.saveNow();

    final restored = GameController(engine: SudokuEngine(random: Random(12)));
    await restored.load();
    expect(restored.history, hasLength(1));
    expect(restored.history.first.difficulty, Difficulty.medium);
    expect(restored.hasUnfinishedGame, isTrue);
    game.dispose();
    restored.dispose();
  });

  test('completed games are recorded and no longer resumable', () async {
    final game = GameController(engine: SudokuEngine(random: Random(13)));
    game.newGame(Difficulty.easy);
    for (var index = 0; index < 81; index++) {
      if (game.givens[index] != 0) continue;
      game.select(index);
      game.place(game.solution[index]);
    }
    expect(game.won, isTrue);
    expect(game.hasUnfinishedGame, isFalse);
    expect(game.history.first.completed, isTrue);
    expect(game.history.first.filled, 81);
    await game.saveNow();
    game.dispose();
  });
}
