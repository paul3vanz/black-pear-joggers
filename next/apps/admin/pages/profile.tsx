import { Button } from '@black-pear-joggers/button';
import { config } from '@black-pear-joggers/core-services';
import { Container } from '@black-pear-joggers/container';
import { Stack } from '@black-pear-joggers/stack';
import { useAuth0 } from '@auth0/auth0-react';

export default function Profile() {
  const { user, logout } = useAuth0();

  if (!user) {
    return null;
  }

  return (
    <Stack>
      <Container>
        <h1>Profile</h1>

        <ul className="mb-6">
          <li>
            <strong>User ID:</strong> {user.sub}
          </li>
          <li>
            <strong>Email:</strong> {user.email}{' '}
            {user.email_verified ? '(Verified)' : '(Unverified)'}
          </li>
          <li>
            <strong>Role(s):</strong> {user.bpjRoles?.join(', ')}
          </li>
        </ul>

        <Button
          text="Log out"
          onClick={() =>
            logout({
              logoutParams: {
                returnTo:
                  (typeof window !== 'undefined' &&
                    `${window.location.origin}/admin`) ||
                  undefined,
              },
            })
          }
        />
      </Container>
    </Stack>
  );
}
