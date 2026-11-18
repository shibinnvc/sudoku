# Publishing to Google Play

## Build the release bundle

```sh
cd mobile
flutter build appbundle --release
# -> build/app/outputs/bundle/release/app-release.aab
```

Before each new upload, bump `version:` in `pubspec.yaml` (e.g. `1.0.0+1` -> `1.0.1+2`).
Play rejects an upload whose build number (after the `+`) it has already seen.

## Signing

- The upload keystore lives at `~/keys/chachus-sudoku-upload.jks` (alias `upload`).
- Passwords are in `mobile/android/key.properties`. That file is gitignored and must never be committed.
- **Back up both files** to a password manager or other safe place. With Play App Signing
  (the default for new apps), Google holds the real app signing key, so a lost upload key
  can be reset through Play Console support. Still, avoid losing it.
- If `key.properties` is missing, release builds fall back to the debug key, and Play will reject them.

Upload key SHA-256 fingerprint:
`98:FA:02:1A:3E:21:8B:51:8B:AA:4B:53:EE:B3:73:BF:7D:65:A7:A7:16:73:30:CC:C7:31:29:6C:D4:3C:B4:CA`

## App identity

| Field | Value |
| --- | --- |
| Package name | `com.shibinnvc.chachussudoku` (permanent once published) |
| App name | Chachu's Sudoku |
| Category | Games › Puzzle |
| Min / target SDK | 24 / 36 |
| Privacy policy | https://chachus-sudoku-2026.web.app/privacy.html |

## Store listing assets

| Asset | Requirement | Status |
| --- | --- | --- |
| App icon | 512×512 PNG | `store/play-icon-512.png` |
| Feature graphic | 1024×500 JPG/PNG, no transparency | `store/feature-graphic-1024x500.jpg` |
| Phone screenshots | 2–8, long side at most 2× short side | `store/screenshots/01.png`–`06.png` (1080×1920), upload in this order |

Short description (max 80 chars):

> A calm, beautifully simple Sudoku. Three difficulties, no ads, works offline.

Full description:

> Chachu's Sudoku is a calm, distraction-free Sudoku game.
>
> • Three difficulty levels: Easy, Medium and Hard
> • Pencil notes, undo, and hints when you get stuck
> • Your game saves automatically, so you can pick up right where you left off
> • A timer and a history of your solved games
> • Works completely offline
> • No ads, no accounts, no tracking
>
> Just you and the puzzle.

Check that the feature bullets match the app before submitting.

## Play Console answers

- **Ads:** No ads.
- **App access:** All functionality is available without special access.
- **Content rating questionnaire:** Puzzle game with no violence, user content, gambling or data sharing. Expect the lowest rating (Everyone / PEGI 3).
- **Target audience:** 13+ is simplest. Including under-13s opts into the Families policy.
- **Data safety:** No data collected, no data shared. Data is not encrypted in transit because none is transmitted. Users cannot request deletion because nothing is stored off-device.
- **Government / financial / health features:** None.

## Release steps

1. Create the app in Play Console (Games, Free).
2. Fill in the store listing, the content rating, data safety, target audience and the privacy policy URL.
3. New personal developer accounts must run a **closed test with at least 12 testers for 14 days**
   before they can apply for production access. Upload the `.aab` to a closed testing track first.
4. After the test period, apply for production access and promote the release.
