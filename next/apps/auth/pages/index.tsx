import { useAuth0, withAuthenticationRequired } from '@auth0/auth0-react';
import { Stack } from '@black-pear-joggers/stack';
import { Container } from '@black-pear-joggers/container';

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
