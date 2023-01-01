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
            <li key={`${result.athleteId}${result.meetingId}`} className="mb-2">
              <Link
                href={`https://apps.bpj.org.uk/race-results/#/athlete/${result.athleteId}`}
              >
                {result.firstName} {result.lastName}
              </Link>
              {result.award ? (
                <span className="ml-1">
                  <AwardBadge award={result.award} />
                </span>
              ) : null}
              <span className="block sm:inline">
                <span className="font-bold text-lg sm:ml-1">{result.time}</span>{' '}
                at {result.meetingName}{' '}
              </span>
              <span className="text-gray-400 block sm:inline">
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
    '5M',
    '5MMT',
    'parkrun',
    '10K',
    '10KMT',
    '10M',
    '10MMT',
    'HM',
    'HMMT',
    'Mar',
    'MarMT',
  ];

  return allowedEvents.includes(result.event);
}
