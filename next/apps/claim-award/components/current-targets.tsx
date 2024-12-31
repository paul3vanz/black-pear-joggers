import { Container } from '@black-pear-joggers/container';
import { GenderFull, useUser } from '@black-pear-joggers/core-services';
import { BackgroundColour, Stack } from '@black-pear-joggers/stack';

export function CurrentTargets() {
  const { data: userProfile, isLoading: isLoadingUser } = useUser();

  return (
    <Stack backgroundColour={BackgroundColour.Dark}>
      <Container>
        <h2>Current targets</h2>

        {isLoadingUser ? (
          <>
            <p>Loading...</p>
          </>
        ) : (
          <>
            <p>
              You are currently in the{' '}
              <strong>
                {GenderFull[userProfile.athlete.gender]}{' '}
                {userProfile.athlete.category.replace('SEN', 'Senior')}
              </strong>{' '}
              category. Below are your targets for the different awards. Check
              out all age categories on the{' '}
              <a href="https://apps.bpj.org.uk/club-standards/">
                club standards awards scheme
              </a>{' '}
              page.
            </p>

            <p>COMING SOON</p>
          </>
        )}
      </Container>
    </Stack>
  );
}
