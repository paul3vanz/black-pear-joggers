import { Stack } from '@black-pear-joggers/stack';
import { Container } from '@black-pear-joggers/container';
import { withAuthenticationRequired } from '@auth0/auth0-react';
import Link from 'next/link';
import { toTitleCase } from '../helpers/formatters';
import { useAthletes } from '../services/athletes';

function AthletesPage() {
  const { athletes, isLoading, isError } = useAthletes();

  return (
    <Stack>
      <Container>
        <h1>Athletes</h1>
        {isLoading ? (
          <p>Loading...</p>
        ) : (
          <>
            {/* <p>
              <strong>{athletes.length}</strong> athletes
            </p> */}
            <table className="w-full">
              <thead className="divide-y divide-gray-200">
                <tr>
                  <th className="px-4 py-2">ID</th>
                  <th className="px-4 py-2">First name</th>
                  <th className="px-4 py-2">Last name</th>
                  <th className="px-4 py-2">Gender</th>
                  <th className="px-4 py-2">Category</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-200">
                {athletes &&
                  athletes.map((athlete, index) => (
                    <tr
                      key={athlete.id}
                      className={index % 2 === 0 ? 'bg-gray-100' : ''}
                    >
                      <td className="px-4 py-2">{athlete.id}</td>
                      <td className="px-4 py-2">
                        <Link href={`/athletes/${athlete.id}`}>
                          {athlete.first_name}
                        </Link>
                      </td>
                      <td className="px-4 py-2">
                        <Link href={`/athletes/${athlete.id}`}>
                          {athlete.last_name}
                        </Link>
                      </td>
                      <td className="px-4 py-2">
                        {toTitleCase(athlete.gender)}
                      </td>
                      <td className="px-4 py-2">{athlete.category}</td>
                    </tr>
                  ))}
              </tbody>
            </table>
          </>
        )}
      </Container>
    </Stack>
  );
}

export default withAuthenticationRequired(AthletesPage);
