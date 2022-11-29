import Link from 'next/link';
import { AwardBadge } from './award-badge';
import { BackgroundColour, Stack } from '@black-pear-joggers/stack';
import { Container } from '@black-pear-joggers/container';
import { useQuery } from '@tanstack/react-query';
import { useState } from 'react';
import {
  formatRelative,
  friendlyDate,
  shortDate,
} from '@black-pear-joggers/helpers';
import {
  getPersonalBests,
  Paginate,
  Performance,
} from '@black-pear-joggers/core-services';

export function PersonalBestsTable() {
  const [activeFixture, setActiveFixture] = useState<Paginate<Performance>>();

  const { isLoading, data } = useQuery<Paginate<Performance>>(
    ['fixtures'],
    () => getPersonalBests().then((response) => response.json())
  );

  return (
    <>
      {isLoading ? (
        <p>Loading...</p>
      ) : (
        <ul className="mb-6">
          {data.data.filter(filterCommonEvents).map((result) => (
            <li
              key={`${result.athlete_id}${result.meeting_id}`}
              className="mb-1"
            >
              <Link
                href={`https://apps.bpj.org.uk/race-results/#/athlete/${result.athlete_id}`}
              >
                <a>
                  {result.first_name} {result.last_name}
                </a>
              </Link>{' '}
              {result.time}{' '}
              {result.award ? <AwardBadge award={result.award} /> : null} at{' '}
              {result.race}{' '}
              <span className="text-gray-400">
                {formatRelative(result.date)}
              </span>
            </li>
          ))}
        </ul>
      )}
    </>
  );
}

function filterCommonEvents(result: Performance) {
  const allowedEvents = [
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

  return allowedEvents.includes(result.event);
}
