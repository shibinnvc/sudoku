import 'dart:async';
import 'package:flutter/material.dart';
import 'game_controller.dart';
import 'sudoku_engine.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SudokuStudioApp());
}

class Palette {
  static const background = Color(0xfff7f6f2);
  static const ink = Color(0xff243f3a);
  static const green = Color(0xff2d6758);
  static const sage = Color(0xff81988b);
  static const muted = Color(0xff98a69b);
  static const line = Color(0xffe5ebe4);
  static const gold = Color(0xffad9567);
  static const selected = Color(0xffd9ebdc);
  static const related = Color(0xfff0f5ef);
  static const same = Color(0xffe5f1e8);
  static const error = Color(0xffbd6959);
}

class SudokuStudioApp extends StatelessWidget {
  const SudokuStudioApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: "chachu's sudoku",
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: Palette.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Palette.green,
        surface: Palette.background,
      ),
      textTheme: Theme.of(context).textTheme.apply(
        fontFamily: 'sans-serif',
        bodyColor: Palette.ink,
        displayColor: Palette.ink,
      ),
    ),
    home: const GameScreen(),
  );
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});
  @override
  State<GameScreen> createState() => _GameScreenState();
}

enum _Page { home, levels, game, history }

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  late final GameController game;
  Timer? _timer;
  bool _foreground = true;
  bool _winShown = false;
  bool _loading = true;
  _Page _page = _Page.home;
  _Page _levelBackPage = _Page.home;

  @override
  void initState() {
    super.initState();
    game = GameController()..addListener(_gameChanged);
    _loadGame();
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_foreground && _page == _Page.game) game.tick();
    });
  }

  Future<void> _loadGame() async {
    await game.load();
    if (mounted) setState(() => _loading = false);
  }

  void _openLevels(_Page from) {
    setState(() {
      _levelBackPage = from;
      _page = _Page.levels;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (!_foreground) game.saveNow();
  }

  void _gameChanged() {
    if (!mounted) return;
    setState(() {});
    if (game.won && !_winShown && _page == _Page.game) {
      _winShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showWin();
      });
    }
    if (!game.won) _winShown = false;
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    game.removeListener(_gameChanged);
    game.dispose();
    super.dispose();
  }

  Future<void> _requestNew(Difficulty level) async {
    if (game.hasUnfinishedGame) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text('Start something fresh?'),
          content: const Text(
            'Your current game will move to History as unfinished.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep playing'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('New puzzle'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    if (!mounted) return;
    game.newGame(level);
    setState(() => _page = _Page.game);
  }

  void _showWin() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        icon: const Icon(
          Icons.auto_awesome_rounded,
          color: Palette.gold,
          size: 38,
        ),
        title: const Text('Beautifully done.', textAlign: TextAlign.center),
        content: Text(
          'You found your way through in ${_time(game.seconds)}.',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Stay here'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _openLevels(_Page.game);
            },
            child: const Text('New game'),
          ),
        ],
      ),
    );
  }

  void _showHelp() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Palette.line,
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
              ),
              const SizedBox(height: 26),
              const Icon(Icons.grid_on_rounded, size: 30, color: Palette.green),
              const SizedBox(height: 14),
              const Text(
                'How to play',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.7,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Fill each row, column, and 3 × 3 box with the numbers 1 through 9. Each number appears once in each group.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: Palette.sage,
                ),
              ),
              const SizedBox(height: 25),
              const _HelpRow(
                'Place a number',
                'Tap a square, then choose a number below the board.',
              ),
              const _HelpRow(
                'Make notes',
                'Turn on Notes to pencil in possibilities.',
              ),
              const _HelpRow(
                'Need a nudge?',
                'Hint reveals one square. Undo and redo are nearby.',
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Let’s play'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => switch (_page) {
    _Page.home => _homeScreen(),
    _Page.levels => _levelsScreen(),
    _Page.game => _puzzleScreen(),
    _Page.history => _historyScreen(),
  };

  Widget _homeScreen() => Scaffold(
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _header(),
                const SizedBox(height: 64),
                const Text(
                  'A LITTLE ROOM TO THINK',
                  style: TextStyle(
                    color: Palette.sage,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.2,
                  ),
                ),
                const SizedBox(height: 12),
                RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      fontSize: 43,
                      color: Palette.ink,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -2,
                    ),
                    children: [
                      TextSpan(text: 'Find your '),
                      TextSpan(
                        text: 'flow.',
                        style: TextStyle(
                          fontFamily: 'Georgia',
                          fontWeight: FontWeight.w400,
                          fontStyle: FontStyle.italic,
                          color: Palette.gold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'One square at a time. Enjoy the puzzle.',
                  style: TextStyle(
                    color: Palette.sage,
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 48),
                if (_loading)
                  const Center(
                    child: CircularProgressIndicator(color: Palette.green),
                  ),
                if (!_loading && game.hasUnfinishedGame) ...[
                  _continueCard(),
                  const SizedBox(height: 24),
                ],
                const Text(
                  'YOUR NEXT MOVE',
                  style: TextStyle(
                    color: Palette.sage,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: FilledButton.icon(
                    onPressed: _loading ? null : () => _openLevels(_Page.home),
                    style: FilledButton.styleFrom(
                      backgroundColor: Palette.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                    ),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text(
                      'New game',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: OutlinedButton.icon(
                    onPressed: _loading
                        ? null
                        : () => setState(() => _page = _Page.history),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Palette.green,
                      side: const BorderSide(color: Palette.line),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                    ),
                    icon: const Icon(Icons.history_rounded),
                    label: const Text(
                      'Game history',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                const Center(
                  child: Text(
                    '✦  Take your time. The grid will wait for you.',
                    style: TextStyle(color: Palette.muted, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Widget _continueCard() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: Palette.line),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0a36594a),
          blurRadius: 28,
          offset: Offset(0, 9),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'CONTINUE WHERE YOU LEFT OFF',
          style: TextStyle(
            color: Palette.sage,
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.7,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '${game.difficulty.label} puzzle',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.7,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          '${game.filled} of 81 cells filled  ·  ${_time(game.seconds)}',
          style: const TextStyle(color: Palette.sage, fontSize: 12),
        ),
        const SizedBox(height: 18),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: game.filled / 81,
            minHeight: 5,
            backgroundColor: Palette.line,
            valueColor: const AlwaysStoppedAnimation(Palette.green),
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => setState(() => _page = _Page.game),
            style: FilledButton.styleFrom(backgroundColor: Palette.green),
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Continue game'),
          ),
        ),
      ],
    ),
  );

  Widget _levelsScreen() => _simplePage(
    title: 'Choose your pace.',
    eyebrow: 'NEW GAME',
    subtitle: 'Pick a difficulty that feels right today.',
    onBack: () => setState(() => _page = _levelBackPage),
    children: [
      _levelTile(
        Difficulty.easy,
        Icons.spa_outlined,
        'A gentle place to begin.',
      ),
      _levelTile(
        Difficulty.medium,
        Icons.tune_rounded,
        'A balanced challenge.',
      ),
      _levelTile(
        Difficulty.hard,
        Icons.auto_awesome_rounded,
        'For a deeper focus.',
      ),
    ],
  );

  Widget _levelTile(Difficulty level, IconData icon, String detail) => Padding(
    padding: const EdgeInsets.only(bottom: 13),
    child: Semantics(
      button: true,
      label: '${level.label} difficulty. $detail',
      onTap: () => _requestNew(level),
      excludeSemantics: true,
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Palette.line),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _requestNew(level),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xffe9f3eb),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: Palette.green),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        level.label,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        detail,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Palette.sage,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Palette.sage),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Widget _historyScreen() => _simplePage(
    title: 'Your journey.',
    eyebrow: 'GAME HISTORY',
    subtitle: 'Every puzzle is a moment well spent.',
    onBack: () => setState(() => _page = _Page.home),
    children: game.history.isEmpty
        ? [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 52, horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Palette.line),
              ),
              child: const Column(
                children: [
                  Icon(Icons.history_rounded, color: Palette.sage, size: 34),
                  SizedBox(height: 14),
                  Text(
                    'No games yet',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                  SizedBox(height: 7),
                  Text(
                    'Finished and replaced games will appear here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Palette.sage, fontSize: 12),
                  ),
                ],
              ),
            ),
          ]
        : [for (final record in game.history) _historyTile(record)],
  );

  Widget _historyTile(GameRecord record) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: Palette.line),
    ),
    child: Row(
      children: [
        Container(
          width: 43,
          height: 43,
          decoration: BoxDecoration(
            color: record.completed
                ? const Color(0xffe9f3eb)
                : const Color(0xfff4f1e9),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(
            record.completed ? Icons.check_rounded : Icons.more_horiz_rounded,
            color: record.completed ? Palette.green : Palette.gold,
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${record.difficulty.label} puzzle',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${record.completed ? 'Completed' : 'Unfinished'} · ${_date(record.endedAt)}',
                style: const TextStyle(color: Palette.sage, fontSize: 11),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _time(record.seconds),
              style: const TextStyle(
                color: Palette.green,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              '${record.filled}/81',
              style: const TextStyle(color: Palette.muted, fontSize: 10),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _simplePage({
    required String title,
    required String eyebrow,
    required String subtitle,
    required VoidCallback onBack,
    required List<Widget> children,
  }) => Scaffold(
    body: SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 14, 22, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: onBack,
                  tooltip: 'Back',
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: Palette.green,
                  ),
                ),
                const SizedBox(height: 47),
                Text(
                  eyebrow,
                  style: const TextStyle(
                    color: Palette.sage,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.2,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  subtitle,
                  style: const TextStyle(color: Palette.sage, fontSize: 14),
                ),
                const SizedBox(height: 35),
                ...children,
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Widget _puzzleScreen() => Scaffold(
    bottomNavigationBar: SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Palette.line)),
        ),
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 510),
            child: _numbers(),
          ),
        ),
      ),
    ),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        game.saveNow();
                        setState(() => _page = _Page.home);
                      },
                      tooltip: 'Home',
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: Palette.green,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => _openLevels(_Page.game),
                      tooltip: 'New game',
                      icon: const Icon(Icons.add_rounded, color: Palette.green),
                    ),
                    IconButton(
                      onPressed: _showHelp,
                      tooltip: 'How to play',
                      icon: const Icon(
                        Icons.help_outline_rounded,
                        color: Palette.sage,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _gameCard(),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Widget _header() => Row(
    children: [
      const _Logo(),
      const SizedBox(width: 9),
      const Expanded(
        child: Text(
          "Chachu's sudoku",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.7,
          ),
        ),
      ),
      IconButton(
        onPressed: _showHelp,
        tooltip: 'How to play',
        icon: const Icon(
          Icons.help_outline_rounded,
          color: Palette.sage,
          size: 22,
        ),
      ),
    ],
  );

  Widget _gameCard() => Container(
    padding: const EdgeInsets.fromLTRB(15, 16, 15, 15),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(23),
      border: Border.all(color: Palette.line),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0a36594a),
          blurRadius: 35,
          offset: Offset(0, 12),
        ),
      ],
    ),
    child: Column(
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xffedf5ee),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                game.difficulty.label,
                style: const TextStyle(
                  color: Palette.green,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const Spacer(),
            const Icon(Icons.schedule_rounded, color: Palette.sage, size: 17),
            const SizedBox(width: 5),
            Text(
              _time(game.seconds),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Palette.green,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            IconButton(
              onPressed: game.togglePause,
              tooltip: game.paused ? 'Resume game' : 'Pause game',
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              icon: Icon(
                game.paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                color: Palette.sage,
                size: 19,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _board(),
        SizedBox(
          height: 25,
          child: Center(
            child: Text(
              game.message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: game.message.contains('repeats')
                    ? Palette.error
                    : Palette.muted,
                fontSize: 11,
              ),
            ),
          ),
        ),
        _tools(),
      ],
    ),
  );

  Widget _board() => AspectRatio(
    aspectRatio: 1,
    child: Stack(
      children: [
        ExcludeSemantics(
          excluding: game.paused,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Palette.green, width: 2),
              borderRadius: BorderRadius.circular(4),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var row = 0; row < 9; row++)
                  Expanded(
                    child: Row(
                      children: [
                        for (var column = 0; column < 9; column++)
                          Expanded(child: _cell(row * 9 + column)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (game.paused)
          Positioned.fill(
            child: Container(
              color: const Color(0xfff9fbf7),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: const Color(0xffe5f0e7),
                      borderRadius: BorderRadius.circular(17),
                    ),
                    child: const Icon(
                      Icons.pause_rounded,
                      size: 31,
                      color: Palette.green,
                    ),
                  ),
                  const SizedBox(height: 17),
                  const Text(
                    'Take a breather',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Your puzzle is right where you left it.',
                    style: TextStyle(fontSize: 11, color: Palette.sage),
                  ),
                  const SizedBox(height: 19),
                  FilledButton(
                    onPressed: game.togglePause,
                    child: const Text('Resume game'),
                  ),
                ],
              ),
            ),
          ),
      ],
    ),
  );

  Widget _cell(int index) {
    final value = game.values[index];
    final selected = game.selected == index;
    final related =
        game.selected != null &&
        game.engine.peers(game.selected!).contains(index);
    final same =
        game.selected != null &&
        game.values[game.selected!] != 0 &&
        value == game.values[game.selected!] &&
        !selected;
    final conflict = game.conflictCells.contains(index);
    final background = conflict
        ? const Color(0xffffeee8)
        : selected
        ? Palette.selected
        : same
        ? Palette.same
        : related
        ? Palette.related
        : Colors.white;
    final row = index ~/ 9;
    final column = index % 9;
    return Semantics(
      button: true,
      selected: selected,
      label:
          'Row ${row + 1}, column ${column + 1}, ${value == 0
              ? game.notes[index].isEmpty
                    ? 'empty'
                    : 'notes ${game.notes[index].join(', ')}'
              : value}${game.givens[index] != 0 ? ', given' : ''}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => game.select(index),
        child: Container(
          decoration: BoxDecoration(
            color: background,
            border: Border(
              right: column == 8
                  ? BorderSide.none
                  : BorderSide(
                      color: column == 2 || column == 5
                          ? Palette.green
                          : Palette.line,
                      width: column == 2 || column == 5 ? 2 : 0.7,
                    ),
              bottom: row == 8
                  ? BorderSide.none
                  : BorderSide(
                      color: row == 2 || row == 5
                          ? Palette.green
                          : Palette.line,
                      width: row == 2 || row == 5 ? 2 : 0.7,
                    ),
            ),
          ),
          child: Center(
            child: value != 0
                ? Text(
                    '$value',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: game.givens[index] != 0
                          ? FontWeight.w800
                          : FontWeight.w600,
                      color: conflict
                          ? Palette.error
                          : game.givens[index] != 0
                          ? Palette.ink
                          : Palette.green,
                    ),
                  )
                : _cellNotes(game.notes[index]),
          ),
        ),
      ),
    );
  }

  Widget _cellNotes(Set<int> notes) {
    if (notes.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        for (var row = 0; row < 3; row++)
          Expanded(
            child: Row(
              children: [
                for (var column = 0; column < 3; column++)
                  Expanded(
                    child: Center(
                      child: Text(
                        notes.contains(row * 3 + column + 1)
                            ? '${row * 3 + column + 1}'
                            : '',
                        style: const TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          color: Palette.sage,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _tools() => Row(
    children: [
      _tool(Icons.undo_rounded, 'Undo', game.canUndo ? game.undo : null),
      _tool(Icons.redo_rounded, 'Redo', game.canRedo ? game.redo : null),
      _tool(Icons.backspace_outlined, 'Erase', game.paused ? null : game.erase),
      _tool(
        Icons.edit_note_rounded,
        game.notesMode ? 'Notes on' : 'Notes',
        game.paused ? null : game.toggleNotes,
        active: game.notesMode,
      ),
      _tool(
        Icons.auto_awesome_outlined,
        'Hint',
        game.paused ? null : game.hint,
      ),
    ],
  );

  Widget _tool(
    IconData icon,
    String label,
    VoidCallback? action, {
    bool active = false,
  }) => Expanded(
    child: Semantics(
      button: true,
      enabled: action != null,
      label: label,
      onTap: action,
      excludeSemantics: true,
      child: InkWell(
        onTap: action,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: active ? const Color(0xffe9f4eb) : null,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 23,
                color: action == null
                    ? Palette.line
                    : active
                    ? Palette.green
                    : Palette.sage,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: action == null
                      ? Palette.line
                      : active
                      ? Palette.green
                      : Palette.sage,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _numbers() => Row(
    children: [
      for (var number = 1; number <= 9; number++)
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: number == 9 ? 0 : 4),
            child: Material(
              color: const Color(0xfff7faf6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: Palette.line),
              ),
              child: InkWell(
                onTap: game.paused || game.won
                    ? null
                    : () => game.place(number),
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  height: 43,
                  child: Center(
                    child: Text(
                      '$number',
                      style: const TextStyle(
                        color: Palette.green,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
    ],
  );
}

class _Logo extends StatelessWidget {
  const _Logo();
  @override
  Widget build(BuildContext context) => Transform.rotate(
    angle: -0.12,
    child: SizedBox(
      width: 27,
      height: 27,
      child: Column(
        children: [
          for (var row = 0; row < 2; row++)
            Expanded(
              child: Row(
                children: [
                  for (var column = 0; column < 2; column++)
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.all(1.5),
                        decoration: BoxDecoration(
                          color: Palette.green.withValues(
                            alpha: [1.0, 0.7, 0.5, 0.85][row * 2 + column],
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    ),
  );
}

class _HelpRow extends StatelessWidget {
  const _HelpRow(this.title, this.detail);
  final String title;
  final String detail;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Palette.green,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          detail,
          style: const TextStyle(
            color: Palette.sage,
            fontSize: 12,
            height: 1.4,
          ),
        ),
      ],
    ),
  );
}

String _time(int seconds) =>
    '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';

String _date(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}
