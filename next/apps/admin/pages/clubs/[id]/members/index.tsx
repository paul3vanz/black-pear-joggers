import Link from 'next/link';
import MembersTable from '../../../../components/members-table';
import { Container } from '@black-pear-joggers/container';
import { faChevronCircleLeft } from '@fortawesome/free-solid-svg-icons';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import { LoadingSpinner } from '../../../../components/loading-spinner';
import { SearchBar } from '@black-pear-joggers/search-bar';
import { Stack } from '@black-pear-joggers/stack';
import { toTitleCase } from '../../../../helpers/formatters';
import { useClubs } from '@black-pear-joggers/core-services';
import { useMembers } from '@black-pear-joggers/core-services';
import { useRouter } from 'next/dist/client/router';
import { useState } from 'react';
import { withAuthenticationRequired } from '@auth0/auth0-react';

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
        <p className="mb-8">
          <Link href={`/clubs`}>
            <FontAwesomeIcon
              className="pr-2"
              size="lg"
              icon={faChevronCircleLeft}
            />
            Back to clubs
          </Link>
        </p>

        <h1>{club?.ClubName}</h1>

        <SearchBar search={search} setSearch={setSearch} />

        {isMembersLoading ? (
          <LoadingSpinner />
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
