import { LEVELS, generatePuzzle, peers, candidates, conflictCells, formatTime } from './core.js';

const STORAGE_KEY = 'sudoku-studio-v1';
const $ = (selector) => document.querySelector(selector);
const boardEl = $('#board');
const numberPad = $('#numberPad');
const feedbackEl = $('#gameFeedback');
let state;
let pendingLevel = null;

function fresh(level) {
  const { puzzle, solution } = generatePuzzle(level);
  return { version: 1, level, puzzle, solution, values: [...puzzle], notes: Array.from({ length: 81 }, () => []), hinted: [], seconds: 0, paused: false, won: false, selected: null, notesMode: false, past: [], future: [] };
}

function validSaved(data) {
  const board = (value) => Array.isArray(value) && value.length === 81 && value.every((n) => Number.isInteger(n) && n >= 0 && n <= 9);
  return data && data.version === 1 && LEVELS[data.level] && board(data.puzzle) && board(data.solution) && board(data.values) && Array.isArray(data.notes) && data.notes.length === 81 && data.notes.every((n) => Array.isArray(n) && n.every((v) => Number.isInteger(v) && v >= 1 && v <= 9)) && Array.isArray(data.hinted) && Number.isInteger(data.seconds) && data.seconds >= 0;
}

function restore() {
  try {
    const saved = JSON.parse(localStorage.getItem(STORAGE_KEY));
    if (validSaved(saved)) return { ...saved, paused: false, selected: null, past: [], future: [], notesMode: false };
  } catch { /* A private browsing mode or old saved value can fail safely. */ }
  return fresh('easy');
}

function save() {
  try {
    const { selected, past, future, ...persisted } = state;
    localStorage.setItem(STORAGE_KEY, JSON.stringify(persisted));
  } catch { /* Keep the current game playable when storage is unavailable. */ }
}

function snapshot() { return { values: [...state.values], notes: state.notes.map((notes) => [...notes]), hinted: [...state.hinted], won: state.won }; }
function applySnapshot(snapshot) { state.values = [...snapshot.values]; state.notes = snapshot.notes.map((notes) => [...notes]); state.hinted = [...snapshot.hinted]; state.won = snapshot.won; render(); save(); }
function record() { state.past.push(snapshot()); if (state.past.length > 100) state.past.shift(); state.future = []; }

function announce(message, kind = '') { feedbackEl.textContent = message; feedbackEl.className = `game-feedback ${kind}`; }
function filledCount() { return state.values.filter(Boolean).length; }

function render() {
  const conflicts = conflictCells(state.values);
  const selected = state.selected;
  const selectedValue = selected === null ? 0 : state.values[selected];
  const related = selected === null ? [] : peers(selected);
  boardEl.replaceChildren(...state.values.map((value, index) => {
    const button = document.createElement('button');
    button.type = 'button';
    button.className = 'cell';
    button.dataset.index = index;
    button.setAttribute('role', 'gridcell');
    button.setAttribute('aria-label', `Row ${Math.floor(index / 9) + 1}, column ${index % 9 + 1}: ${value || (state.notes[index].length ? `notes ${state.notes[index].join(', ')}` : 'empty')}${state.puzzle[index] ? ', given' : ''}`);
    button.setAttribute('aria-selected', String(index === selected));
    if (index % 9 === 2 || index % 9 === 5) button.classList.add('box-right');
    if (Math.floor(index / 9) === 2 || Math.floor(index / 9) === 5) button.classList.add('box-bottom');
    if (state.puzzle[index]) button.classList.add('given');
    if (related.includes(index)) button.classList.add('related');
    if (selectedValue && value === selectedValue && index !== selected) button.classList.add('same-number');
    if (index === selected) button.classList.add('selected');
    if (conflicts.has(index)) button.classList.add('conflict');
    if (state.hinted.includes(index)) button.classList.add('hinted');
    button.tabIndex = index === (selected ?? 0) ? 0 : -1;
    if (value) button.textContent = value;
    else if (state.notes[index].length) {
      const notes = document.createElement('span'); notes.className = 'notes';
      for (let digit = 1; digit <= 9; digit++) {
        const note = document.createElement('span');
        note.textContent = state.notes[index].includes(digit) ? digit : '';
        notes.append(note);
      }
      button.append(notes);
    }
    return button;
  }));
  $('#timer').textContent = formatTime(state.seconds);
  $('#sideTime').textContent = formatTime(state.seconds);
  $('#sideDifficulty').textContent = LEVELS[state.level].label;
  $('#sideProgress').textContent = `${filledCount()} / 81`;
  $('#progressFill').style.width = `${filledCount() / 81 * 100}%`;
  $('#progressCaption').textContent = state.won ? 'A beautiful finish. Well done.' : filledCount() > 65 ? 'So close. Keep going.' : filledCount() > state.puzzle.filter(Boolean).length ? 'You’re finding your rhythm.' : 'A fresh start. You’ve got this.';
  document.querySelectorAll('[data-level]').forEach((button) => { button.classList.toggle('active', button.dataset.level === state.level); button.setAttribute('aria-pressed', String(button.dataset.level === state.level)); });
  $('#notesButton').classList.toggle('active', state.notesMode);
  $('#notesButton').setAttribute('aria-pressed', String(state.notesMode));
  $('#notesBadge').textContent = state.notesMode ? 'On' : 'Off';
  $('#undoButton').disabled = !state.past.length || state.paused;
  $('#redoButton').disabled = !state.future.length || state.paused;
  $('#pauseOverlay').hidden = !state.paused;
  $('#pauseButton').textContent = state.paused ? '▶' : 'Ⅱ';
  $('#pauseButton').setAttribute('aria-label', state.paused ? 'Resume game' : 'Pause game');
  numberPad.querySelectorAll('button').forEach((button) => { button.disabled = state.paused || state.won; });
}

function select(index, focus = false) {
  if (state.paused) return;
  state.selected = index;
  render();
  if (focus) boardEl.children[index]?.focus();
  if (!state.won) announce(state.puzzle[index] ? 'This number is part of the puzzle.' : state.notesMode ? 'Notes are on. Add a possibility.' : 'Choose a number or use your keyboard.');
}

function place(value) {
  const index = state.selected;
  if (index === null || state.paused || state.won) { if (index === null) announce('Select an empty square first.'); return; }
  if (state.puzzle[index]) { announce('Given numbers can’t be changed.'); return; }
  if (state.notesMode && value) {
    record();
    state.values[index] = 0;
    const notes = state.notes[index];
    state.notes[index] = notes.includes(value) ? notes.filter((n) => n !== value) : [...notes, value].sort();
    announce('Note updated.');
  } else {
    if (state.values[index] === value && !state.notes[index].length) return;
    record();
    state.values[index] = value;
    state.notes[index] = [];
    if (value) for (const peer of peers(index)) state.notes[peer] = state.notes[peer].filter((n) => n !== value);
    const conflicts = conflictCells(state.values);
    announce(conflicts.has(index) ? 'That number repeats in this row, column, or box.' : value ? 'Nicely placed.' : 'Square cleared.', conflicts.has(index) ? 'error' : '');
  }
  render(); save(); checkWin();
}

function erase() { if (state.selected === null || state.puzzle[state.selected] || state.paused || state.won) return; place(0); }
function undo() { if (!state.past.length || state.paused) return; state.future.push(snapshot()); applySnapshot(state.past.pop()); announce('Last move undone.'); }
function redo() { if (!state.future.length || state.paused) return; state.past.push(snapshot()); applySnapshot(state.future.pop()); announce('Move restored.'); }

function hint() {
  if (state.paused || state.won) return;
  let index = state.selected;
  if (index === null || state.puzzle[index] || state.values[index] === state.solution[index]) index = state.values.findIndex((value, i) => !state.puzzle[i] && value !== state.solution[i]);
  if (index < 0) { announce('Everything is in place.'); return; }
  record();
  state.values[index] = state.solution[index];
  state.notes[index] = [];
  state.hinted.push(index);
  state.selected = index;
  for (const peer of peers(index)) state.notes[peer] = state.notes[peer].filter((n) => n !== state.solution[index]);
  render(); save(); announce('A little nudge, right there.', 'success'); checkWin();
}

function checkWin() {
  if (!state.values.every((value, index) => value === state.solution[index])) return;
  state.won = true; render(); save(); announce('Puzzle complete. Beautifully done!', 'success');
  $('#winTime').textContent = formatTime(state.seconds);
  $('#winDialog').showModal();
}

function start(level) {
  state = fresh(level);
  save(); render(); announce('A new puzzle is ready. Enjoy the moment.');
}

function askNewGame(level = state.level) {
  pendingLevel = level;
  if (state.won || filledCount() === state.puzzle.filter(Boolean).length) start(level);
  else $('#newGameDialog').showModal();
}

state = restore();
for (let digit = 1; digit <= 9; digit++) {
  const button = document.createElement('button');
  button.type = 'button'; button.textContent = digit; button.setAttribute('aria-label', `Enter ${digit}`);
  button.addEventListener('click', () => place(digit));
  numberPad.append(button);
}
boardEl.addEventListener('click', (event) => { const cell = event.target.closest('.cell'); if (cell) select(Number(cell.dataset.index)); });
$('#newGameButton').addEventListener('click', () => askNewGame());
document.querySelectorAll('[data-level]').forEach((button) => button.addEventListener('click', () => { if (button.dataset.level !== state.level) askNewGame(button.dataset.level); }));
$('#newGameDialog').addEventListener('close', (event) => { if (event.target.returnValue === 'confirm') start(pendingLevel); pendingLevel = null; });
$('#helpButton').addEventListener('click', () => $('#helpDialog').showModal());
$('#winDialog').addEventListener('close', (event) => { if (event.target.returnValue === 'new') start(state.level); });
$('#pauseButton').addEventListener('click', () => { if (state.won) return; state.paused = !state.paused; render(); save(); });
$('#resumeButton').addEventListener('click', () => { state.paused = false; render(); save(); });
$('#undoButton').addEventListener('click', undo);
$('#redoButton').addEventListener('click', redo);
$('#eraseButton').addEventListener('click', erase);
$('#notesButton').addEventListener('click', () => { state.notesMode = !state.notesMode; render(); save(); announce(state.notesMode ? 'Notes are on.' : 'Notes are off.'); });
$('#hintButton').addEventListener('click', hint);
document.addEventListener('keydown', (event) => {
  if (document.querySelector('dialog[open]') || event.altKey) return;
  if ((event.ctrlKey || event.metaKey) && event.key.toLowerCase() === 'z') { event.preventDefault(); event.shiftKey ? redo() : undo(); return; }
  if ((event.ctrlKey || event.metaKey) && event.key.toLowerCase() === 'y') { event.preventDefault(); redo(); return; }
  if (event.ctrlKey || event.metaKey) return;
  if (event.key.toLowerCase() === 'n') { event.preventDefault(); $('#notesButton').click(); return; }
  if (event.key === 'Escape' && state.paused) { state.paused = false; render(); return; }
  if (state.paused) return;
  if (/^[1-9]$/.test(event.key)) { event.preventDefault(); place(Number(event.key)); return; }
  if (event.key === 'Backspace' || event.key === 'Delete' || event.key === '0') { event.preventDefault(); erase(); return; }
  const delta = { ArrowLeft: -1, ArrowRight: 1, ArrowUp: -9, ArrowDown: 9 }[event.key];
  if (delta) { event.preventDefault(); const current = state.selected ?? 0; select(Math.max(0, Math.min(80, current + delta)), true); }
});
setInterval(() => { if (!state.paused && !state.won && !document.hidden) { state.seconds++; $('#timer').textContent = formatTime(state.seconds); $('#sideTime').textContent = formatTime(state.seconds); save(); } }, 1000);
render();
announce(state.won ? 'Puzzle complete. Beautifully done!' : 'Select a square to begin.', state.won ? 'success' : '');
