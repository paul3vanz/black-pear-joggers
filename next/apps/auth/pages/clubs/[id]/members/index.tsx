import { Stack } from '@black-pear-joggers/stack';
import { Container } from '@black-pear-joggers/container';
import { withAuthenticationRequired } from '@auth0/auth0-react';
import Link from 'next/link';
import { useMembers } from 'apps/auth/services/members';
import { toTitleCase } from 'apps/auth/helpers/formatters';
import { useRouter } from 'next/dist/client/router';
import { useClubs } from 'apps/auth/services/clubs';
import { Athlete } from 'apps/auth/services/members.interface';

function MembersPage() {
  const router = useRouter();
  const { id: clubId } = router.query;

  const {
    members,
    isLoading: isMembersLoading,
    isError: isMembersError,
  } = useMembers(Number(clubId));

  const {
    clubs,
    isLoading: isClubsLoading,
    isError: isClubsError,
  } = useClubs();

  const club = clubs?.Clubs.find((club) => club.ClubId === clubId.toString());

  return (
    <Stack>
      <Container>
        <p>
          <Link href="/clubs">Back to clubs</Link>
        </p>

        <h1>{club?.ClubName}</h1>
        {isMembersLoading ? (
          <p>Loading...</p>
        ) : (
          <>
            <p>
              <strong>{members.Athletes.length}</strong> members (
              <strong>{getActiveMembers(members.Athletes)}</strong> active)
            </p>
            <table className="w-full">
              <thead className="divide-y divide-gray-200">
                <tr>
                  <th className="px-4 py-2">URN</th>
                  <th className="px-4 py-2">First name</th>
                  <th className="px-4 py-2">Last name</th>
                  <th className="px-4 py-2">Date of birth</th>
                  <th className="px-4 py-2">Gender</th>
                  <th className="px-4 py-2">Registration status</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-200">
                {members &&
                  members.Athletes.map((member, index) => (
                    <tr
                      key={member.Urn}
                      className={index % 2 === 0 ? 'bg-gray-100' : ''}
                    >
                      <td className="px-4 py-2">{member.Urn}</td>
                      <td className="px-4 py-2">
                        <Link href={`/clubs/${clubId}/members/${member.Urn}`}>
                          {member.Firstname}
                        </Link>
                      </td>
                      <td className="px-4 py-2">
                        <Link href={`/clubs/${clubId}/members/${member.Urn}`}>
                          {member.Lastname}
                        </Link>
                      </td>
                      <td className="px-4 py-2">
                        {toTitleCase(member.Gender)}
                      </td>
                      <td className="px-4 py-2">{member.Dob}</td>
                      <td className="px-4 py-2">
                        {member.CompetitiveRegStatus}
                      </td>
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

function getActiveMembers(members: Athlete[]): number {
  return members.filter((member) => {
    return !['Resigned From Club', 'Membership with Club Lapsed'].includes(
      member.CompetitiveRegStatus
    );
  }).length;
}

export default withAuthenticationRequired(MembersPage);
