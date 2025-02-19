import CreateMagicMileResultForm from '../components/magic-mile/create-magic-mile-form';
import MagicMileResultsTable from '../components/magic-mile/magic-mile-results-table';
import { BackgroundColour, Stack } from '@black-pear-joggers/stack';
import { Container } from '@black-pear-joggers/container';
import { LoadingSpinner } from '../components/loading-spinner';
import { MagicMileResult } from '@black-pear-joggers/core-services';
import { mutate } from 'swr';
import { SearchBar } from '@black-pear-joggers/search-bar';
import { useState } from 'react';
import { withAuthenticationRequired } from '@auth0/auth0-react';
import {
  destroy,
  magicMileResultsUrl,
  useMagicMileResults,
} from '@black-pear-joggers/core-services';

export function MagicMilePage() {
  const { magicMileResults, isLoading, isError } = useMagicMileResults();
  const [search, setSearch] = useState('');

  async function onDelete(magicMileResult: MagicMileResult) {
    const response = await destroy(magicMileResult);

    if (!response) {
      alert('Failed to delete');

      return;
    }

    const position = magicMileResults!.findIndex(
      (a) => a.id === magicMileResult.id
    );

    mutate(
      magicMileResultsUrl,
      magicMileResults!.filter((a) => a.id !== magicMileResult.id),
      false
    );
  }

  if (!magicMileResults) {
    return null;
  }

  return (
    <>
      <Stack>
        <Container>
          <h1>Magic mile</h1>

          <h2>Add a result</h2>

          <CreateMagicMileResultForm results={magicMileResults} />
        </Container>
      </Stack>

      <Stack backgroundColour={BackgroundColour.Dark}>
        <Container>
          <h2>Results</h2>

          <SearchBar search={search} setSearch={setSearch} dark={true} />

          {isLoading ? (
            <LoadingSpinner />
          ) : (
            <MagicMileResultsTable
              search={search}
              magicMileResults={magicMileResults}
              onDelete={onDelete}
            />
          )}
        </Container>
      </Stack>
    </>
  );
}

export default withAuthenticationRequired(MagicMilePage);
