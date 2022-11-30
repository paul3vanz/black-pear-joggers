import Link from 'next/link';
import { AwardBadge } from './award-badge';
import { formatRelative } from '@black-pear-joggers/helpers';
import { useQuery } from '@tanstack/react-query';
import {
  getPersonalBests,
  Paginate,
  Performance,
} from '@black-pear-joggers/core-services';

export function PersonalBestsTable() {
  const { isLoading, data } = useQuery<Paginate<Performance>>(
    ['personalBests'],
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
              className="mb-2"
            >
              <Link
                href={`https://apps.bpj.org.uk/race-results/#/athlete/${result.athlete_id}`}
              >
                <a>
                  {result.first_name} {result.last_name}
                </a>
              </Link>
              <span className="font-bold text-lg mx-1">{result.time}</span>
              {result.award ? (
                <AwardBadge award={result.award} />
              ) : null} at {result.race}{' '}
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
