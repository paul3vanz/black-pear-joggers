import { Stack } from '@black-pear-joggers/stack';
import { Container } from '@black-pear-joggers/container';
import { useAuth0, withAuthenticationRequired } from '@auth0/auth0-react';

export function Tools() {
  const { user } = useAuth0();
  return (
    <Stack>
      <Container>
        <h1>Athletes</h1>
        Welcome {user.name}
      </Container>
    </Stack>
  );
}

export default withAuthenticationRequired(Tools);
