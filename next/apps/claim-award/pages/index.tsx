import { Container } from '@black-pear-joggers/container';
import { Stack } from '@black-pear-joggers/stack';
import { withAuthenticationRequired } from '@auth0/auth0-react';
import { YourAwards } from '../components/your-awards';
import { CurrentTargets } from '../components/current-targets';
import { useUser } from '@black-pear-joggers/core-services';
import { PersonalBests } from '../components/personal-bests';

function AwardClaimHomePage() {
  const { data: userProfile, isLoading: isLoadingUser } = useUser();

  if (!isLoadingUser && !userProfile.athleteId) {
    window.location.href = 'https://bpj.org.uk/register';
  }

  return (
    <>
      <Stack>
        <Container>
          <h1>Club standards awards</h1>

          <p>
            Check your progress on the{' '}
            <a href="https://apps.bpj.org.uk/club-standards/">
              club standards awards scheme
            </a>{' '}
            below. You can claim your award if in any calendar year you have
            been a member of the club throughout the period over which all the
            runs have taken place and you have the required standard for at
            least three of the five distances in your age category (your age
            counting as of the date of the run).
          </p>
        </Container>
      </Stack>

      <PersonalBests />

      <CurrentTargets />

      <YourAwards />
    </>
  );
}

export default withAuthenticationRequired(AwardClaimHomePage);
