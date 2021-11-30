import { Stack } from '@black-pear-joggers/stack';
import { Container } from '@black-pear-joggers/container';
import { withAuthenticationRequired } from '@auth0/auth0-react';
import Link from 'next/link';
import { useMembers } from '../../../../services/members';
import { toTitleCase } from '../../../../helpers/formatters';
import { useRouter } from 'next/dist/client/router';
import { useClubs } from '../../../../services/clubs';
import { Athlete } from '../../../../services/members.interface';
import { SearchBar } from '@black-pear-joggers/search-bar';
import { useState } from 'react';
import MembersTable from '../../../../components/members-table';

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

  const [search, setSearch] = useState('');

  const club = clubs?.Clubs.find((club) => club.ClubId === clubId.toString());

  return (
    <Stack>
      <Container>
        <p>
          <Link href="/clubs">Back to clubs</Link>
        </p>

        <h1>{club?.ClubName}</h1>

        <SearchBar search={search} setSearch={setSearch} />

        {isMembersLoading ? (
          <p>Loading...</p>
        ) : members.Athletes ? (
          <MembersTable
            search={search}
            members={members.Athletes}
            clubId={`${clubId}`}
          />
        ) : (
          <p>No members</p>
        )}
      </Container>
    </Stack>
  );
}

export default withAuthenticationRequired(MembersPage);
