import { Stack } from '@black-pear-joggers/stack';
import { Container } from '@black-pear-joggers/container';
import AwardClaimsTable from '../components/club-standards/award-claims-table';
import { withAuthenticationRequired } from '@auth0/auth0-react';
import { SearchBar } from '@black-pear-joggers/search-bar';
import { useState } from 'react';
import { useAwardClaims } from '../services/award-claims';

export function ClubStandards() {
  const { awardClaims, isLoading, isError } = useAwardClaims();
  const [search, setSearch] = useState('');

  return (
    <Stack>
      <Container>
        <h1>Athletes</h1>

        <SearchBar search={search} setSearch={setSearch} />

        {isLoading ? (
          <p>Loading...</p>
        ) : (
          <AwardClaimsTable search={search} awardClaims={awardClaims} />
        )}
      </Container>
    </Stack>
  );
}

export default withAuthenticationRequired(ClubStandards);
