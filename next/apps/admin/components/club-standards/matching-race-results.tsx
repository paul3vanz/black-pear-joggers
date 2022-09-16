import Link from 'next/link';
import { AwardClaim, update } from '@black-pear-joggers/core-services';
import { awards, distances } from '../../helpers/enums';
import { ButtonLightTextDarkBackground } from '@black-pear-joggers/button';
import { faExternalLinkSquareAlt } from '@fortawesome/free-solid-svg-icons';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import { friendlyDate } from '@black-pear-joggers/helpers';
import { PaginatedResults } from '../../types/paginated-results';
import { PerformanceSummary } from '../../types/performance-summary';
import { Select, TextInput } from '@black-pear-joggers/form-controls';
import { updateAthlete } from '@black-pear-joggers/core-services';
import { useFieldArray, useForm } from 'react-hook-form';
import { useMutation, useQuery } from '@tanstack/react-query';

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
  console.log('fetching');
  return fetch(
    `https://bpj.org.uk/api/public/index.php/performances?search=${race.substring(
      0,
      3
    )}&fromDate=${date}&toDate=${date}`
  ).then((response) => response.json());
}

export function MatchingRaceResults(props: MatchingRaceResultsProps) {
  const { isLoading, error, data, isFetching } = useQuery(
    ['races', props.date, props.event],
    () => findMatchingRaces(props.event, props.date)
  );

  return (
    <div className="text-sm mb-4 bg-gray-100 p-4">
      <h3 className="text-sm mb-2 font-normal">
        Found the following potential matching results...
      </h3>

      {isLoading ? <div>Loading...</div> : null}

      {error ? <div>{JSON.stringify(error)}</div> : null}

      {data?.data.length ? (
        <ul className="list list-disc ml-4">
          {data?.data?.map((result) => (
            <>
              <li>
                {result.race}
                <button
                  className="font-bold pl-4 underline"
                  onClick={() => props.onSelect(result.race)}
                >
                  Select
                </button>

                <Link
                  href={`https://apps.bpj.org.uk/race-results/#/meeting/${result.date}/${result.meeting_id}`}
                >
                  <a className="pl-4" target="_blank">
                    View full results{' '}
                    <FontAwesomeIcon icon={faExternalLinkSquareAlt} />
                  </a>
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
