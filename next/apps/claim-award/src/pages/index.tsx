import { Container } from '@black-pear-joggers/container';
import { withAuthenticationRequired } from '@auth0/auth0-react';
import { YourAwards } from '../components/your-awards';
import { CurrentTargets } from '../components/current-targets';
import { useUser } from '@black-pear-joggers/core-services';
import { PersonalBests } from '../components/personal-bests';
import { Stack } from '@black-pear-joggers/stack';
import { CLAIM_MODE } from '../config/claim-mode';
import { MyClaims } from '../components/my-claims/my-claims';
import { ClaimWizard } from '../components/claim-wizard/claim-wizard';

function AwardClaimHomePage() {
  const { data: userProfile, isLoading: isLoadingUser } = useUser();

  if (!isLoadingUser && !userProfile?.athleteId) {
    window.location.href = 'https://bpj.org.uk/register';
  }

  return (
    <>
      <Stack>
        <Container>
          <h1>Club standards awards</h1>

          <p>
            You can claim an award if in any calendar year you have been a
            member of the club throughout the period over which all the runs
            have taken place and you have the required standard for at least
            three of the five distances in your age category (your age
            counting as of the date of the run).
          </p>
        </Container>
      </Stack>

      <CurrentTargets />

      {CLAIM_MODE === 'auto' ? (
        <>
          <PersonalBests />
          <YourAwards />
        </>
      ) : (
        <>
          <MyClaims athleteId={userProfile?.athleteId} />
          <ClaimWizard />
        </>
      )}
    </>
  );
}

export default withAuthenticationRequired(AwardClaimHomePage);
