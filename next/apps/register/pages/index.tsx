import RegisterForm from '../components/register-form';
import { Athlete } from '../../auth/services/athletes.interface';
import { ConfirmDetails } from '../components/confirm-details';
import { Container } from '@black-pear-joggers/container';
import { NotFound } from '../components/not-found';
import { scrollIntoView } from '@black-pear-joggers/helpers';
import { setAthlete } from '../../auth/services/user';
import { Stack } from '@black-pear-joggers/stack';
import { useAthleteIdvCheck } from '../../auth/services/athletes';
import { useEffect, useRef, useState } from 'react';
import { useRouter } from 'next/router';
import { withAuthenticationRequired } from '@auth0/auth0-react';


export interface IdvDetails {
  urn: number;
  dateOfBirth: string;
}

function AdminHomePage() {
  const [idvDetails, setIdvDetails] = useState<IdvDetails>();

  const step1 = useRef<HTMLDivElement>();
  const step2 = useRef<HTMLDivElement>();

  const router = useRouter();

  const { athlete, isError } = useAthleteIdvCheck(
    idvDetails?.urn,
    idvDetails?.dateOfBirth
  );

  useEffect(() => {
    scrollIntoView(step2.current);
  }, [athlete, isError]);

  async function onConfirmDetails(athlete: Athlete) {
    const success = await setAthlete(athlete.id);

    if (success) {
      router.push('/success');
    } else {
      alert('There was an error.');
    }
  }

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

      <div ref={step1}>
        <RegisterForm
          onFormSubmit={(idvDetails) => setIdvDetails(idvDetails)}
        />
      </div>

      <div ref={step2}>
        {athlete && !isError && (
          <ConfirmDetails
            athlete={athlete}
            onConfirmDetails={onConfirmDetails}
          />
        )}

        {isError && (
          <NotFound
            onGoBack={() => {
              scrollIntoView(step1.current);
              setIdvDetails(null);
            }}
          />
        )}
      </div>
    </>
  );
}

export default withAuthenticationRequired(AdminHomePage);
