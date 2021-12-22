import Link from 'next/link';
import { Club } from '@black-pear-joggers/core-services';

interface ClubsTableProps {
  search: string;
  clubs: Club[];
}

function ClubsTable(props: ClubsTableProps) {
  const filteredClubs = props.search
    ? props.clubs.filter((club) =>
        club.ClubName.toLowerCase().includes(props.search.toLowerCase())
      )
    : props.clubs;

  return (
    <table className="w-full">
      <thead className="divide-y divide-gray-200">
        <tr>
          <th className="px-4 py-2">ID</th>
          <th className="px-4 py-2">Name</th>
          <th className="px-4 py-2">Country</th>
          <th className="px-4 py-2">Locality</th>
          <th className="px-4 py-2">Region</th>
        </tr>
      </thead>
      <tbody className="divide-y divide-gray-200">
        {filteredClubs.map((club, index) => (
          <tr
            key={club.ClubId}
            className={index % 2 === 0 ? 'bg-gray-100' : ''}
          >
            <td className="px-4 py-2">{club.ClubId}</td>
            <td className="px-4 py-2">
              <Link href={`/clubs/${club.ClubId}/members`}>
                {club.ClubName}
              </Link>
            </td>
            <td className="px-4 py-2">{club.HomeCountry}</td>
            <td className="px-4 py-2">{club.Locality}</td>
            <td className="px-4 py-2">{club.Region}</td>
          </tr>
        ))}
      </tbody>
    </table>
  );
}

export default ClubsTable;
