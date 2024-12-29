import { Container } from '@black-pear-joggers/container';
import { BackgroundColour, Stack } from '@black-pear-joggers/stack';
import { withAuthenticationRequired } from '@auth0/auth0-react';
import { YourAwards } from '../components/your-awards';

function AwardClaimHomePage() {
  return (
    <>
      <Stack>
        <Container>
          <h1>Club standards awards</h1>

          <p>
            Check your progress on the{' '}
            <a href="https://apps.bpj.org.uk/club-standards/">
              club standards awards scheme
            </a>
            . You can claim your award if in any calendar year you have been a
            member of the club throughout the period over which all the runs
            have taken place and you have the required standard for at least
            three of the five distances in your age category (your age counting
            as of the date of the run).
          </p>
        </Container>
      </Stack>

      <Stack backgroundColour={BackgroundColour.Dark}>
        <Container>
          <h2>Current targets</h2>

          <p>
            Coming soon. In the meantime, find your targets on the{' '}
            <a href="https://apps.bpj.org.uk/club-standards/">
              club standards awards scheme
            </a>{' '}
            page.
          </p>
        </Container>
      </Stack>

      <YourAwards />
    </>
  );
}

export default withAuthenticationRequired(AwardClaimHomePage);
