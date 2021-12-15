import { Container } from '@black-pear-joggers/container';
import { Stack } from '@black-pear-joggers/stack';
import { useAuth0, withAuthenticationRequired } from '@auth0/auth0-react';


function AdminHomePage() {
  return (
    <Stack>
      <Container>
        <h1>Registration</h1>

        <p>Now you're logged in, we need to link up your membership details.</p>
      </Container>
    </Stack>
  );
}

export default withAuthenticationRequired(AdminHomePage);
