import Link from 'next/link';
import { faTrash } from '@fortawesome/free-solid-svg-icons';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import { friendlyDate, timeFormatted } from '@black-pear-joggers/helpers';
import { MagicMileResult } from '@black-pear-joggers/core-services';
import { toTitleCase } from '../../helpers/formatters';

interface MagicMileResultsProps {
  search: string;
  magicMileResults: MagicMileResult[];
  onDelete: (magicMileResult: MagicMileResult) => void;
}

function MagicMileResults(props: MagicMileResultsProps) {
  const filteredResults = props.search
    ? props.magicMileResults.filter((result) => {
        const search = props.search.toLowerCase();
        const name = `${result.firstName} ${result.lastName}`.toLowerCase();

        return name.includes(search);
      })
    : props.magicMileResults;

  function formatLocation(location: string): string {
    const search = location.match(/\(.*?(?=\))/);

    return search ? search[0].replace('(', '') : location;
  }

  return (
    <>
      <p>
        <strong>{filteredResults.length}</strong> results
      </p>
      <div className="overflow-x-auto">
        <table className="w-full">
          <thead className="divide-y divide-gray-800">
            <tr>
              <th className="px-1 sm:px-4 py-2">Name</th>
              <th className="px-1 sm:px-4 py-2 hidden lg:table-cell">
                Predicted
              </th>
              <th className="px-1 sm:px-4 py-2">Actual</th>
              <th className="px-1 sm:px-4 py-2">Date</th>
              <th className="px-1 sm:px-4 py-2 hidden lg:table-cell">Gender</th>
              <th className="px-1 sm:px-4 py-2 hidden lg:table-cell">
                Category
              </th>
              <th className="px-1 sm:px-4 py-2">Location</th>
              <th></th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-800">
            {filteredResults.map((result, index) => (
              <tr
                key={result.id}
                className={index % 2 === 0 ? 'bg-gray-800' : ''}
              >
                <td className="px-1 sm:px-4 py-2">
                  <Link href={`/magic-mile/${result.id}`}>
                    {result.firstName + ' ' + result.lastName}
                  </Link>
                </td>
                <td className="px-1 sm:px-4 py-2 hidden lg:table-cell">
                  {timeFormatted(result.predictedTime)}
                </td>
                <td className="px-1 sm:px-4 py-2">
                  {timeFormatted(result.actualTime)}
                </td>
                <td className="px-1 sm:px-4 py-2">
                  {friendlyDate(result.date)}
                </td>
                <td className="px-1 sm:px-4 py-2 hidden lg:table-cell">
                  {toTitleCase(result.gender)}
                </td>
                <td className="px-1 sm:px-4 py-2 hidden lg:table-cell">
                  {result.category}
                </td>
                <td className="px-1 sm:px-4 py-2">
                  {formatLocation(result.location)}
                </td>
                <td className="px-1 sm:px-4 py-2">
                  <button title="Delete" onClick={() => props.onDelete(result)}>
                    <FontAwesomeIcon
                      className="cursor-pointer"
                      size="lg"
                      icon={faTrash}
                    />
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </>
  );
}

export default MagicMileResults;
