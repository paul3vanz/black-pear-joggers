import { Athlete, useAthletes } from '@black-pear-joggers/core-services';
import { ConfirmStep } from '../components/steps/confirm-step';
import { ContactStep } from '../components/steps/contact-step';
import { Container } from '@black-pear-joggers/container';
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

      <ResultsStep onNext={() => {}} />
    </>
  );
}

export default withAuthenticationRequired(AwardClaimHomePage);
