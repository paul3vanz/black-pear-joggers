import { buildLeaderboard, formatElapsed, formatOrdinal, sortCategoryKeys } from './leaderboard';
import { FinishRow, ParticipantRow, RaceRow } from './types';

// In practice a lapped event is one race row — every lap is a repeat
// direct-entry finish for the same bib within it, not a separate race.
const races: RaceRow[] = [{ id: 'race-1', name: 'The Wild One', created_at: '2026-07-11T09:00:00Z' }];

const participants: ParticipantRow[] = [
  { race_id: 'race-1', bib_number: '1', first_name: 'Alice', last_name: 'Smith', team_name: null, gender: 'F', category: 'Senior', sub_category: 'solo', club: 'Black Pear Joggers' },
  { race_id: 'race-1', bib_number: '2', first_name: null, last_name: null, team_name: 'Team Falcon', gender: null, category: null, sub_category: 'teams', club: null },
  { race_id: 'race-1', bib_number: '3', first_name: 'Bob', last_name: 'Jones', team_name: null, gender: 'M', category: 'V40', sub_category: 'solo', club: null },
  { race_id: 'race-1', bib_number: '4', first_name: 'Carol', last_name: 'Day', team_name: null, gender: 'F', category: 'V40', sub_category: 'solo', club: null },
];

describe('buildLeaderboard', () => {
  it('ranks by laps completed desc, then time asc, within each sub_category', () => {
    const finishes: FinishRow[] = [
      // Bib 1: 2 laps, second lap at 20 min — same race_id both times
      { race_id: 'race-1', bib_number: '1', gun_time: 10 * 60_000 },
      { race_id: 'race-1', bib_number: '1', gun_time: 20 * 60_000 },
      // Bib 3: 2 laps, second lap at 18 min (faster) — should rank above bib 1
      { race_id: 'race-1', bib_number: '3', gun_time: 9 * 60_000 },
      { race_id: 'race-1', bib_number: '3', gun_time: 18 * 60_000 },
      // Team Falcon: only 1 lap so far
      { race_id: 'race-1', bib_number: '2', gun_time: 11 * 60_000 },
    ];

    const result = buildLeaderboard(races, participants, finishes);

    expect(Object.keys(result).sort()).toEqual(['solo', 'teams']);
    expect(result.solo.map((e) => e.bibNumber)).toEqual(['3', '1']);
    expect(result.solo[0].position).toBe(1);
    expect(result.solo[1].position).toBe(2);
    expect(result.solo[0].lapsCompleted).toBe(2);
    expect(result.solo[0].currentTime).toBe(18 * 60_000);
    expect(result.solo[0].lapSplits).toEqual([9 * 60_000, 9 * 60_000]);
    expect(result.solo[0].club).toBeNull(); // Bob (1st) has no club set
    expect(result.solo[1].club).toBe('Black Pear Joggers'); // Alice (2nd) does
    expect(result.teams).toHaveLength(1);
    expect(result.teams[0].displayName).toBe('Team Falcon');
    expect(result.teams[0].lapSplits).toEqual([11 * 60_000]);
    expect(result.teams[0].gender).toBeNull();
    expect(result.teams[0].genderPosition).toBeNull();
  });

  it('treats every repeat finish for the same bib within one race as a separate lap', () => {
    // Matches real usage: no per-lap race rows, just repeat direct-entry
    // finishes against the same race_id as the bib crosses the mat again.
    const finishes: FinishRow[] = [
      { race_id: 'race-1', bib_number: '1', gun_time: 10 * 60_000 },
      { race_id: 'race-1', bib_number: '1', gun_time: 22 * 60_000 },
      { race_id: 'race-1', bib_number: '1', gun_time: 30 * 60_000 },
    ];

    const result = buildLeaderboard(races, participants, finishes);

    expect(result.solo[0].lapsCompleted).toBe(3);
    expect(result.solo[0].lapSplits).toEqual([10 * 60_000, 12 * 60_000, 8 * 60_000]);
    expect(result.solo[0].currentTime).toBe(30 * 60_000);
  });

  it('orders out-of-sequence rows by gun_time rather than insertion order', () => {
    const finishes: FinishRow[] = [
      { race_id: 'race-1', bib_number: '1', gun_time: 30 * 60_000 },
      { race_id: 'race-1', bib_number: '1', gun_time: 10 * 60_000 },
    ];

    const result = buildLeaderboard(races, participants, finishes);

    expect(result.solo[0].lapSplits).toEqual([10 * 60_000, 20 * 60_000]);
    expect(result.solo[0].currentTime).toBe(30 * 60_000);
  });

  it('ranks gender and age-category standings independently within a sub_category', () => {
    const finishes: FinishRow[] = [
      { race_id: 'race-1', bib_number: '1', gun_time: 10 * 60_000 }, // Alice, F, Senior
      { race_id: 'race-1', bib_number: '3', gun_time: 9 * 60_000 }, // Bob, M, V40 — fastest overall
      { race_id: 'race-1', bib_number: '4', gun_time: 11 * 60_000 }, // Carol, F, V40
    ];

    const result = buildLeaderboard(races, participants, finishes);

    // Overall order: Bob (9m), Alice (10m), Carol (11m)
    expect(result.solo.map((e) => e.bibNumber)).toEqual(['3', '1', '4']);

    const bob = result.solo.find((e) => e.bibNumber === '3');
    const alice = result.solo.find((e) => e.bibNumber === '1');
    const carol = result.solo.find((e) => e.bibNumber === '4');

    // Gender: Bob is the only male (1st M); Alice then Carol are 1st/2nd F
    expect(bob.genderPosition).toBe(1);
    expect(alice.genderPosition).toBe(1);
    expect(carol.genderPosition).toBe(2);

    // Age category: Bob and Carol share V40 (Bob faster, 1st/2nd); Alice is
    // the only Senior (1st)
    expect(bob.categoryPosition).toBe(1);
    expect(carol.categoryPosition).toBe(2);
    expect(alice.categoryPosition).toBe(1);
  });

  it('falls back to "Bib N" when no participant roster row exists', () => {
    const finishes: FinishRow[] = [{ race_id: 'race-1', bib_number: '99', gun_time: 5 * 60_000 }];

    const result = buildLeaderboard(races, participants, finishes);

    expect(result['Results']).toHaveLength(1);
    expect(result['Results'][0].displayName).toBe('Bib 99');
    expect(result['Results'][0].genderPosition).toBeNull();
  });

  it('ignores finishes with no gun_time', () => {
    const finishes: FinishRow[] = [{ race_id: 'race-1', bib_number: '1', gun_time: null }];

    const result = buildLeaderboard(races, participants, finishes);

    expect(result).toEqual({});
  });
});

describe('sortCategoryKeys', () => {
  it('orders solo/pairs/teams first, unknown categories alphabetically after', () => {
    expect(sortCategoryKeys(['teams', 'zzz', 'solo', 'pairs'])).toEqual([
      'solo',
      'pairs',
      'teams',
      'zzz',
    ]);
  });
});

describe('formatElapsed', () => {
  it('formats sub-hour durations as MM:SS', () => {
    expect(formatElapsed(9 * 60_000 + 5_000)).toBe('09:05');
  });

  it('formats hour-plus durations as HH:MM:SS', () => {
    expect(formatElapsed(65 * 60_000 + 3_000)).toBe('01:05:03');
  });
});

describe('formatOrdinal', () => {
  it('formats standard ordinals', () => {
    expect(formatOrdinal(1)).toBe('1st');
    expect(formatOrdinal(2)).toBe('2nd');
    expect(formatOrdinal(3)).toBe('3rd');
    expect(formatOrdinal(4)).toBe('4th');
  });

  it('formats the 11th-13th exception correctly', () => {
    expect(formatOrdinal(11)).toBe('11th');
    expect(formatOrdinal(12)).toBe('12th');
    expect(formatOrdinal(13)).toBe('13th');
    expect(formatOrdinal(21)).toBe('21st');
  });
});
