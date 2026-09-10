import { Container } from '@black-pear-joggers/container';
import { BackgroundColour, Stack } from '@black-pear-joggers/stack';
import { ButtonLightTextDarkBackground } from '@black-pear-joggers/button';
import {
  submitClaim,
  useMyAwardClaims,
  usePerformances,
  useStandards,
  useUser,
} from '@black-pear-joggers/core-services';
import { useAuth0 } from '@auth0/auth0-react';
import { useMemo, useState } from 'react';
import {
  candidateRacesFromPerformances,
  ClaimRaceInput,
  ClaimWizardRaces,
  computeClaimAward,
  racesAreValid,
} from './claim-wizard-races';

type Step = 'category' | 'races' | 'review' | 'submitted';

export function ClaimWizard() {
  const { data: userProfile } = useUser();
  const { user: auth0User } = useAuth0();
  const athleteId = userProfile?.athleteId;
  const athlete = userProfile?.athlete;

  const { data: performancesResult } = usePerformances(athleteId);
  const { standards } = useStandards();
  const { myAwardClaims, isLoading: isLoadingMyClaims } =
    useMyAwardClaims(athleteId);

  const [step, setStep] = useState<Step>('category');
  const [races, setRaces] = useState<ClaimRaceInput[]>([]);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [submitError, setSubmitError] = useState<string>();

  const candidates = useMemo(
    () =>
      performancesResult?.data && athlete
        ? candidateRacesFromPerformances(performancesResult.data, athlete.category)
        : [],
    [performancesResult, athlete]
  );

  const existingActiveClaimForCategory = (myAwardClaims || []).find(
    (claim) => !claim.archived && claim.category === athlete?.category
  );

  const award = computeClaimAward(races);

  async function onSubmit() {
    if (!athlete) {
      return;
    }

    setIsSubmitting(true);
    setSubmitError(undefined);

    try {
      await submitClaim({
        gender: athlete.gender,
        category: athlete.category,
        award,
        firstName: athlete.first_name,
        lastName: athlete.last_name,
        email: auth0User?.email ?? '',
        races: races.map(({ distance, date, race, time, timeParsed, award }) => ({
          distance,
          date,
          race,
          time,
          timeParsed,
          award,
        })),
      });

      setStep('submitted');
    } catch (e) {
      setSubmitError(
        'Something went wrong submitting your claim. Please try again.'
      );
    } finally {
      setIsSubmitting(false);
    }
  }

  if (!athlete || isLoadingMyClaims) {
    return (
      <Stack backgroundColour={BackgroundColour.White}>
        <Container>
          <p>Loading...</p>
        </Container>
      </Stack>
    );
  }

  if (step === 'submitted') {
    return (
      <Stack backgroundColour={BackgroundColour.White}>
        <Container>
          <h2>Claim submitted</h2>
          <p>
            Thanks &mdash; your claim has been submitted and is now{' '}
            <strong>pending verification</strong> by the club. You&apos;ll be
            able to view and print your certificate once it&apos;s been
            verified.
          </p>
        </Container>
      </Stack>
    );
  }

  return (
    <Stack backgroundColour={BackgroundColour.White}>
      <Container>
        <h2>Claim an award</h2>

        {existingActiveClaimForCategory && (
          <div className="p-4 bg-orange-100 mb-4">
            <p className="mb-0">
              You already have a{' '}
              {existingActiveClaimForCategory.verified
                ? 'verified'
                : 'pending'}{' '}
              claim for the {athlete.category.replace('SEN', 'Senior')}{' '}
              category. Submitting another may cause confusion &mdash; contact
              the club if you need to amend an existing claim.
            </p>
          </div>
        )}

        {step === 'category' && (
          <>
            <p className="mb-4">
              You&apos;re claiming as{' '}
              <strong>
                {athlete.first_name} {athlete.last_name}
              </strong>
              , in the{' '}
              <strong>
                {athlete.gender === 'M' ? 'Male' : 'Female'}{' '}
                {athlete.category.replace('SEN', 'Senior')}
              </strong>{' '}
              category.
            </p>

            <ButtonLightTextDarkBackground
              text="Start"
              onClick={() => setStep('races')}
            />
          </>
        )}

        {step === 'races' && (
          <>
            <ClaimWizardRaces
              gender={athlete.gender}
              category={athlete.category}
              standards={standards || []}
              candidates={candidates}
              value={races}
              onChange={setRaces}
            />

            <div className="mt-4 flex gap-3">
              <ButtonLightTextDarkBackground
                text="Back"
                onClick={() => setStep('category')}
              />

              <ButtonLightTextDarkBackground
                text="Review claim"
                onClick={() => racesAreValid(races) && setStep('review')}
              />
            </div>
          </>
        )}

        {step === 'review' && (
          <>
            <h3 className="text-xl font-semibold mb-2">Review your claim</h3>

            <p>
              <strong>{award || 'No award'}</strong> standard,{' '}
              {athlete.gender === 'M' ? 'Male' : 'Female'}{' '}
              {athlete.category.replace('SEN', 'Senior')}
            </p>

            <ul className="mb-4 list-disc list-inside">
              {races.map((race) => (
                <li key={race.key}>
                  {race.distance} &mdash; {race.time} &mdash; {race.race}
                </li>
              ))}
            </ul>

            <p className="mb-4">
              Submitting as{' '}
              <strong>
                {athlete.first_name} {athlete.last_name}
              </strong>
              .
            </p>

            {submitError && <p className="text-red-600">{submitError}</p>}

            <div className="flex gap-3">
              <ButtonLightTextDarkBackground
                text="Back"
                onClick={() => setStep('races')}
              />

              <ButtonLightTextDarkBackground
                text={isSubmitting ? 'Submitting...' : 'Submit claim'}
                onClick={() => !isSubmitting && onSubmit()}
              />
            </div>
          </>
        )}
      </Container>
    </Stack>
  );
}
