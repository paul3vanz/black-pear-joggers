import { Athlete, useAthletes } from '@black-pear-joggers/core-services';
import { AthleteStep } from '../components/steps/athlete-step';
import { ConfirmStep } from '../components/steps/confirm-step';
import { ContactStep } from '../components/steps/contact-step';
import { Container } from '@black-pear-joggers/container';
import { NameStep } from '../components/steps/name-step';
import { ResultsStep } from '../components/steps/results-step';
import { Stack } from '@black-pear-joggers/stack';
import { stepNamesToRefs } from '@black-pear-joggers/helpers';
import { SuccessStep } from '../components/steps/success-step';
import { useRef, useState } from 'react';
import { useRouter } from 'next/router';
import { withAuthenticationRequired } from '@auth0/auth0-react';

type FormData = {
  firstName: string;
  lastName: string;
};

function AwardClaimHomePage() {
  const stepNames = [
    'name',
    'athlete',
    'results',
    'contact',
    'confirm',
    'success',
  ] as const;
  const steps = stepNamesToRefs([...stepNames]);

  const [currentStep, setCurrentStep] =
    useState<typeof stepNames[number]>('name');

  const { athletes } = useAthletes();

  const [firstName, setFirstName] = useState<string>();
  const [lastName, setLastName] = useState<string>();
  const [athlete, setAthlete] = useState<Athlete>();

  function handleNameStepComplete(formData: {
    firstName: string;
    lastName: string;
  }) {
    setFirstName(formData.firstName);
    setLastName(formData.lastName);
    setCurrentStep('athlete');
  }

  function handleAthleteStepComplete(athlete: Athlete) {
    console.log('handleAthleteStepComplete', athlete);
    setAthlete(athlete);
    setCurrentStep('results');
  }

  return (
    <>
      <Stack>
        <Container>
          <h1>Claim award</h1>

          <p>
            You can claim your award if in any calendar year you have been a
            member of the club throughout the period over which all the runs
            have taken place and you have the required standard for at least
            three of the five distances in your age category (your age counting
            as of the date of the run).
          </p>
        </Container>
      </Stack>

      <div ref={steps.name}>
        {currentStep === 'name' && (
          <NameStep onNext={handleNameStepComplete} isLoading={false} />
        )}
      </div>

      <div ref={steps.athlete}>
        {currentStep === 'athlete' && (
          <AthleteStep
            firstName={firstName}
            lastName={lastName}
            athlete={athlete}
            onNext={handleAthleteStepComplete}
          />
        )}
      </div>

      <div ref={steps.results}>
        {currentStep === 'results' && <ResultsStep onNext={() => {}} />}
      </div>

      <div ref={steps.contact}>
        {currentStep === 'contact' && <ContactStep onNext={() => {}} />}
      </div>

      <div ref={steps.confirm}>
        {currentStep === 'confirm' && <ConfirmStep onNext={() => {}} />}
      </div>

      <div ref={steps.success}>
        {currentStep === 'success' && <SuccessStep onNext={() => {}} />}
      </div>
    </>
  );
}

export default withAuthenticationRequired(AwardClaimHomePage);
