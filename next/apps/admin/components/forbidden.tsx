import { BackgroundColour, Stack } from '@black-pear-joggers/stack';
import { Button } from '@black-pear-joggers/button';
import { Container } from '@black-pear-joggers/container';
import { useAuth0 } from '@auth0/auth0-react';
import { config } from '../helpers/config';

export function Forbidden() {
  const { user, error, isAuthenticated, loginWithRedirect } =
    useAuth0();

  return (
    <>
      <Stack>
        <Container>
          <h1>Not authenticated</h1>

          <p>
            Sorry, you don&apos;t have access. Please speak to a committee
            member to request access to the admin site.
          </p>

          <Button
            text="Try logging in again"
            onClick={() => loginWithRedirect(config.auth)}
          />
        </Container>
      </Stack>

      <div className="hidden">
        <Stack backgroundColour={BackgroundColour.Light}>
          <Container>
            <h2>Debug information</h2>

            <pre>User: {JSON.stringify(user, null, '  ')}</pre>
            <pre>Error: {JSON.stringify(error, null, ' ')}</pre>
            <pre>
              isAuthenticated: {JSON.stringify(isAuthenticated, null, ' ')}
            </pre>
          </Container>
        </Stack>
      </div>
    </>
  );
}
