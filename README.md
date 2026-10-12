# Sudoku Studio

A calm, responsive Sudoku game built with plain HTML, CSS, and JavaScript. Open `dist/index.html` through a local HTTP server or deploy `dist/` as a static site.

## Play

- Three difficulty levels with newly generated, uniquely solvable puzzles
- Notes, hints, undo and redo, keyboard controls, conflict highlighting, pause, and timer
- Progress saved automatically in the browser

Run `npm test` to check puzzle generation and Sudoku constraints. No installation is required.

## Architecture

The game is deliberately local first. `dist/core.js` holds pure puzzle rules and generation. `dist/app.js` owns the game state, interactions, and browser storage. `dist/styles.css` owns the visual system. This keeps core logic testable and allows the UI to change without rewriting puzzle rules.

Firebase is a later integration, not a requirement for solo play. A cloud version should add Firebase Authentication (anonymous sign in with an optional account upgrade), Firestore for per-user saved games and preferences, and security rules that only allow each user to access their own documents. The client should retain local saves for offline play and sync a small, versioned game document when connected. Server timestamps and a revision number can resolve stale writes. Puzzle generation should remain on the client for casual play; competitive daily puzzles would need server-issued puzzle IDs and validation.

## Delivery tickets

| ID | Ticket | Acceptance criteria | Status |
| --- | --- | --- | --- |
| SUD-01 | Define visual design and responsive shell | Clear hierarchy, keyboard focus, mobile layout | Done |
| SUD-02 | Implement puzzle engine | Valid solutions, unique puzzle, three levels, automated checks | Done |
| SUD-03 | Implement gameplay | Notes, hint, erase, undo/redo, conflicts, win state, pause | Done |
| SUD-04 | Save progress locally | Refresh restores board, notes, elapsed time, difficulty | Done |
| SUD-05 | Browser QA and accessibility review | Verify desktop/mobile interactions and screen reader labels | In progress |
| SUD-06 | Firebase account and cloud sync | User-owned games sync across devices; offline reconciliation | Planned |
| SUD-07 | Daily puzzle and player history | Stable daily puzzle, completion history, streaks | Planned |

## Firebase data shape for SUD-06

`users/{uid}/games/{gameId}`: `schemaVersion`, `puzzle`, `solution`, `values`, `notes`, `level`, `seconds`, `status`, `revision`, `updatedAt`. The solution should be excluded from any future competitive game document and verified in trusted server code. Add `users/{uid}/preferences/main` for settings. Firestore rules should require `request.auth.uid == uid`, validate expected fields, and cap document sizes.
