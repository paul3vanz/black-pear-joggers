import { Stack } from '@black-pear-joggers/stack';
import { Container } from '@black-pear-joggers/container';
import AwardClaimsTable from '../components/club-standards/award-claims-table';
import { withAuthenticationRequired } from '@auth0/auth0-react';
import { SearchBar } from '@black-pear-joggers/search-bar';
import { useState } from 'react';
import {
  awardClaimsUrl,
  toggleVerified,
  useAwardClaims,
} from '../services/award-claims';
import { useSWRConfig } from 'swr';
import { AwardClaim } from '../services/award-claims.interface';

export function ClubStandards() {
  const { awardClaims, isLoading } = useAwardClaims();
  const { mutate } = useSWRConfig();
  const [search, setSearch] = useState('');

  async function onToggleVerified(awardClaim: AwardClaim) {
    const response = await toggleVerified(awardClaim);
    console.log(awardClaims);
    console.log(
      awardClaims.findIndex((awardClaim) => awardClaim.id === response.id)
    );
    console.log(response);

    mutate(
      awardClaimsUrl,
      [
        ...awardClaims.splice(
          awardClaims.findIndex((awardClaim) => awardClaim.id === response.id),
          1
        ),
        response,
      ],
      false
    );
  }

  return (
    <Stack>
      <Container>
        <h1>Athletes</h1>

        <SearchBar search={search} setSearch={setSearch} />

        {isLoading ? (
          <p>Loading...</p>
        ) : (
          <AwardClaimsTable
            search={search}
            awardClaims={awardClaims}
            onToggleVerified={onToggleVerified}
          />
        )}
      </Container>
    </Stack>
  );
}

export default withAuthenticationRequired(ClubStandards);
