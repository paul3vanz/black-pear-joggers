import { Stack } from '@black-pear-joggers/stack';
import { Container } from '@black-pear-joggers/container';
import { SearchBar } from '@black-pear-joggers/search-bar';
import { withAuthenticationRequired } from '@auth0/auth0-react';
import { useClubs } from '../../services/clubs';
import ClubsTable from '../../components/clubs-table';
import { toTitleCase } from '../../helpers/formatters';

import { useState } from 'react';

function MembersPage() {
  const { clubs, isLoading } = useClubs();
  const [search, setSearch] = useState('');

  return (
    <Stack>
      <Container>
        <h1>Clubs</h1>

        {isLoading ? (
          <p>Loading...</p>
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
