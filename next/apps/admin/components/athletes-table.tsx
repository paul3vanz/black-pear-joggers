import Link from 'next/link';
import { Athlete } from '@black-pear-joggers/core-services';
import { friendlyDate } from '@black-pear-joggers/helpers';
import { formatGender } from '../helpers/formatters';
import { Pill } from '@black-pear-joggers/ui/atoms/pill';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import {
  faCheckCircle,
  faExclamationCircle,
  faPersonRunning,
  faTimesCircle,
  faTrophy,
} from '@fortawesome/free-solid-svg-icons';
import { useState } from 'react';

interface AthletesTableProps {
  search: string;
  athletes: Athlete[];
}

function AthletesTable(props: AthletesTableProps) {
  const [statusFilter, setStatusFilter] = useState<string>('active');
  const [affiliatedFilter, setAffiliatedFilter] = useState<string>(null);

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
          : statusFilter === 'requested'
          ? !athlete.active &&
            athlete.payments[0]?.paymentStatus === 'Requested'
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
          text="Active (paid up)"
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

      <table className="w-full">
        <thead className="divide-y divide-gray-200">
          <tr>
            <th className="px-4 py-2">Active</th>
            <th className="px-4 py-2">Affiliation</th>
            <th className="px-4 py-2">Name</th>
            <th className="px-4 py-2">Gender</th>
            <th className="px-4 py-2">Category</th>
            <th className="px-4 py-2 hidden md:table-cell">Created</th>
            <th className="px-4 py-2 hidden md:table-cell">Updated</th>
          </tr>
        </thead>
        <tbody className="divide-y divide-gray-200">
          {filteredAthletes.map((athlete, index) => (
            <tr
              key={athlete.id}
              className={index % 2 === 0 ? 'bg-gray-100' : ''}
            >
              <td className="px-4 py-2">
                {athlete.active ? (
                  <FontAwesomeIcon
                    className="text-green-600"
                    size="lg"
                    title="Paid up"
                    icon={faCheckCircle}
                  />
                ) : athlete.payments[0]?.paymentStatus === 'Requested' ? (
                  <FontAwesomeIcon
                    className="text-yellow-400"
                    size="lg"
                    title="Payment requested"
                    icon={faExclamationCircle}
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
                {athlete.active ||
                athlete.payments[0]?.paymentStatus === 'Requested' ? (
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
                <Link href={`/athletes/${athlete.id}`}>
                  {athlete.first_name + ' ' + athlete.last_name}
                </Link>
              </td>
              <td className="px-4 py-2">{formatGender(athlete.gender)}</td>
              <td className="px-4 py-2">{athlete.category}</td>
              <td className="px-4 py-2 hidden md:table-cell">
                {friendlyDate(athlete.created_at)}
              </td>
              <td className="px-4 py-2 hidden md:table-cell">
                {athlete.created_at !== athlete.updated_at
                  ? friendlyDate(athlete.updated_at)
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
