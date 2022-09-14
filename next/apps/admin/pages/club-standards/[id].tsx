import Link from 'next/link';
import { Container } from '@black-pear-joggers/container';
import { faChevronCircleLeft } from '@fortawesome/free-solid-svg-icons';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import { Stack } from '@black-pear-joggers/stack';
import { UpdateClaimForm } from '../../components/club-standards/update-claim-form';
import { UpdateClaimRacesForm } from '../../components/club-standards/update-claim-races-form';
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
    <>
      <Stack>
        <Container>
          <p className="mb-8">
            <Link href={`/club-standards`}>
              <a>
                <FontAwesomeIcon
                  className="pr-2"
                  size="lg"
                  icon={faChevronCircleLeft}
                />
                Back to claims
              </a>
            </Link>
          </p>

          <h1 className="mb-8">
            {awardClaim.firstName + ' ' + awardClaim.lastName}
            <br />
            <span className="text-2xl">
              {awardClaim.gender}
              {awardClaim.category} {awardClaim.award}
            </span>
          </h1>
        </Container>
      </Stack>

      <Stack backgroundColour="light">
        <Container>
          <h2>Claim details</h2>

          <UpdateClaimForm awardClaim={awardClaim} />
        </Container>
      </Stack>

      <Stack>
        <Container>
          <h2>Races</h2>

          <UpdateClaimRacesForm awardClaim={awardClaim} />
        </Container>
      </Stack>
    </>
  );
}

export default withAuthenticationRequired(AwardClaimDetailsPage);
