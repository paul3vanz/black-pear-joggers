import RegisterForm from '../components/register-form';
import { Button } from '@black-pear-joggers/button';
import { Container } from '@black-pear-joggers/container';
import { Stack } from '@black-pear-joggers/stack';
import { useState } from 'react';
import { withAuthenticationRequired } from '@auth0/auth0-react';

function AdminHomePage() {
  const [idvCheck, setIdvCheck] = useState<any>();

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

          <RegisterForm onIdvCheck={setIdvCheck} />
        </Container>
      </Stack>

      {idvCheck ? (
        <Stack backgroundColour="bright">
          <Container>
            <h2>Check your details</h2>

            <p>We think we found you! Please check the details below.</p>

            <pre className="mb-6">{JSON.stringify(idvCheck, null, '  ')}</pre>

            <Button text="Confirm" onClick={console.log} />
          </Container>
        </Stack>
      ) : null}
    </>
  );
}

export default withAuthenticationRequired(AdminHomePage);
