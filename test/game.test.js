import test from 'node:test';
import assert from 'node:assert/strict';
import { createGame, hint, place, travel, validGame } from '../src/game.js';

test('a move, undo, redo, and hint keep puzzle state consistent', () => {
  const original = createGame('easy');
  assert.ok(validGame(original));
  const index = original.puzzle.findIndex((value) => value === 0);
  const selected = { ...original, selected: index };
  const entered = place(selected, selected.solution[index]);
  assert.equal(entered.values[index], selected.solution[index]);
  assert.equal(selected.values[index], 0);
  assert.equal(travel(entered, 'undo').values[index], 0);
  assert.equal(travel(travel(entered, 'undo'), 'redo').values[index], selected.solution[index]);
  const assisted = hint(selected);
  assert.equal(assisted.values[index], selected.solution[index]);
  assert.ok(assisted.hinted.includes(index));
});
