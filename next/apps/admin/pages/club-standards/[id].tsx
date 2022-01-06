import Link from 'next/link';
import { Button } from '@black-pear-joggers/button';
import { Container } from '@black-pear-joggers/container';
import { Stack } from '@black-pear-joggers/stack';
import { UpdateAthleteForm } from '../../components/athletes/update-athlete-form';
import { useAwardClaims } from '@black-pear-joggers/core-services';
import { useRouter } from 'next/dist/client/router';
import { withAuthenticationRequired } from '@auth0/auth0-react';

function AwardClaimDetailsPage() {
  const router = useRouter();
  const { id } = router.query;
  const { awardClaims, isLoading, isError } = useAwardClaims();

  const awardClaim = awardClaims
    ? awardClaims.find((awardClaim) => awardClaim.id === Number(id))
    : null;

  console.log(awardClaim);

  if (isLoading) {
    return (
      <Stack>
        <Container>
          <p>Loading...</p>
        </Container>
      </Stack>
    );
  }

  if ((!isLoading && !awardClaim) || isError) {
    return (
      <Stack>
        <Container>
          <p>Error loading award claim</p>
        </Container>
      </Stack>
    );
  }

  return (
    <Stack>
      <Container>
        <p>
          <Link href={`/club-standards`}>Back to claims</Link>
        </p>

        <h1>{awardClaim.firstName + ' ' + awardClaim.lastName}</h1>

        {/* <UpdateAthleteForm athlete={athlete} /> */}

        <pre>{JSON.stringify(awardClaim, null, '    ')}</pre>
      </Container>
    </Stack>
  );
}

export default withAuthenticationRequired(AwardClaimDetailsPage);
