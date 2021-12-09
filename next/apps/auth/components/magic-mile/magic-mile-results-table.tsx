import { toTitleCase } from '../../helpers/formatters';
import Link from 'next/link';
import { MagicMileResult } from '../../services/magic-mile.interface';
import { friendlyDate } from '@black-pear-joggers/helpers';

interface MagicMileResultsProps {
  search: string;
  magicMileResults: MagicMileResult[];
}

function MagicMileResults(props: MagicMileResultsProps) {
  const filteredResults = props.search
    ? props.magicMileResults.filter((result) => {
        const search = props.search.toLowerCase();
        const name = `${result.firstName} ${result.lastName}`.toLowerCase();

        return name.includes(search);
      })
    : props.magicMileResults;

  return (
    <>
      <p>
        <strong>{filteredResults.length}</strong> results
      </p>
      <table className="w-full">
        <thead className="divide-y divide-gray-800">
          <tr>
            <th className="px-4 py-2">Name</th>
            <th className="px-4 py-2">Predicted</th>
            <th className="px-4 py-2">Actual</th>
            <th className="px-4 py-2">Standard</th>
            <th className="px-4 py-2">Date</th>
            <th className="px-4 py-2">Gender</th>
            <th className="px-4 py-2">Category</th>
            <th className="px-4 py-2">Location</th>
          </tr>
        </thead>
        <tbody className="divide-y divide-gray-800">
          {filteredResults.map((result, index) => (
            <tr
              key={result.id}
              className={index % 2 === 0 ? 'bg-gray-800' : ''}
            >
              <td className="px-4 py-2">
                <Link href={`/magic-mile/${result.id}`}>
                  {result.firstName + ' ' + result.lastName}
                </Link>
              </td>
              <td className="px-4 py-2">{result.predictedTime}</td>
              <td className="px-4 py-2">{result.actualTime}</td>
              <td className="px-4 py-2"></td>
              <td className="px-4 py-2">{friendlyDate(result.date)}</td>
              <td className="px-4 py-2">{toTitleCase(result.gender)}</td>
              <td className="px-4 py-2">{result.category}</td>
              <td className="px-4 py-2">{result.location}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </>
  );
}

export default MagicMileResults;
