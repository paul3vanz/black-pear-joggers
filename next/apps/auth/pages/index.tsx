import { useAuth0, withAuthenticationRequired } from '@auth0/auth0-react';
import styled from 'styled-components';

const StyledPage = styled.div`
  .page {
  }
`;

export function Test() {
  const { isLoading, isAuthenticated, error, user, loginWithRedirect, logout } =
    useAuth0();

  //   if (isLoading) {
  //     return <div>Loading...</div>;
  //   }

  if (isAuthenticated) {
    return (
      <div>
        Hello {user.name} {user}
        <button onClick={() => logout({ returnTo: window.location.origin })}>
          Log out
        </button>
      </div>
    );
  } else {
    return <button onClick={loginWithRedirect}>Log in</button>;
  }
}

export function Index() {
  return (
    <StyledPage>
      <Test />
    </StyledPage>
  );
}

export default withAuthenticationRequired(Index);
