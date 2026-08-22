import Link from 'next/link';
import { Athlete } from '@black-pear-joggers/core-services';
import { Button } from '@black-pear-joggers/button';
import { friendlyDate, powerOfTenAthleteUrl } from '@black-pear-joggers/helpers';
import { formatGender } from '../helpers/formatters';
import { Pill } from '@black-pear-joggers/ui/atoms/pill';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import {
  faArrowUpRightFromSquare,
  faCheckCircle,
  faExclamationCircle,
  faHourglassHalf,
  faPersonRunning,
  faSpinner,
  faTimesCircle,
  faTrophy,
} from '@fortawesome/free-solid-svg-icons';
import { useState } from 'react';
import { describeFetch, fetchAthlete } from '../services/power-of-ten';
import { FetchAthleteResult } from '../types/power-of-ten';

/**
 * A quiet link out to someone's Power of 10 profile, where we know it.
 *
 * Most members are matched but not all, and the old integer athlete id builds
 * nothing on the rebuilt site, so an unmatched member gets no link rather than
 * one that goes nowhere.
 */
function PowerOfTenLink(props: { guid?: string | null }) {
  const url = powerOfTenAthleteUrl(props.guid);

  if (!url) {
    return null;
  }

  return (
    <a
      className="ml-2 text-gray-400 hover:text-gray-700"
      href={url}
      target="_blank"
      rel="noopener noreferrer"
      title="Power of 10 profile"
    >
      <FontAwesomeIcon icon={faArrowUpRightFromSquare} size="xs" />
    </a>
  );
}

/**
 * Where one athlete has got to in a bulk fetch. Nothing at all until they are
 * part of a run, so a table nobody has fetched looks as it always did.
 */
function FetchOutcome(props: {
  result?: FetchAthleteResult;
  isRunning: boolean;
  isQueued: boolean;
}) {
  if (props.isRunning) {
    return (
      <FontAwesomeIcon className="text-gray-500" icon={faSpinner} spin title="Fetching" />
    );
  }

  if (props.isQueued) {
    return (
      <FontAwesomeIcon className="text-gray-300" icon={faHourglassHalf} title="Waiting" />
    );
  }

  if (!props.result) {
    return null;
  }

  return props.result.success ? (
    <FontAwesomeIcon
      className="text-green-600"
      icon={faCheckCircle}
      title={describeFetch(props.result)}
    />
  ) : (
    <FontAwesomeIcon
      className="text-red-600"
      icon={faTimesCircle}
      title={describeFetch(props.result)}
    />
  );
}

interface AthletesTableProps {
  search: string;
  athletes: Athlete[];
}

function hasOutstandingPayment(athlete: Athlete): boolean {
  if (!athlete.payments) {
    return false;
  }

  return athlete.payments[0]?.paymentStatus === 'Requested';
}

function paymentDescription(athlete: Athlete): string {
  if (!athlete.payments) {
    return '';
  }

  if (hasOutstandingPayment(athlete)) {
    return 'Payment requested';
  }

  return `Paid (${friendlyDate(athlete.payments[0]?.datePaid)})`;
}

function AthletesTable(props: AthletesTableProps) {
  const [statusFilter, setStatusFilter] = useState<string | null>('active');
  const [affiliatedFilter, setAffiliatedFilter] = useState<string | null>(null);
  const [selected, setSelected] = useState<number[]>([]);
  const [results, setResults] = useState<Record<number, FetchAthleteResult>>({});
  const [queued, setQueued] = useState<number[]>([]);
  const [running, setRunning] = useState<number | null>(null);

  function toggle(athleteId: number) {
    setSelected((current) =>
      current.includes(athleteId)
        ? current.filter((id) => id !== athleteId)
        : [...current, athleteId]
    );
  }

  /**
   * Fetch the selected athletes one at a time.
   *
   * Each one is a scrape of somebody else's site, so they go in single file
   * rather than all at once.
   */
  async function fetchSelected(athleteIds: number[]) {
    setQueued(athleteIds);

    for (const athleteId of athleteIds) {
      setRunning(athleteId);

      try {
        const result = await fetchAthlete(athleteId);
        setResults((current) => ({ ...current, [athleteId]: result }));
      } catch (error) {
        setResults((current) => ({
          ...current,
          [athleteId]: {
            success: false,
            athleteId,
            name: null,
            message: error instanceof Error ? error.message : 'Failed',
            performances: null,
            rankings: null,
          } as unknown as FetchAthleteResult,
        }));
      }

      setQueued((current) => current.filter((id) => id !== athleteId));
    }

    setRunning(null);
  }

  const filteredAthletes = (
    props.search
      ? props.athletes.filter((athlete) => {
          const search = props.search.toLowerCase();
          const name =
            `${athlete.first_name} ${athlete.last_name}`.toLowerCase();

          return name.includes(search);
        })
      : props.athletes
  )
    .filter((athlete) =>
      statusFilter
        ? statusFilter === 'active'
          ? athlete.active
          : statusFilter === 'paid'
          ? athlete.active && !hasOutstandingPayment(athlete)
          : statusFilter === 'requested'
          ? !athlete.active && hasOutstandingPayment(athlete)
          : true
        : true
    )
    .filter((athlete) =>
      affiliatedFilter
        ? affiliatedFilter === 'affiliated'
          ? athlete.affiliated
          : affiliatedFilter === 'basic'
          ? !athlete.affiliated
          : true
        : true
    )
    .sort((a, b) => {
      const result = a.first_name.localeCompare(b.first_name);

      return result !== 0 ? result : a.last_name.localeCompare(b.last_name);
    });

  const selectableIds = filteredAthletes.map((athlete) => athlete.athlete_id);
  const allSelected =
    selectableIds.length > 0 && selectableIds.every((id) => selected.includes(id));
  const finished = Object.values(results);

  return (
    <>
      <p>
        <strong>{filteredAthletes.length}</strong> athletes
      </p>

      <p>
        <strong>Status</strong>
        <Pill
          onClick={() => setStatusFilter(null)}
          active={!statusFilter}
          text="All"
        />

        <Pill
          onClick={() => setStatusFilter('active')}
          active={statusFilter === 'active'}
          text="Active"
        />

        <Pill
          onClick={() => setStatusFilter('paid')}
          active={statusFilter === 'paid'}
          text="Paid up"
        />

        <Pill
          onClick={() => {
            setStatusFilter('requested');
            setAffiliatedFilter(null);
          }}
          active={statusFilter === 'requested'}
          text="Payment requested"
        />
      </p>

      {statusFilter !== 'requested' ? (
        <p>
          <strong>Affiliation</strong>

          <Pill
            onClick={() => setAffiliatedFilter(null)}
            active={!affiliatedFilter}
            text="All"
          />

          <Pill
            onClick={() => setAffiliatedFilter('affiliated')}
            active={affiliatedFilter === 'affiliated'}
            text="Affiliated"
          />

          <Pill
            onClick={() => setAffiliatedFilter('basic')}
            active={affiliatedFilter === 'basic'}
            text="Basic or second claim"
          />
        </p>
      ) : null}

      <p className="flex flex-wrap items-center gap-3">
        <Button
          text={
            allSelected ? 'Clear selection' : `Select all ${selectableIds.length}`
          }
          size="sm"
          onClick={() => setSelected(allSelected ? [] : selectableIds)}
        />

        {selected.length > 0 && (
          <>
            <Button
              text={
                running
                  ? `Fetching ${selected.length - queued.length} of ${selected.length}...`
                  : `Fetch ${selected.length} from Power of 10`
              }
              size="sm"
              onClick={() => (running ? undefined : fetchSelected(selected))}
            />
            <span className="text-sm text-gray-600">
              one at a time, roughly {Math.ceil(selected.length * 2)} seconds
            </span>
          </>
        )}

        {finished.length > 0 && (
          <span className="text-sm text-gray-600">
            {finished.filter((result) => result.success).length} done,{' '}
            {finished.filter((result) => !result.success).length} failed
          </span>
        )}
      </p>

      <table className="w-full">
        <thead className="divide-y divide-gray-200">
          <tr>
            <th className="px-4 py-2">
              <span className="sr-only">Select</span>
            </th>
            <th className="px-4 py-2">Active</th>
            <th className="px-4 py-2">Affiliation</th>
            <th className="px-4 py-2">Name</th>
            <th className="px-4 py-2">Gender</th>
            <th className="px-4 py-2">Category</th>
            <th className="px-4 py-2 hidden md:table-cell">Created</th>
            <th className="px-4 py-2 hidden md:table-cell">Paid</th>
          </tr>
        </thead>
        <tbody className="divide-y divide-gray-200">
          {filteredAthletes.map((athlete, index) => (
            <tr
              key={athlete.id}
              className={index % 2 === 0 ? 'bg-gray-100' : ''}
            >
              <td className="px-4 py-2 whitespace-nowrap">
                <input
                  type="checkbox"
                  aria-label={`Select ${athlete.first_name} ${athlete.last_name}`}
                  checked={selected.includes(athlete.athlete_id)}
                  onChange={() => toggle(athlete.athlete_id)}
                />
                <span className="ml-2 inline-block w-4">
                  <FetchOutcome
                    result={results[athlete.athlete_id]}
                    isRunning={running === athlete.athlete_id}
                    isQueued={queued.includes(athlete.athlete_id)}
                  />
                </span>
              </td>
              <td className="px-4 py-2">
                {hasOutstandingPayment(athlete) ? (
                  <FontAwesomeIcon
                    className="text-yellow-400"
                    size="lg"
                    title={paymentDescription(athlete)}
                    icon={faExclamationCircle}
                  />
                ) : athlete.active ? (
                  <FontAwesomeIcon
                    className="text-green-600"
                    size="lg"
                    title={paymentDescription(athlete)}
                    icon={faCheckCircle}
                  />
                ) : (
                  <FontAwesomeIcon
                    className="text-gray-300"
                    size="lg"
                    title="Lapsed"
                    icon={faTimesCircle}
                  />
                )}
              </td>
              <td className="px-4 py-2">
                {athlete.active || hasOutstandingPayment(athlete) ? (
                  athlete.affiliated ? (
                    <>
                      {' '}
                      <FontAwesomeIcon
                        className="text-green-600"
                        size="lg"
                        title="Affiliated"
                        icon={faTrophy}
                      />
                    </>
                  ) : (
                    <FontAwesomeIcon
                      className="text-gray-300"
                      size="lg"
                      title="Basic or second claim"
                      icon={faTrophy}
                    />
                  )
                ) : null}
              </td>
              <td className="px-4 py-2">
                <Link href={`/athletes/${athlete.athlete_id}`}>
                  {athlete.first_name + ' ' + athlete.last_name}
                </Link>
                <PowerOfTenLink guid={athlete.po10_guid} />
              </td>
              <td className="px-4 py-2">{formatGender(athlete.gender)}</td>
              <td className="px-4 py-2">{athlete.category}</td>
              <td className="px-4 py-2 hidden md:table-cell">
                {friendlyDate(athlete.created_at)}
              </td>
              <td className="px-4 py-2 hidden md:table-cell">
                {athlete.payments && !hasOutstandingPayment(athlete)
                  ? friendlyDate(athlete.payments[0]?.datePaid)
                  : ''}
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </>
  );
}

export default AthletesTable;
