import { AwardClaim } from '@black-pear-joggers/core-services';
import { AwardClaimsTable } from '../components/club-standards/award-claims-table';
import { Container } from '@black-pear-joggers/container';
import { SearchBar } from '@black-pear-joggers/search-bar';
import { Stack } from '@black-pear-joggers/stack';
import { useStandards } from '@black-pear-joggers/core-services';
import { useState } from 'react';
import { useSWRConfig } from 'swr';
import { withAuthenticationRequired } from '@auth0/auth0-react';
import {
  archive,
  awardClaimsUrl,
  deleteClaim,
  toggleVerified,
  useAwardClaims,
} from '@black-pear-joggers/core-services';

export function ClubStandards() {
  const { awardClaims, isLoading: isAwardClaimsLoading } = useAwardClaims();
  const { standards, isLoading: isStandardsLoading } = useStandards();
  const { mutate } = useSWRConfig();
  const [search, setSearch] = useState('');

  async function onToggleVerified(awardClaim: AwardClaim) {
    const response = await toggleVerified(awardClaim);

    const position = awardClaims.findIndex(
      (awardClaim) => awardClaim.id === response.id
    );

    mutate(
      awardClaimsUrl,
      [
        ...awardClaims.slice(0, position),
        response,
        ...awardClaims.slice(position + 1),
      ],
      false
    );
  }

  async function onArchive(awardClaim: AwardClaim) {
    const response = await archive(awardClaim);

    if (!response) {
      alert('Failed to archive');

      return;
    }

    const position = awardClaims.findIndex((a) => a.id === awardClaim.id);

    mutate(
      awardClaimsUrl,
      awardClaims.map((a) =>
        a.id === awardClaim.id ? { ...awardClaim, archived: true } : a
      ),
      false
    );
  }

  async function onDelete(awardClaim: AwardClaim) {
    const response = await deleteClaim(awardClaim);

    if (!response) {
      alert('Failed to delete');

      return;
    }

    const position = awardClaims.findIndex((a) => a.id === awardClaim.id);

    mutate(
      awardClaimsUrl,
      awardClaims.filter((a) => a.id !== awardClaim.id),
      false
    );
  }

  return (
    <Stack>
      <Container>
        <h1>Club standards award claims</h1>

        <SearchBar search={search} setSearch={setSearch} />

        {isAwardClaimsLoading ? (
          <p>Loading...</p>
        ) : (
          <AwardClaimsTable
            search={search}
            awardClaims={awardClaims}
            standards={standards}
            onToggleVerified={onToggleVerified}
            onArchive={onArchive}
            onDelete={onDelete}
          />
        )}
      </Container>
    </Stack>
  );
}

export default withAuthenticationRequired(ClubStandards);
