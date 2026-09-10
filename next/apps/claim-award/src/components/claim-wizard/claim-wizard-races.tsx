import {
  Award,
  Performance,
  Standard,
} from '@black-pear-joggers/core-services';
import { classNames, shortUkDate } from '@black-pear-joggers/helpers';
import { useMemo, useState } from 'react';

export type ClaimRaceInput = {
  key: string;
  source: 'performance' | 'manual';
  distance: string;
  date: string;
  race: string;
  time: string;
  timeParsed: number;
  award: string;
};

const ALLOWED_DISTANCES = ['Mile', '5K', '10K', 'Half Marathon', 'Marathon'];

const RAW_EVENT_CODES = [
  '1M',
  'Mile',
  '5K',
  'parkrun',
  '10K',
  '10KMT',
  'HM',
  'HMMT',
  'Mar',
  'MarMT',
];

// Mirrors the same raw-code -> display-distance normalisation already used
// in personal-bests.tsx, since performances come back with PO10-style event
// codes rather than the plain distance names claims/standards use.
function normaliseEventToDistance(event: string): string {
  return event
    .replace('MT', '')
    .replace('1M', 'Mile')
    .replace('parkrun', '5K')
    .replace('Mar', 'Marathon')
    .replace('HM', 'Half Marathon');
}

const AWARD_ORDER = ['Bronze', 'Silver', 'Gold', 'Platinum'];

function computeStandardAward(
  distance: string,
  timeParsedSeconds: number,
  gender: string,
  category: string,
  standards: Standard[]
): string {
  const qualifying = standards
    .filter(
      (standard) =>
        standard.gender === gender &&
        standard.category === category &&
        standard.event === distance
    )
    .filter((standard) => Number(standard.time_parsed) >= timeParsedSeconds)
    .sort(
      (a, b) => AWARD_ORDER.indexOf(b.name) - AWARD_ORDER.indexOf(a.name)
    );

  return qualifying[0]?.name ?? '';
}

function performanceToCandidate(performance: Performance): ClaimRaceInput {
  return {
    key: `performance-${performance.id}`,
    source: 'performance',
    distance: normaliseEventToDistance(performance.event),
    date: performance.date,
    race: performance.meetingName,
    time: performance.time,
    timeParsed: Number(performance.timeParsed),
    award: Award[performance.award] ?? '',
  };
}

export function candidateRacesFromPerformances(
  performances: Performance[],
  category: string
): ClaimRaceInput[] {
  return performances
    .filter(
      (performance) =>
        RAW_EVENT_CODES.includes(performance.event) &&
        performance.category === category &&
        !!performance.award
    )
    .map(performanceToCandidate)
    .sort((a, b) => (a.date < b.date ? 1 : -1));
}

interface ClaimWizardRacesProps {
  gender: string;
  category: string;
  standards: Standard[];
  candidates: ClaimRaceInput[];
  value: ClaimRaceInput[];
  onChange: (races: ClaimRaceInput[]) => void;
}

export function ClaimWizardRaces(props: ClaimWizardRacesProps) {
  const [manualDistance, setManualDistance] = useState(ALLOWED_DISTANCES[0]);
  const [manualDate, setManualDate] = useState('');
  const [manualRaceName, setManualRaceName] = useState('');
  const [manualHours, setManualHours] = useState(0);
  const [manualMinutes, setManualMinutes] = useState(0);
  const [manualSeconds, setManualSeconds] = useState(0);

  const selectedKeys = useMemo(
    () => new Set(props.value.map((race) => race.key)),
    [props.value]
  );

  function toggleCandidate(candidate: ClaimRaceInput) {
    if (selectedKeys.has(candidate.key)) {
      props.onChange(props.value.filter((race) => race.key !== candidate.key));
    } else {
      props.onChange([...props.value, candidate]);
    }
  }

  function removeRace(key: string) {
    props.onChange(props.value.filter((race) => race.key !== key));
  }

  function addManualRace() {
    const timeParsed = manualHours * 3600 + manualMinutes * 60 + manualSeconds;

    if (!manualDate || !manualRaceName || !timeParsed) {
      return;
    }

    const award = computeStandardAward(
      manualDistance,
      timeParsed,
      props.gender,
      props.category,
      props.standards
    );

    props.onChange([
      ...props.value,
      {
        key: `manual-${Date.now()}`,
        source: 'manual',
        distance: manualDistance,
        date: manualDate,
        race: manualRaceName,
        time:
          manualHours > 0
            ? `${manualHours}:${String(manualMinutes).padStart(2, '0')}:${String(
                manualSeconds
              ).padStart(2, '0')}`
            : `${manualMinutes}:${String(manualSeconds).padStart(2, '0')}`,
        timeParsed,
        award,
      },
    ]);

    setManualDate('');
    setManualRaceName('');
    setManualHours(0);
    setManualMinutes(0);
    setManualSeconds(0);
  }

  const distinctDistances = new Set(props.value.map((race) => race.distance));
  const distinctYears = new Set(
    props.value.map((race) => new Date(race.date).getFullYear())
  );

  return (
    <div>
      <h3 className="text-xl font-semibold mb-2">Pick your races</h3>

      {props.candidates.length > 0 ? (
        <>
          <p className="mb-4">
            These are your results in your current category that count
            towards an award. Tick up to one per distance.
          </p>

          <ul className="mb-6 divide-y divide-gray-200">
            {props.candidates.map((candidate) => (
              <li key={candidate.key} className="py-2 flex items-center gap-3">
                <input
                  type="checkbox"
                  id={`candidate-${candidate.key}`}
                  checked={selectedKeys.has(candidate.key)}
                  onChange={() => toggleCandidate(candidate)}
                  className="h-5 w-5"
                />

                <label htmlFor={`candidate-${candidate.key}`} className="flex-1">
                  <strong>{candidate.distance}</strong> &mdash; {candidate.time}{' '}
                  &mdash; {candidate.race} ({shortUkDate(candidate.date)})
                </label>

                <span className="text-sm text-gray-500">{candidate.award}</span>
              </li>
            ))}
          </ul>
        </>
      ) : (
        <p className="mb-4">
          We don&apos;t have any of your results on file for your current
          category yet. Add your races manually below.
        </p>
      )}

      <h4 className="font-semibold mb-2">
        Missing a race? Add it manually
      </h4>

      <div className="flex flex-wrap gap-3 mb-3 items-end">
        <div>
          <label className="block font-bold mb-1" htmlFor="manual-distance">
            Distance
          </label>
          <select
            id="manual-distance"
            className="block border rounded py-3 px-4 h-12"
            value={manualDistance}
            onChange={(e) => setManualDistance(e.target.value)}
          >
            {ALLOWED_DISTANCES.map((distance) => (
              <option key={distance} value={distance}>
                {distance}
              </option>
            ))}
          </select>
        </div>

        <div>
          <label className="block font-bold mb-1" htmlFor="manual-date">
            Date
          </label>
          <input
            id="manual-date"
            type="date"
            className="block border rounded py-3 px-4 h-12"
            value={manualDate}
            onChange={(e) => setManualDate(e.target.value)}
          />
        </div>

        <div>
          <label className="block font-bold mb-1" htmlFor="manual-race-name">
            Race name
          </label>
          <input
            id="manual-race-name"
            type="text"
            className="block border rounded py-3 px-4 h-12"
            value={manualRaceName}
            onChange={(e) => setManualRaceName(e.target.value)}
          />
        </div>

        <div>
          <span className="block font-bold mb-1">Finish time</span>
          <div className="flex gap-1">
            <input
              aria-label="Hours"
              title="Hours"
              type="number"
              min={0}
              className="block border rounded py-3 px-2 h-12 w-16"
              value={manualHours}
              onChange={(e) => setManualHours(Number(e.target.value))}
            />
            <input
              aria-label="Minutes"
              title="Minutes"
              type="number"
              min={0}
              max={59}
              className="block border rounded py-3 px-2 h-12 w-16"
              value={manualMinutes}
              onChange={(e) => setManualMinutes(Number(e.target.value))}
            />
            <input
              aria-label="Seconds"
              title="Seconds"
              type="number"
              min={0}
              max={59}
              className="block border rounded py-3 px-2 h-12 w-16"
              value={manualSeconds}
              onChange={(e) => setManualSeconds(Number(e.target.value))}
            />
          </div>
        </div>

        <button
          type="button"
          className="underline font-bold h-12"
          onClick={addManualRace}
        >
          Add race
        </button>
      </div>

      {props.value.filter((race) => race.source === 'manual').length > 0 && (
        <ul className="mb-6 divide-y divide-gray-200">
          {props.value
            .filter((race) => race.source === 'manual')
            .map((race) => (
              <li key={race.key} className="py-2 flex items-center gap-3">
                <span className="flex-1">
                  <strong>{race.distance}</strong> &mdash; {race.time} &mdash;{' '}
                  {race.race} ({shortUkDate(race.date)})
                </span>

                <span className="text-sm text-gray-500">
                  {race.award || 'No standard met'}
                </span>

                <button
                  type="button"
                  className="underline"
                  onClick={() => removeRace(race.key)}
                >
                  Remove
                </button>
              </li>
            ))}
        </ul>
      )}

      <div
        className={classNames(
          'p-4',
          distinctDistances.size >= 3 && distinctYears.size <= 1
            ? 'bg-teal-100'
            : 'bg-orange-100'
        )}
      >
        {distinctDistances.size < 3 && (
          <p className="mb-0">
            Pick at least 3 different distances ({distinctDistances.size} of 3
            so far).
          </p>
        )}

        {distinctDistances.size >= 3 && distinctYears.size > 1 && (
          <p className="mb-0">
            All races must be from the same calendar year &mdash; you&apos;ve
            picked races from {distinctYears.size} different years.
          </p>
        )}

        {distinctDistances.size >= 3 && distinctYears.size <= 1 && (
          <p className="mb-0">You&apos;re good to go &mdash; continue below.</p>
        )}
      </div>
    </div>
  );
}

export function racesAreValid(races: ClaimRaceInput[]): boolean {
  const distinctDistances = new Set(races.map((race) => race.distance));
  const distinctYears = new Set(
    races.map((race) => new Date(race.date).getFullYear())
  );

  return distinctDistances.size >= 3 && distinctYears.size <= 1;
}

export function computeClaimAward(races: ClaimRaceInput[]): string {
  const ordered = [...races]
    .filter((race) => AWARD_ORDER.includes(race.award))
    .sort((a, b) => AWARD_ORDER.indexOf(b.award) - AWARD_ORDER.indexOf(a.award));

  return ordered[2]?.award ?? '';
}
