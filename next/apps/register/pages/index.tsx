import RegisterForm from '../components/register-form';
import { Athlete } from '@black-pear-joggers/core-services';
import { ConfirmDetails } from '../components/confirm-details';
import { Container } from '@black-pear-joggers/container';
import { NotFound } from '../components/not-found';
import { scrollIntoView } from '@black-pear-joggers/helpers';
import { setAthlete } from '@black-pear-joggers/core-services';
import { Stack } from '@black-pear-joggers/stack';
import { useAthleteIdvCheck } from '@black-pear-joggers/core-services';
import { useEffect, useRef, useState } from 'react';
import { useRouter } from 'next/router';
import { withAuthenticationRequired } from '@auth0/auth0-react';

export interface IdvDetails {
  urn: number;
  dateOfBirth: string;
}

function AdminHomePage() {
  const [idvDetails, setIdvDetails] = useState<IdvDetails>();
  const [isUpdating, setIsUpdating] = useState<boolean>(false);

  const step1 = useRef<HTMLDivElement>();
  const step2 = useRef<HTMLDivElement>();

  const router = useRouter();

  const { athlete, isError, isLoading } = useAthleteIdvCheck(
    idvDetails?.urn,
    idvDetails?.dateOfBirth
  );

  useEffect(() => {
    scrollIntoView(step2.current);
  }, [athlete, isError, isLoading]);

  async function onConfirmDetails(athlete: Athlete) {
    setIsUpdating(true);

    const success = await setAthlete(athlete.id);

    setIsUpdating(false);

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
            Now you&rsquo;re logged in, we need to link up your membership
            details. You&rsquo;ll need your England Athletics registration
            number (URN) that would have been given to you when your membership
            was set up - it&rsquo;ll be on your membership card.
          </p>
        </Container>
      </Stack>

      <div ref={step1}>
        {isLoading}
        <RegisterForm
          onFormSubmit={(idvDetails) => setIdvDetails(idvDetails)}
          isLoading={isLoading}
        />
      </div>

      <div ref={step2}>
        {athlete && !isError && (
          <ConfirmDetails
            isUpdating={isUpdating}
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
