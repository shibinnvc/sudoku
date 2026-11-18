# Chachu's Sudoku for iOS and Android

Flutter is the primary mobile app. It opens to a welcome screen with Continue, New Game, and Game History. New Game asks for a difficulty before showing the puzzle. The game runs offline and saves the current puzzle and history on the device.

## Run

```sh
flutter pub get
flutter run
```

Use `flutter test` and `flutter analyze` for verification. An Android debug APK can be built with `flutter build apk --debug`.

## Release to Google Play

The app is published as `com.shibinnvc.chachussudoku`. Release builds are signed with the upload key described in `android/key.properties`. That file is gitignored, so restore it from your backup on a new machine.

1. Raise `version:` in `pubspec.yaml`, for example `1.0.0+1` → `1.0.1+2`. The number after `+` is the Android version code, and it must increase with every upload.
2. Run `flutter test`, then `flutter build appbundle --release`.
3. In Play Console, go to **Test and release › Production › Create new release**. Upload `build/app/outputs/bundle/release/app-release.aab`, add release notes, and save.
4. In **Publishing overview**, click **Send changes for review**.

Store listing text, graphics and policy answers are in [`store/PLAY_STORE.md`](store/PLAY_STORE.md). CI/CD and Firebase details are in the [root README](../README.md).

## Code map

- `lib/sudoku_engine.dart` — pure Sudoku rules, randomized generation, uniqueness checks
- `lib/game_controller.dart` — game state, actions, undo/redo, current save and history
- `lib/main.dart` — welcome, difficulty, puzzle and history screens
- `tool/generate_icon.swift` — source for the app icon

The current game uses `shared_preferences` for one resumable puzzle and up to 100 history records. Replacing a puzzle records it as unfinished; solving one records it as completed. Firebase is reserved for account-based sync and daily puzzles. The sync layer should be a repository that serializes versioned game documents, keeps local play available offline, and resolves stale writes with a revision and server timestamp. Firebase Authentication and Firestore security rules are required before cloud saves are enabled.
