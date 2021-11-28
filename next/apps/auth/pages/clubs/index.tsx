import { Stack } from '@black-pear-joggers/stack';
import { Container } from '@black-pear-joggers/container';
import { withAuthenticationRequired } from '@auth0/auth0-react';
import { useClubs } from '../../services/clubs';
import { toTitleCase } from '../../helpers/formatters';
import Link from 'next/link';

function MembersPage() {
  const { clubs, isLoading, isError } = useClubs();

  return (
    <Stack>
      <Container>
        <h1>Clubs</h1>
        {isLoading ? (
          <p>Loading...</p>
        ) : (
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
              {clubs &&
                clubs.Clubs.map((club, index) => (
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
        )}
      </Container>
    </Stack>
  );
}

export default withAuthenticationRequired(MembersPage);
