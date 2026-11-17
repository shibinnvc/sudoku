import { LEVELS, conflictCells, generatePuzzle, peers } from './core.js';

const KEY = 'chachus-sudoku-web-v1';
const OLD_KEY = 'sudoku-studio-v1';
const board = (value) => Array.isArray(value) && value.length === 81 && value.every((n) => Number.isInteger(n) && n >= 0 && n <= 9);
const notesValid = (value) => Array.isArray(value) && value.length === 81 && value.every((entry) => Array.isArray(entry) && entry.every((n) => Number.isInteger(n) && n >= 1 && n <= 9));

export function createGame(level) {
  const { puzzle, solution } = generatePuzzle(level);
  return {
    level, puzzle, solution, values: [...puzzle],
    notes: Array.from({ length: 81 }, () => []), hinted: [], seconds: 0,
    paused: false, won: false, archived: false, selected: null, notesMode: false,
    past: [], future: [],
  };
}

export function validGame(game) {
  return game && LEVELS[game.level] && board(game.puzzle) && board(game.solution)
    && board(game.values) && notesValid(game.notes) && Array.isArray(game.hinted)
    && game.hinted.every((n) => Number.isInteger(n) && n >= 0 && n < 81)
    && Number.isInteger(game.seconds) && game.seconds >= 0;
}

function restoreGame(value) {
  return validGame(value) ? {
    ...value, paused: false, selected: null, notesMode: false,
    archived: Boolean(value.archived), past: [], future: [],
  } : null;
}

export function loadSession() {
  try {
    const data = JSON.parse(localStorage.getItem(KEY));
    if (data && Array.isArray(data.history)) {
      return { active: restoreGame(data.active), history: data.history.filter(validRecord).slice(0, 100) };
    }
    const old = JSON.parse(localStorage.getItem(OLD_KEY));
    const active = restoreGame(old);
    if (active) return { active, history: [] };
  } catch { /* A damaged save must not stop the app from opening. */ }
  return { active: null, history: [] };
}

function validRecord(record) {
  return record && LEVELS[record.level] && Number.isInteger(record.seconds)
    && Number.isInteger(record.filled) && record.filled >= 0 && record.filled <= 81
    && typeof record.completed === 'boolean' && !Number.isNaN(Date.parse(record.endedAt));
}

export function saveSession(session) {
  try {
    const active = session.active && (({ selected, past, future, notesMode, ...saved }) => saved)(session.active);
    localStorage.setItem(KEY, JSON.stringify({ active, history: session.history }));
  } catch { /* Gameplay remains usable when browser storage is unavailable. */ }
}

export function recordFor(game, completed) {
  return {
    level: game.level, seconds: game.seconds,
    filled: game.values.filter(Boolean).length,
    completed, endedAt: new Date().toISOString(),
  };
}

const snapshot = (game) => ({
  values: [...game.values], notes: game.notes.map((entry) => [...entry]),
  hinted: [...game.hinted], won: game.won,
});

function beforeMove(game) {
  return { ...game, values: [...game.values], notes: game.notes.map((entry) => [...entry]),
    hinted: [...game.hinted], past: [...game.past, snapshot(game)].slice(-100), future: [] };
}

export function place(game, digit) {
  const index = game.selected;
  if (index == null || game.paused || game.won || game.puzzle[index]) return game;
  if (game.notesMode && digit) {
    const next = beforeMove(game);
    next.values[index] = 0;
    next.notes[index] = next.notes[index].includes(digit)
      ? next.notes[index].filter((n) => n !== digit)
      : [...next.notes[index], digit].sort((a, b) => a - b);
    return next;
  }
  if (game.values[index] === digit && !game.notes[index].length) return game;
  const next = beforeMove(game);
  next.values[index] = digit;
  next.notes[index] = [];
  if (digit) for (const peer of peers(index)) next.notes[peer] = next.notes[peer].filter((n) => n !== digit);
  next.won = next.values.every((value, i) => value === next.solution[i]);
  return next;
}

export function hint(game) {
  if (game.paused || game.won) return game;
  let index = game.selected;
  if (index == null || game.puzzle[index] || game.values[index] === game.solution[index]) {
    index = game.values.findIndex((value, i) => !game.puzzle[i] && value !== game.solution[i]);
  }
  if (index < 0) return game;
  const next = beforeMove(game);
  next.values[index] = next.solution[index];
  next.notes[index] = [];
  next.hinted.push(index);
  next.selected = index;
  for (const peer of peers(index)) next.notes[peer] = next.notes[peer].filter((n) => n !== next.solution[index]);
  next.won = next.values.every((value, i) => value === next.solution[i]);
  return next;
}

export function travel(game, direction) {
  const source = direction === 'undo' ? game.past : game.future;
  if (game.paused || game.won || !source.length) return game;
  const previous = source.at(-1);
  return { ...game, ...previous,
    past: direction === 'undo' ? game.past.slice(0, -1) : [...game.past, snapshot(game)],
    future: direction === 'redo' ? game.future.slice(0, -1) : [...game.future, snapshot(game)],
  };
}

export function hasConflict(game) {
  return game?.selected != null && conflictCells(game.values).has(game.selected);
}
