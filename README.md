# Chachu's Sudoku

A calm Sudoku game for the web and mobile. The web app is built with React and Vite; the Flutter app is in [`mobile/`](mobile/README.md). The earlier plain JavaScript prototype remains in `dist/`.

## Web app

```sh
npm install
npm run dev
npm test
npm run build
```

The web app opens on a welcome screen with **Continue game**, **New game**, and **Game history**. New game asks for Easy, Medium, or Hard before showing a uniquely solvable puzzle. The puzzle screen keeps the grid front and center, with notes, undo, redo, erase, hint, pause, keyboard input, conflict highlighting, a timer, and progress.

Game state and up to 100 history entries are saved in browser storage. An old save from the plain JavaScript prototype is imported on first use. Browser saves are specific to that browser and are not synchronized with the Flutter app.

## Architecture

- `src/App.jsx` owns the screen flow and accessible React UI.
- `src/game.js` owns game state transitions, save validation, and history records.
- `dist/core.js` remains the shared, pure puzzle engine; `src/core.js` reexports it for the React build.
- `src/styles.css` defines the responsive visual system.
- `firebase.json` serves the static Vite build from `build-web/` with a single page app rewrite.

Firebase Hosting serves the web app. No Firebase Authentication or Firestore is enabled for this release, because solo play works without an account or network connection after the app loads. Cloud synchronization is a separate ticket requiring user identity, security rules, and conflict handling.

## Firebase deployment

Project: `chachus-sudoku-2026` (display name: Chachu's Sudoku).

```sh
npm run build
firebase deploy --only hosting --project chachus-sudoku-2026
```

## Delivery tickets

| ID | Ticket | Acceptance criteria | Status |
| --- | --- | --- | --- |
| SUD-01 | Puzzle engine | Valid grids, unique solution, three difficulties, unit tests | Done |
| SUD-02 | React screen flow | Welcome, Continue, difficulty choice, puzzle, history | Done |
| SUD-03 | React gameplay | Notes, undo/redo, erase, hint, pause, timer, keyboard, conflicts | Done |
| SUD-04 | Local persistence | Restore unfinished puzzle; archive replaced and completed games | Done |
| SUD-05 | Responsive design and browser QA | Desktop and mobile layout, keyboard focus, visible controls | Done |
| SUD-06 | Firebase Hosting | New project, production build, live URL | Done |
| SUD-07 | Cloud sync | Optional sign in, Firestore user documents, rules, offline reconciliation | Planned |
| SUD-08 | Flutter iOS and Android | Native projects, local saves, same core flow | Done |
| SUD-09 | Daily puzzle and streaks | Stable daily challenge, history and streak tracking | Planned |

For SUD-07, use Firebase Authentication and `users/{uid}/games/{gameId}` in Firestore, with rules that restrict each document to its owner. Keep a local save for offline use and add a revision number to settle concurrent updates. Competitive puzzles would need server issued IDs and trusted solution validation.
