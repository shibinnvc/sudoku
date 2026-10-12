import test from 'node:test';
import assert from 'node:assert/strict';
import { LEVELS, generatePuzzle, countSolutions, conflictCells, candidates } from '../dist/core.js';

for (const level of Object.keys(LEVELS)) {
  test(`${level} puzzle has one valid solution and an appropriate clue count`, () => {
    const { puzzle, solution } = generatePuzzle(level);
    assert.equal(puzzle.length, 81);
    assert.equal(countSolutions(puzzle), 1);
    assert.ok(puzzle.filter(Boolean).length >= LEVELS[level].clues);
    assert.ok(puzzle.filter(Boolean).length <= LEVELS[level].clues + 6);
    for (let index = 0; index < 81; index++) {
      if (puzzle[index]) assert.equal(puzzle[index], solution[index]);
    }
    assert.equal(conflictCells(solution).size, 0);
  });
}

test('candidates exclude row, column, and box values', () => {
  const board = Array(81).fill(0);
  board[1] = 1; board[9] = 2; board[10] = 3;
  assert.deepEqual(candidates(board, 0), [4, 5, 6, 7, 8, 9]);
});
