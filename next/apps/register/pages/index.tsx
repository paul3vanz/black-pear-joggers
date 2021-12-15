import RegisterForm from '../components/register-form';
import { Container } from '@black-pear-joggers/container';
import { Stack } from '@black-pear-joggers/stack';
import { useAuth0, withAuthenticationRequired } from '@auth0/auth0-react';


function AdminHomePage() {
  return (
    <>
      <Stack>
        <Container>
          <h1>Registration</h1>

          <p>
            Now you're logged in, we need to link up your membership details.
            You'll need your England Athletics registration number (URN) that
            would have been given to you when your membership was set up - it'll
            be on your membership card.
          </p>
        </Container>
      </Stack>

      <Stack backgroundColour="light">
        <Container>
          <h2>Your details</h2>

          <RegisterForm />
        </Container>
      </Stack>
    </>
  );
}

export default withAuthenticationRequired(AdminHomePage);
