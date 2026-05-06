import CreateMagicMileResultForm from '../components/magic-mile/create-magic-mile-form';
import ImportCsvMagicMileForm from '../components/magic-mile/import-csv-magic-mile-form';
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
  const [addMode, setAddMode] = useState<'single' | 'csv'>('single');

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

  function handleImportComplete() {
    mutate(magicMileResultsUrl);
    setAddMode('single');
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

          <div className="flex gap-4 mb-4">
            <button
              type="button"
              className={`font-bold pb-1 border-b-2 ${addMode === 'single' ? 'border-black' : 'border-transparent text-gray-400 hover:text-black'}`}
              onClick={() => setAddMode('single')}
            >
              Single entry
            </button>
            <button
              type="button"
              className={`font-bold pb-1 border-b-2 ${addMode === 'csv' ? 'border-black' : 'border-transparent text-gray-400 hover:text-black'}`}
              onClick={() => setAddMode('csv')}
            >
              Import from CSV
            </button>
          </div>

          {addMode === 'single' && (
            <CreateMagicMileResultForm results={magicMileResults} />
          )}

          {addMode === 'csv' && (
            <ImportCsvMagicMileForm onImportComplete={handleImportComplete} />
          )}
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
