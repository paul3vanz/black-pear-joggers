import Link from 'next/link';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import { LoadingSpinner } from '../loading-spinner';
import { useQuery } from '@tanstack/react-query';
import {
  faCheckCircle,
  faExternalLinkSquareAlt,
} from '@fortawesome/free-solid-svg-icons';

interface MatchingRaceResultsProps {
  date: string;
  distance: string;
  event: string;
  firstName: string;
  gender: string;
  lastName: string;
  onSelect: (race: string) => void;
}

function findMatchingRaces(race?: string, date?: string) {
  return fetch(
    `https://bpj.org.uk/api/public/index.php/performances?search=${race.substring(
      0,
      3
    )}&fromDate=${date}&toDate=${date}`
  ).then((response) => response.json());
}

export function MatchingRaceResults(props: MatchingRaceResultsProps) {
  const { isLoading, error, data } = useQuery(
    ['races', props.date, props.event],
    () => findMatchingRaces(props.event, props.date)
  );

  return (
    <div className="text-sm mb-4 bg-gray-100 p-4">
      <h3 className="text-sm mb-2 font-normal">
        Found the following potential matching results...
      </h3>

      {isLoading ? <LoadingSpinner /> : null}

      {error ? <div>{JSON.stringify(error)}</div> : null}

      {data?.data.length ? (
        <ul className="list list-disc ml-4">
          {data?.data?.map((result) => (
            <>
              <li>
                {result.race}

                {result.race !== props.event ? (
                  <button
                    className="font-bold pl-4 underline"
                    onClick={() => props.onSelect(result.race)}
                  >
                    Update
                  </button>
                ) : (
                  <FontAwesomeIcon
                    className="pl-4 text-green-600"
                    icon={faCheckCircle}
                  />
                )}

                <Link
                  href={`https://apps.bpj.org.uk/race-results/#/meeting/${result.date}/${result.meeting_id}`}
                  className="pl-4"
                  target="_blank"
                >
                  <>
                    View full results{' '}
                    <FontAwesomeIcon icon={faExternalLinkSquareAlt} />
                  </>
                </Link>
              </li>
            </>
          ))}
        </ul>
      ) : (
        <div>No results found.</div>
      )}
    </div>
  );
}

export default MatchingRaceResults;
