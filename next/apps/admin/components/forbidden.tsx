import { Container } from '@black-pear-joggers/container';
import { Stack } from '@black-pear-joggers/stack';
import { useAuth0 } from '@auth0/auth0-react';
import { UserWithRoles } from '../helpers/auth';

export function Forbidden() {
  const { user } = useAuth0();

  return (
    <Stack>
      <Container>
        <h1>Uh oh :-(</h1>

        <p>
          Sorry, you don&apos;t have access. Please speak to a committee member
          to request access to the admin site.
        </p>
      </Container>
    </Stack>
  );
}
