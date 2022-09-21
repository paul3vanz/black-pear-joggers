import ClubsTable from '../../components/clubs-table';
import { Container } from '@black-pear-joggers/container';
import { LoadingSpinner } from 'apps/admin/components/loading-spinner';
import { SearchBar } from '@black-pear-joggers/search-bar';
import { Stack } from '@black-pear-joggers/stack';
import { toTitleCase } from '../../helpers/formatters';
import { useClubs } from '@black-pear-joggers/core-services';
import { useState } from 'react';
import { withAuthenticationRequired } from '@auth0/auth0-react';

function MembersPage() {
  const { clubs, isLoading } = useClubs();
  const [search, setSearch] = useState('');

  return (
    <Stack>
      <Container>
        <h1>Clubs</h1>

        {isLoading ? (
          <LoadingSpinner />
        ) : (
          <>
            <SearchBar search={search} setSearch={setSearch} />

            <ClubsTable search={search} clubs={clubs ? clubs.Clubs : []} />
          </>
        )}
      </Container>
    </Stack>
  );
}

export default withAuthenticationRequired(MembersPage);
