export const LEVELS = {
  easy: { label: 'Easy', clues: 40 },
  medium: { label: 'Medium', clues: 34 },
  hard: { label: 'Hard', clues: 29 },
};

const range = (n) => Array.from({ length: n }, (_, i) => i);
const shuffle = (items) => {
  const copy = [...items];
  for (let i = copy.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [copy[i], copy[j]] = [copy[j], copy[i]];
  }
  return copy;
};

export function peers(index) {
  const row = Math.floor(index / 9), col = index % 9;
  const out = new Set();
  for (let n = 0; n < 9; n++) {
    out.add(row * 9 + n);
    out.add(n * 9 + col);
    out.add((Math.floor(row / 3) * 3 + Math.floor(n / 3)) * 9 + Math.floor(col / 3) * 3 + n % 3);
  }
  out.delete(index);
  return [...out];
}

export function candidates(board, index) {
  if (board[index]) return [];
  const used = new Set(peers(index).map((peer) => board[peer]));
  return range(9).map((i) => i + 1).filter((value) => !used.has(value));
}

export function countSolutions(board, limit = 2) {
  const work = [...board];
  let count = 0;
  function visit() {
    if (count >= limit) return;
    let target = -1, options = null;
    for (let i = 0; i < 81; i++) {
      if (work[i]) continue;
      const next = candidates(work, i);
      if (!next.length) return;
      if (!options || next.length < options.length) {
        target = i; options = next;
        if (next.length === 1) break;
      }
    }
    if (target === -1) { count++; return; }
    for (const value of options) {
      work[target] = value;
      visit();
      work[target] = 0;
      if (count >= limit) return;
    }
  }
  visit();
  return count;
}

function makeSolution() {
  const bands = shuffle(range(3));
  const rows = bands.flatMap((band) => shuffle(range(3)).map((offset) => band * 3 + offset));
  const stacks = shuffle(range(3));
  const cols = stacks.flatMap((stack) => shuffle(range(3)).map((offset) => stack * 3 + offset));
  const digits = shuffle(range(9).map((i) => i + 1));
  return rows.flatMap((row) => cols.map((col) => digits[(row * 3 + Math.floor(row / 3) + col) % 9]));
}

export function generatePuzzle(level = 'easy') {
  const target = LEVELS[level]?.clues ?? LEVELS.easy.clues;
  // Several randomized passes improve the chance of reaching the clue target.
  for (let attempt = 0; attempt < 5; attempt++) {
    const solution = makeSolution();
    const puzzle = [...solution];
    for (const index of shuffle(range(81))) {
      if (puzzle.filter(Boolean).length <= target) break;
      const previous = puzzle[index];
      puzzle[index] = 0;
      if (countSolutions(puzzle) !== 1) puzzle[index] = previous;
    }
    if (puzzle.filter(Boolean).length <= target) return { puzzle, solution };
  }
  // This is rare for hard puzzles; still return a uniquely solvable board.
  const solution = makeSolution(), puzzle = [...solution];
  for (const index of shuffle(range(81))) {
    if (puzzle.filter(Boolean).length <= target) break;
    const previous = puzzle[index];
    puzzle[index] = 0;
    if (countSolutions(puzzle) !== 1) puzzle[index] = previous;
  }
  return { puzzle, solution };
}

export function conflictCells(board) {
  const conflicts = new Set();
  for (let i = 0; i < 81; i++) {
    if (!board[i]) continue;
    for (const peer of peers(i)) {
      if (board[peer] === board[i]) { conflicts.add(i); conflicts.add(peer); }
    }
  }
  return conflicts;
}

export function formatTime(seconds) {
  return `${String(Math.floor(seconds / 60)).padStart(2, '0')}:${String(seconds % 60).padStart(2, '0')}`;
}
