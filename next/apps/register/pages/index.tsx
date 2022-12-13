import RegisterForm from '../components/register-form';
import { Athlete, useUser } from '@black-pear-joggers/core-services';
import { Button } from '@black-pear-joggers/button';
import { ConfirmDetails } from '../components/confirm-details';
import { Container } from '@black-pear-joggers/container';
import { LoadingSpinner } from '../components/loading-spinner';
import { NotFound } from '../components/not-found';
import { scrollIntoView } from '@black-pear-joggers/helpers';
import { setAthlete } from '@black-pear-joggers/core-services';
import { Stack } from '@black-pear-joggers/stack';
import { storeAthlete } from '../helpers/athlete-storage';
import { useAthleteIdvCheck } from '@black-pear-joggers/core-services';
import { useEffect, useRef, useState } from 'react';
import { useRouter } from 'next/router';
import { withAuthenticationRequired } from '@auth0/auth0-react';

export interface IdvDetails {
  urn: number;
  dateOfBirth: string;
}

function AdminHomePage() {
  const [currentStep, setCurrentStep] = useState<string>();
  const [idvDetails, setIdvDetails] = useState<IdvDetails>();
  const [isUpdating, setIsUpdating] = useState<boolean>(false);

  const { user, isUserLoading } = useUser();

  const steps = {
    form: useRef<HTMLDivElement>(),
    result: useRef<HTMLDivElement>(),
  };

  const router = useRouter();

  const { athlete, isError, isLoading } = useAthleteIdvCheck(
    idvDetails?.urn,
    idvDetails?.dateOfBirth
  );

  useEffect(() => {
    if (athlete || isError) {
      setCurrentStep('result');
    }
  }, [athlete, isError]);

  useEffect(() => {
    if (currentStep) {
      scrollIntoView(steps[currentStep].current);
    }
  }, [currentStep, steps]);

  async function onConfirmDetails(athlete: Athlete) {
    setIsUpdating(true);
    const success = await setAthlete(athlete.id);
    setIsUpdating(false);

    if (success) {
      storeAthlete(athlete);
      router.push('/success');
    } else {
      alert('There was an error.');
    }
  }

  if (isUserLoading) {
    return <LoadingSpinner />;
  }

  if (user?.athleteId) {
    return (
      <Stack>
        <Container>
          <h1>Already registered</h1>

          <p>
            You've already linked your membership details to your account. If
            you'd like to update your details, please{' '}
            <a href="https://bpj.org.uk/contact?reason=website">contact us</a>.
          </p>

          <h2>Your details</h2>

          <ul className="mb-6 list-inside list-disc">
            <li>
              <strong>First name:</strong> {user.athlete.first_name}
            </li>
            <li>
              <strong>Last name:</strong> {user.athlete.last_name}
            </li>
            <li>
              <strong>Gender:</strong>{' '}
              {user.athlete.gender === 'M' ? 'Male' : 'Female'}
            </li>
            <li>
              <strong>Category:</strong> {user.athlete.category}
            </li>
            <li>
              <strong>Athlete ID:</strong> {user.athlete.athlete_id}
            </li>
          </ul>

          <Button text="Go to dashboard" link="https://bpj.org.uk/profile" />
        </Container>
      </Stack>
    );
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

      <div ref={steps.form}>
        {isLoading}
        <RegisterForm
          onFormSubmit={(idvDetails) => setIdvDetails(idvDetails)}
          isLoading={isLoading}
        />
      </div>

      <div ref={steps.result}>
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
              setCurrentStep('form');
              setIdvDetails(null);
            }}
          />
        )}
      </div>
    </>
  );
}

export default withAuthenticationRequired(AdminHomePage);
