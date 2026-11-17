import { useEffect, useRef, useState } from 'react';
import { LEVELS, conflictCells, formatTime, peers } from './core.js';
import { createGame, hasConflict, hint, loadSession, place, recordFor, saveSession, travel } from './game.js';

function Icon({ name, size = 20 }) {
  const paths = {
    arrow: <><path d="M19 12H5m7 7-7-7 7-7" /></>,
    plus: <path d="M12 5v14M5 12h14" />,
    history: <><path d="M3 12a9 9 0 1 0 3-6.7L3 8" /><path d="M3 3v5h5M12 7v5l3 2" /></>,
    chevron: <path d="m9 18 6-6-6-6" />,
    clock: <><circle cx="12" cy="12" r="9" /><path d="M12 7v5l3 2" /></>,
    pause: <><path d="M9 5v14M15 5v14" /></>,
    play: <path d="m8 5 11 7-11 7z" />,
    undo: <><path d="M9 14 4 9l5-5M4 9h9a7 7 0 0 1 0 14" /></>,
    redo: <><path d="m15 14 5-5-5-5M20 9h-9a7 7 0 0 0 0 14" /></>,
    erase: <><path d="m3 15 9-10a2 2 0 0 1 3 0l6 6a2 2 0 0 1 0 3l-6 7H9zM9 21l-5-5M12 18h7" /></>,
    notes: <><path d="M5 3h10l4 4v14H5zM15 3v5h4M8 12h8M8 16h6" /></>,
    hint: <><path d="M9 18h6m-5 3h4M9 15c-1-1-3-3-3-6a6 6 0 0 1 12 0c0 3-2 5-3 6z" /></>,
    help: <><circle cx="12" cy="12" r="9" /><path d="M9.5 9a2.5 2.5 0 1 1 4 2c-1 .7-1.5 1.3-1.5 2.5M12 17h.01" /></>,
    spark: <path d="m12 2 1.8 7.2L21 11l-7.2 1.8L12 20l-1.8-7.2L3 11l7.2-1.8z" />,
  };
  return <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">{paths[name]}</svg>;
}

function Logo() {
  return <span className="logo-mark" aria-hidden="true">{Array.from({ length: 9 }, (_, i) => <span key={i} className={i === 4 ? 'logo-center' : ''} />)}</span>;
}

function Header({ onHelp }) {
  return <header className="brand-row"><div className="brand"><Logo /><span>Chachu's sudoku</span></div><button className="icon-button" onClick={onHelp} aria-label="How to play"><Icon name="help" /></button></header>;
}

function Label({ children }) { return <div className="eyebrow">{children}</div>; }

function Modal({ title, children, actions, onClose }) {
  const first = useRef(null);
  useEffect(() => { first.current?.focus(); }, []);
  return <div className="modal-backdrop" onMouseDown={(event) => { if (event.target === event.currentTarget) onClose(); }}>
    <section className="modal" role="dialog" aria-modal="true" aria-labelledby="modal-title">
      <div className="modal-spark"><Icon name="spark" size={24} /></div>
      <h2 id="modal-title">{title}</h2><p>{children}</p>
      <div className="modal-actions">{actions.map((action, i) => <button key={action.label} ref={i === 0 ? first : undefined} className={action.primary ? 'button primary' : 'button secondary'} onClick={action.onClick}>{action.label}</button>)}</div>
    </section>
  </div>;
}

const descriptions = { easy: 'A gentle place to begin.', medium: 'A balanced challenge.', hard: 'For a deeper focus.' };
const levelSymbols = { easy: '✿', medium: '◈', hard: '✦' };

function Board({ game, onSelect, cellRefs }) {
  const selected = game.selected;
  const selectedValue = selected == null ? 0 : game.values[selected];
  const related = selected == null ? new Set() : new Set(peers(selected));
  const conflicts = conflictCells(game.values);
  return <div className="board-wrap">
    <div className="board" role="grid" aria-label={`${LEVELS[game.level].label} Sudoku puzzle`}>
      {game.values.map((value, index) => {
        const classes = ['cell'];
        if (game.puzzle[index]) classes.push('given');
        if (related.has(index)) classes.push('related');
        if (selectedValue && value === selectedValue && selected !== index) classes.push('same-number');
        if (selected === index) classes.push('selected');
        if (conflicts.has(index)) classes.push('conflict');
        if (game.hinted.includes(index)) classes.push('hinted');
        if (index % 9 === 2 || index % 9 === 5) classes.push('box-right');
        if (Math.floor(index / 9) === 2 || Math.floor(index / 9) === 5) classes.push('box-bottom');
        const label = `Row ${Math.floor(index / 9) + 1}, column ${index % 9 + 1}: ${value || (game.notes[index].length ? `notes ${game.notes[index].join(', ')}` : 'empty')}${game.puzzle[index] ? ', given' : ''}`;
        return <button key={index} ref={(node) => { cellRefs.current[index] = node; }} type="button" role="gridcell" aria-label={label} aria-selected={selected === index} tabIndex={index === (selected ?? 0) ? 0 : -1} className={classes.join(' ')} onClick={() => onSelect(index)}>
          {value || (game.notes[index].length > 0 && <span className="cell-notes">{Array.from({ length: 9 }, (_, n) => <span key={n}>{game.notes[index].includes(n + 1) ? n + 1 : ''}</span>)}</span>)}
        </button>;
      })}
    </div>
    {game.paused && <div className="pause-overlay"><Icon name="pause" size={30} /><strong>Take a breath.</strong><span>Your puzzle will be here.</span></div>}
  </div>;
}

export default function App() {
  const [session, setSession] = useState(loadSession);
  const [page, setPage] = useState('home');
  const [levelBack, setLevelBack] = useState('home');
  const [dialog, setDialog] = useState(null);
  const [message, setMessage] = useState('Select a square to begin.');
  const cellRefs = useRef([]);
  const game = session.active;

  useEffect(() => { saveSession(session); }, [session]);
  useEffect(() => {
    if (page !== 'game') return undefined;
    const timer = window.setInterval(() => {
      if (document.hidden) return;
      setSession((current) => current.active && !current.active.paused && !current.active.won
        ? { ...current, active: { ...current.active, seconds: current.active.seconds + 1 } } : current);
    }, 1000);
    return () => window.clearInterval(timer);
  }, [page]);

  function openLevels(from) { setLevelBack(from); setPage('levels'); }
  function start(level) {
    setSession((current) => {
      const history = current.active && !current.active.won && !current.active.archived
        ? [recordFor(current.active, false), ...current.history].slice(0, 100) : current.history;
      return { active: createGame(level), history };
    });
    setMessage('Select a square to begin.'); setDialog(null); setPage('game');
  }
  function requestStart(level) {
    if (game && !game.won && !game.archived) setDialog({ type: 'replace', level });
    else start(level);
  }
  function updateGame(change, feedback) {
    setSession((current) => {
      if (!current.active) return current;
      const next = change(current.active);
      if (next === current.active) return current;
      const finished = next.won && !current.active.won && !next.archived;
      return { active: finished ? { ...next, archived: true } : next,
        history: finished ? [recordFor(next, true), ...current.history].slice(0, 100) : current.history };
    });
    if (feedback) setMessage(feedback);
  }
  function enter(value) {
    if (!game || game.selected == null) { setMessage('Select an empty square first.'); return; }
    if (game.puzzle[game.selected]) { setMessage('Given numbers cannot be changed.'); return; }
    updateGame((current) => place(current, value), value === 0 ? 'Square cleared.' : game.notesMode ? 'Note updated.' : 'Number placed.');
  }
  function select(index, focus = false) {
    if (!game || game.paused) return;
    updateGame((current) => ({ ...current, selected: index }));
    setMessage(game.puzzle[index] ? 'This number is part of the puzzle.' : game.notesMode ? 'Add a possibility.' : 'Choose a number.');
    if (focus) cellRefs.current[index]?.focus();
  }
  useEffect(() => {
    if (page !== 'game' || dialog) return undefined;
    function onKey(event) {
      if (event.altKey || ['INPUT', 'TEXTAREA'].includes(document.activeElement?.tagName)) return;
      if ((event.metaKey || event.ctrlKey) && event.key.toLowerCase() === 'z') { event.preventDefault(); updateGame((current) => travel(current, event.shiftKey ? 'redo' : 'undo')); return; }
      if ((event.metaKey || event.ctrlKey) && event.key.toLowerCase() === 'y') { event.preventDefault(); updateGame((current) => travel(current, 'redo')); return; }
      if (event.metaKey || event.ctrlKey) return;
      if (/^[1-9]$/.test(event.key)) { event.preventDefault(); enter(Number(event.key)); return; }
      if (['Backspace', 'Delete', '0'].includes(event.key)) { event.preventDefault(); enter(0); return; }
      if (event.key.toLowerCase() === 'n') { event.preventDefault(); updateGame((current) => ({ ...current, notesMode: !current.notesMode })); return; }
      const delta = { ArrowLeft: -1, ArrowRight: 1, ArrowUp: -9, ArrowDown: 9 }[event.key];
      if (delta) { event.preventDefault(); select(Math.max(0, Math.min(80, (game?.selected ?? 0) + delta)), true); }
    }
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  });

  const filled = game?.values.filter(Boolean).length ?? 0;
  const initialClues = game?.puzzle.filter(Boolean).length ?? 0;
  const progress = game ? Math.round((filled / 81) * 100) : 0;

  return <div className={`app-shell page-${page}`}>
    {page === 'home' && <main className="home-layout">
      <div className="home-main"><Header onHelp={() => setDialog({ type: 'help' })} />
        <section className="intro"><Label>A LITTLE ROOM TO THINK</Label><h1>Find your <em>flow.</em></h1><p>One square at a time. Enjoy the puzzle.</p></section>
        {game && !game.won && <section className="continue-section"><Label>CONTINUE WHERE YOU LEFT OFF</Label><button className="continue-card" onClick={() => setPage('game')}><span className="continue-art" aria-hidden="true">{[1, 0, 7, 0, 5, 0, 9, 0, 3].map((n, i) => <span key={i}>{n || ''}</span>)}</span><span className="continue-info"><strong>{LEVELS[game.level].label} puzzle</strong><small>{filled} of 81 cells filled · {formatTime(game.seconds)}</small><span className="continue-link">Continue game <Icon name="chevron" size={16} /></span></span></button></section>}
        <section className="home-actions"><Label>YOUR NEXT MOVE</Label><button className="button primary wide" onClick={() => openLevels('home')}><Icon name="plus" />New game</button><button className="button secondary wide" onClick={() => setPage('history')}><Icon name="history" />Game history</button></section>
        <p className="home-note">✦ &nbsp; Take your time. The grid will wait for you.</p>
      </div>
      <aside className="home-decor" aria-hidden="true"><div className="decor-orbit orbit-one" /><div className="decor-orbit orbit-two" /><div className="decor-card"><div className="decor-grid">{[0, 4, 0, 7, 0, 2, 0, 9, 0, 0, 8, 0, 1, 0, 5, 0, 0, 6, 0, 0, 3, 4, 0, 0, 2, 0, 0, 6, 0, 5, 0, 0, 9, 0, 3, 0].map((n, i) => <span key={i} className={i === 16 ? 'decor-selected' : ''}>{n || ''}</span>)}</div><div className="decor-caption"><span>Today feels like a good day to solve something.</span><span>✦</span></div></div></aside>
    </main>}

    {page === 'levels' && <main className="simple-page"><div className="top-row"><button className="icon-button back-button" onClick={() => setPage(levelBack)} aria-label="Back"><Icon name="arrow" /></button><span className="top-brand"><Logo /> Chachu's sudoku</span></div><div className="simple-content"><Label>NEW GAME</Label><h1>Choose your <em>pace.</em></h1><p className="page-subtitle">Pick a difficulty that feels right today.</p><div className="level-list">{Object.keys(LEVELS).map((level) => <button key={level} className="level-card" onClick={() => requestStart(level)}><span className="level-icon">{levelSymbols[level]}</span><span><strong>{LEVELS[level].label}</strong><small>{descriptions[level]}</small></span><Icon name="chevron" /></button>)}</div></div><p className="simple-footnote">Every puzzle has one unique solution.</p></main>}

    {page === 'history' && <main className="simple-page"><div className="top-row"><button className="icon-button back-button" onClick={() => setPage('home')} aria-label="Back"><Icon name="arrow" /></button><span className="top-brand"><Logo /> Chachu's sudoku</span></div><div className="simple-content"><Label>YOUR JOURNEY</Label><h1>Game <em>history.</em></h1><p className="page-subtitle">A little record of the time you made for yourself.</p>{session.history.length ? <div className="history-list">{session.history.map((record, i) => <div className="history-card" key={`${record.endedAt}-${i}`}><span className={`history-icon ${record.completed ? 'complete' : ''}`}>{record.completed ? '✦' : '◷'}</span><span className="history-info"><strong>{LEVELS[record.level].label} puzzle</strong><small>{new Date(record.endedAt).toLocaleDateString(undefined, { month: 'short', day: 'numeric', year: 'numeric' })} · {formatTime(record.seconds)}</small></span><span className={`status-pill ${record.completed ? 'complete' : ''}`}>{record.completed ? 'Completed' : `${record.filled}/81 filled`}</span></div>)}</div> : <div className="empty-history"><div>✦</div><strong>Your story starts here.</strong><p>Finished and unfinished games will appear here.</p><button className="button primary" onClick={() => openLevels('history')}>Start a game</button></div>}</div></main>}

    {page === 'game' && game && <main className="game-page"><div className="game-top"><button className="icon-button" onClick={() => setPage('home')} aria-label="Home"><Icon name="arrow" /></button><div className="game-top-actions"><button className="icon-button" onClick={() => openLevels('game')} aria-label="New game"><Icon name="plus" /></button><button className="icon-button" onClick={() => setDialog({ type: 'help' })} aria-label="How to play"><Icon name="help" /></button></div></div><section className="game-card"><div className="game-meta"><span className="level-pill">{LEVELS[game.level].label}</span><span className="game-time"><Icon name="clock" size={17} />{formatTime(game.seconds)}<button className="icon-button small" onClick={() => updateGame((current) => ({ ...current, paused: !current.paused }))} aria-label={game.paused ? 'Resume game' : 'Pause game'}><Icon name={game.paused ? 'play' : 'pause'} size={17} /></button></span></div><Board game={game} onSelect={select} cellRefs={cellRefs} /><p className={`game-message ${hasConflict(game) ? 'error' : ''}`} role="status">{game.won ? 'Puzzle complete. Beautifully done!' : hasConflict(game) ? 'That number repeats in this row, column, or box.' : message}</p><div className="tool-row"><button className="tool-button" disabled={!game.past.length || game.paused || game.won} onClick={() => updateGame((current) => travel(current, 'undo'), 'Last move undone.')}><Icon name="undo" /><span>Undo</span></button><button className="tool-button" disabled={!game.future.length || game.paused || game.won} onClick={() => updateGame((current) => travel(current, 'redo'), 'Move restored.')}><Icon name="redo" /><span>Redo</span></button><button className="tool-button" disabled={game.paused || game.won} onClick={() => enter(0)}><Icon name="erase" /><span>Erase</span></button><button className={`tool-button ${game.notesMode ? 'active' : ''}`} disabled={game.paused || game.won} aria-pressed={game.notesMode} onClick={() => updateGame((current) => ({ ...current, notesMode: !current.notesMode }), game.notesMode ? 'Notes are off.' : 'Notes are on.')}><Icon name="notes" /><span>Notes <b>{game.notesMode ? 'On' : 'Off'}</b></span></button><button className="tool-button" disabled={game.paused || game.won} onClick={() => updateGame(hint, 'A little nudge, right there.')}><Icon name="hint" /><span>Hint</span></button></div></section><div className="number-pad">{Array.from({ length: 9 }, (_, i) => <button key={i} disabled={game.paused || game.won} aria-label={`Enter ${i + 1}`} onClick={() => enter(i + 1)}>{i + 1}</button>)}</div><div className="game-progress"><div><span>YOUR PROGRESS</span><strong>{filled} <small>/ 81</small></strong></div><div className="progress-track"><span style={{ width: `${progress}%` }} /></div><p>{game.won ? 'A beautiful finish. Well done.' : filled > 65 ? 'So close. Keep going.' : filled > initialClues ? 'You are finding your rhythm.' : 'A fresh start. You have got this.'}</p></div></main>}

    {dialog?.type === 'replace' && <Modal title="Start something fresh?" onClose={() => setDialog(null)} actions={[{ label: 'Keep playing', onClick: () => setDialog(null) }, { label: 'New puzzle', primary: true, onClick: () => start(dialog.level) }]}>Your current game will move to History as unfinished.</Modal>}
    {dialog?.type === 'help' && <Modal title="How to play" onClose={() => setDialog(null)} actions={[{ label: 'Got it', primary: true, onClick: () => setDialog(null) }]}>Fill each row, column, and 3 × 3 box with the numbers 1 through 9. Tap a square, then choose a number. Use Notes to pencil in possibilities, or Hint when you need a nudge.</Modal>}
  </div>;
}
