import { Container } from '@black-pear-joggers/container';
import { Stack } from '@black-pear-joggers/stack';
import { useAuth0, withAuthenticationRequired } from '@auth0/auth0-react';

function AdminHomePage() {
  return (
    <Stack>
      <Container>
        <h1>Black Pear Joggers Admin</h1>

        <p>Please use the menu above to navigate around.</p>
      </Container>
    </Stack>
  );
}

export default withAuthenticationRequired(AdminHomePage);
