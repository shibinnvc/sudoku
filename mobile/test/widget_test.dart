import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sudoku_studio/main.dart';

void main() {
  testWidgets('home leads through difficulty to a resumable puzzle', (
    tester,
  ) async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    await tester.pumpWidget(const SudokuStudioApp());
    await tester.pump();
    expect(find.text("Chachu's sudoku"), findsOneWidget);
    expect(
      find.text('One square at a time. Enjoy the puzzle.'),
      findsOneWidget,
    );
    expect(find.text('New game'), findsOneWidget);
    expect(find.text('Continue game'), findsNothing);

    await tester.tap(find.text('New game'));
    await tester.pump();
    expect(find.text('Choose your pace.'), findsOneWidget);
    await tester.tap(find.text('Easy'));
    await tester.pump();
    expect(find.byTooltip('Home'), findsOneWidget);
    expect(find.text('One square at a time. Enjoy the puzzle.'), findsNothing);

    await tester.tap(find.byTooltip('Home'));
    await tester.pump();
    expect(find.text('Continue game'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
