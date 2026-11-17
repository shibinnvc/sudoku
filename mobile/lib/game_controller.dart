import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'sudoku_engine.dart';

class GameRecord {
  const GameRecord({
    required this.difficulty,
    required this.seconds,
    required this.filled,
    required this.completed,
    required this.endedAt,
  });

  final Difficulty difficulty;
  final int seconds;
  final int filled;
  final bool completed;
  final DateTime endedAt;

  Map<String, Object> toJson() => {
    'difficulty': difficulty.name,
    'seconds': seconds,
    'filled': filled,
    'completed': completed,
    'endedAt': endedAt.toIso8601String(),
  };

  factory GameRecord.fromJson(Map<String, dynamic> data) => GameRecord(
    difficulty: Difficulty.values.firstWhere(
      (item) => item.name == data['difficulty'],
    ),
    seconds: (data['seconds'] as int).clamp(0, 999999),
    filled: (data['filled'] as int).clamp(0, 81),
    completed: data['completed'] == true,
    endedAt: DateTime.parse(data['endedAt'] as String),
  );
}

class _Move {
  _Move(GameController game)
    : values = List<int>.of(game.values),
      notes = game.notes.map((entry) => Set<int>.of(entry)).toList(),
      hints = Set<int>.of(game.hints),
      won = game.won;
  final List<int> values;
  final List<Set<int>> notes;
  final Set<int> hints;
  final bool won;
}

class GameController extends ChangeNotifier {
  GameController({SudokuEngine? engine, SharedPreferencesAsync? preferences})
    : engine = engine ?? SudokuEngine(),
      _preferences = preferences ?? SharedPreferencesAsync() {
    _reset(Difficulty.easy);
  }

  static const _saveKey = 'sudoku_studio_game_v1';
  static const _historyKey = 'sudoku_studio_history_v1';
  final SudokuEngine engine;
  final SharedPreferencesAsync _preferences;
  final List<_Move> _past = [];
  final List<_Move> _future = [];
  final List<GameRecord> _history = [];

  late Difficulty difficulty;
  late List<int> givens;
  late List<int> solution;
  late List<int> values;
  late List<Set<int>> notes;
  Set<int> hints = {};
  int? selected;
  int seconds = 0;
  bool notesMode = false;
  bool paused = false;
  bool won = false;
  bool hasSavedGame = false;
  String message = 'Select a square to begin.';

  int get filled => values.where((value) => value != 0).length;
  bool get hasUnfinishedGame => hasSavedGame && !won;
  List<GameRecord> get history => List.unmodifiable(_history);
  bool get canUndo => _past.isNotEmpty && !paused && !won;
  bool get canRedo => _future.isNotEmpty && !paused && !won;
  Set<int> get conflictCells => engine.conflicts(values);

  void _reset(Difficulty level) {
    final puzzle = engine.generate(level);
    difficulty = level;
    givens = puzzle.givens;
    solution = puzzle.solution;
    values = List<int>.of(givens);
    notes = List.generate(81, (_) => <int>{});
    hints = {};
    selected = null;
    seconds = 0;
    paused = false;
    won = false;
    notesMode = false;
    _past.clear();
    _future.clear();
    message = 'Select a square to begin.';
    notifyListeners();
  }

  Future<void> load() async {
    try {
      final rawHistory = await _preferences.getString(_historyKey);
      if (rawHistory != null) {
        _history
          ..clear()
          ..addAll(
            (jsonDecode(rawHistory) as List).map(
              (entry) => GameRecord.fromJson(entry as Map<String, dynamic>),
            ),
          );
      }
    } catch (_) {
      _history.clear();
    }
    try {
      final raw = await _preferences.getString(_saveKey);
      if (raw == null) return;
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final level = Difficulty.values.firstWhere(
        (item) => item.name == data['difficulty'],
      );
      List<int> board(String key) => (data[key] as List).cast<int>();
      final savedGivens = board('givens');
      final savedSolution = board('solution');
      final savedValues = board('values');
      final savedNotes = (data['notes'] as List)
          .map((entry) => (entry as List).cast<int>().toSet())
          .toList();
      final valid =
          [savedGivens, savedSolution, savedValues].every(
            (board) =>
                board.length == 81 &&
                board.every((value) => value >= 0 && value <= 9),
          ) &&
          savedNotes.length == 81 &&
          savedNotes.every(
            (entry) => entry.every((value) => value >= 1 && value <= 9),
          );
      if (!valid) return;
      difficulty = level;
      givens = savedGivens;
      solution = savedSolution;
      values = savedValues;
      notes = savedNotes;
      hints = (data['hints'] as List)
          .cast<int>()
          .where((index) => index >= 0 && index < 81)
          .toSet();
      seconds = (data['seconds'] as int).clamp(0, 999999);
      won = data['won'] == true;
      hasSavedGame = true;
      selected = null;
      paused = false;
      notifyListeners();
    } catch (_) {
      // An old or corrupted save must never prevent the game from opening.
    }
  }

  Future<void> _save() async {
    if (!hasSavedGame) return;
    try {
      await _preferences.setString(
        _saveKey,
        jsonEncode({
          'difficulty': difficulty.name,
          'givens': givens,
          'solution': solution,
          'values': values,
          'notes': notes.map((entry) => entry.toList()).toList(),
          'hints': hints.toList(),
          'seconds': seconds,
          'won': won,
        }),
      );
    } catch (_) {
      // Keep play available if device storage is temporarily unavailable.
    }
  }

  Future<void> saveNow() async {
    await _save();
    await _saveHistory();
  }

  Future<void> _saveHistory() async {
    try {
      await _preferences.setString(
        _historyKey,
        jsonEncode(_history.map((record) => record.toJson()).toList()),
      );
    } catch (_) {
      // Local history is best effort when device storage is unavailable.
    }
  }

  void _archive(bool completed) {
    _history.insert(
      0,
      GameRecord(
        difficulty: difficulty,
        seconds: seconds,
        filled: filled,
        completed: completed,
        endedAt: DateTime.now(),
      ),
    );
    if (_history.length > 100) _history.removeLast();
    _saveHistory();
  }

  void newGame(Difficulty level) {
    if (hasUnfinishedGame) _archive(false);
    hasSavedGame = true;
    _reset(level);
    _save();
  }

  void select(int index) {
    if (paused || index < 0 || index >= 81) return;
    selected = index;
    message = givens[index] != 0
        ? 'This number is part of the puzzle.'
        : notesMode
        ? 'Add a possibility.'
        : 'Choose a number.';
    notifyListeners();
  }

  void toggleNotes() {
    if (paused || won) return;
    notesMode = !notesMode;
    message = notesMode ? 'Notes are on.' : 'Notes are off.';
    notifyListeners();
  }

  void togglePause() {
    if (won) return;
    paused = !paused;
    notifyListeners();
  }

  void tick() {
    if (paused || won) return;
    seconds++;
    notifyListeners();
    if (seconds % 5 == 0) _save();
  }

  void _record() {
    _past.add(_Move(this));
    if (_past.length > 100) _past.removeAt(0);
    _future.clear();
  }

  void _restore(_Move move) {
    values = List<int>.of(move.values);
    notes = move.notes.map((entry) => Set<int>.of(entry)).toList();
    hints = Set<int>.of(move.hints);
    won = move.won;
    notifyListeners();
    _save();
  }

  void undo() {
    if (!canUndo) return;
    _future.add(_Move(this));
    _restore(_past.removeLast());
    message = 'Last move undone.';
    notifyListeners();
  }

  void redo() {
    if (!canRedo) return;
    _past.add(_Move(this));
    _restore(_future.removeLast());
    message = 'Move restored.';
    notifyListeners();
  }

  void place(int value) {
    final index = selected;
    if (index == null || paused || won) {
      message = 'Select an empty square first.';
      notifyListeners();
      return;
    }
    if (givens[index] != 0) {
      message = 'Given numbers cannot be changed.';
      notifyListeners();
      return;
    }
    if (value < 0 || value > 9) return;
    if (notesMode && value > 0) {
      _record();
      values[index] = 0;
      if (!notes[index].add(value)) notes[index].remove(value);
      message = 'Note updated.';
    } else {
      if (values[index] == value && notes[index].isEmpty) return;
      _record();
      values[index] = value;
      notes[index].clear();
      if (value != 0) {
        for (final peer in engine.peers(index)) {
          notes[peer].remove(value);
        }
      }
      message = value == 0
          ? 'Square cleared.'
          : conflictCells.contains(index)
          ? 'That number repeats in this row, column, or box.'
          : 'Nicely placed.';
    }
    _finishIfSolved();
    notifyListeners();
    _save();
  }

  void erase() {
    final index = selected;
    if (index == null || paused || won || givens[index] != 0) return;
    place(0);
  }

  void hint() {
    if (paused || won) return;
    var index = selected;
    if (index == null ||
        givens[index] != 0 ||
        values[index] == solution[index]) {
      index = values.indexed
          .where(
            (entry) => givens[entry.$1] == 0 && entry.$2 != solution[entry.$1],
          )
          .map((entry) => entry.$1)
          .firstOrNull;
    }
    if (index == null) {
      message = 'Everything is in place.';
      notifyListeners();
      return;
    }
    _record();
    values[index] = solution[index];
    notes[index].clear();
    hints.add(index);
    selected = index;
    for (final peer in engine.peers(index)) {
      notes[peer].remove(solution[index]);
    }
    message = 'A little nudge, right there.';
    _finishIfSolved();
    notifyListeners();
    _save();
  }

  void _finishIfSolved() {
    if (!won &&
        List.generate(
          81,
          (index) => values[index] == solution[index],
        ).every((match) => match)) {
      won = true;
      message = 'Puzzle complete. Beautifully done!';
      _archive(true);
    }
  }
}
