import AthletesTable from '../components/athletes-table';
import { Container } from '@black-pear-joggers/container';
import { SearchBar } from '@black-pear-joggers/search-bar';
import { Stack } from '@black-pear-joggers/stack';
import { useAthletes } from '@black-pear-joggers/core-services';
import { useState } from 'react';
import { withAuthenticationRequired } from '@auth0/auth0-react';

function AthletesPage() {
  const { athletes, isLoading, isError } = useAthletes();
  const [search, setSearch] = useState('');

  return (
    <Stack>
      <Container>
        <h1>Athletes</h1>

        <SearchBar search={search} setSearch={setSearch} />

        {isLoading ? (
          <p>Loading...</p>
        ) : (
          <AthletesTable search={search} athletes={athletes} />
        )}
      </Container>
    </Stack>
  );
}

export default withAuthenticationRequired(AthletesPage);
