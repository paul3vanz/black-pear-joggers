import { Stack } from '@black-pear-joggers/stack';
import { Container } from '@black-pear-joggers/container';
import { withAuthenticationRequired } from '@auth0/auth0-react';
import { useMagicMileResults } from '../services/magic-mile';
import { SearchBar } from '@black-pear-joggers/search-bar';
import { useState } from 'react';
import MagicMileResultsTable from '../components/magic-mile/magic-mile-results-table';
import CreateMagicMileResultForm from '../components/magic-mile/create-magic-mile-form';

export function Tools() {
  const { magicMileResults, isLoading, isError } = useMagicMileResults();
  const [search, setSearch] = useState('');

  return (
    <>
      <Stack>
        <Container>
          <h1>Magic mile</h1>

          <h2>Add a result</h2>

          <CreateMagicMileResultForm results={magicMileResults} />
        </Container>
      </Stack>

      <Stack backgroundColour="dark">
        <Container>
          <h2>Results</h2>

          <SearchBar search={search} setSearch={setSearch} dark={true} />

          {isLoading ? (
            <p>Loading...</p>
          ) : (
            <MagicMileResultsTable
              search={search}
              magicMileResults={magicMileResults}
            />
          )}
        </Container>
      </Stack>
    </>
  );
}

export default withAuthenticationRequired(Tools);
