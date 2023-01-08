import Link from 'next/link';
import { AwardBadge } from './award-badge';
import { Performance } from '@black-pear-joggers/core-services';
import { PersonalBestBadge } from './personal-best-badge';

type ResultsTableProps = {
  results: Performance[];
};

export const ResultsTable = ({ results }: ResultsTableProps) => {
  if (!results || !results.length) return null;

  return (
    <table className="w-full">
      <thead className="divide-y divide-gray-200">
        <tr>
          <th className="px-4 py-2">Date</th>
          <th className="px-4 py-2">Athlete</th>
          <th className="px-4 py-2">Event</th>
          <th className="px-4 py-2">Event name</th>
          <th className="px-4 py-2">Gender</th>
          <th className="px-4 py-2">Category</th>
          <th className="px-4 py-2">Time</th>
          <th className="px-4 py-2">Standard</th>
        </tr>
      </thead>
      <tbody className="divide-y divide-gray-200">
        {results.map((result, index) => (
          <tr key={result.id} className={index % 2 === 0 ? 'bg-gray-100' : ''}>
            <td className="px-4 py-2">{result.date}</td>
            <td className="px-4 py-2">
              {result.membershipStatus === 'Registered' ? (
                <Link
                  href={`https://apps.bpj.org.uk/race-results/#/athlete/${result.athleteId}`}
                >
                  {result.firstName} {result.lastName}
                </Link>
              ) : (
                <>
                  {result.firstName} {result.lastName}
                </>
              )}
            </td>
            <td className="px-4 py-2">{result.event}</td>
            <td className="px-4 py-2">{result.meetingName}</td>
            <td className="px-4 py-2">
              {result.gender === 'M' ? 'Male' : 'Female'}
            </td>
            <td className="px-4 py-2">{result.category}</td>
            <td className="px-4 py-2">
              {result.time}{' '}
              {result.isPersonalBest ? (
                <span className="ml-1">
                  <PersonalBestBadge />
                </span>
              ) : (
                ''
              )}
            </td>
            <td className="px-4 py-2">
              <AwardBadge award={result.award} />
            </td>
          </tr>
        ))}
      </tbody>
    </table>
  );
};
