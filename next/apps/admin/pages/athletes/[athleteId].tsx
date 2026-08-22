import Link from 'next/link';
import { Button } from '@black-pear-joggers/button';
import { Container } from '@black-pear-joggers/container';
import { LoadingSpinner } from '../../components/loading-spinner';
import { MembershipDetail } from '../../components/shared/membership-detail';
import { Stack } from '@black-pear-joggers/stack';
import { UpdateAthleteForm } from '../../components/athletes/update-athlete-form';
import { useAthletes } from '@black-pear-joggers/core-services';
import { useRouter } from 'next/router';
import { withAuthenticationRequired } from '@auth0/auth0-react';
import { PaymentDetail } from 'apps/admin/components/shared/payment-detail';
import { powerOfTenAthleteUrl } from '@black-pear-joggers/helpers';
import { useState } from 'react';
import { describeFetch, fetchAthlete } from '../../services/power-of-ten';
import { FetchAthleteResult } from '../../types/power-of-ten';

function AthleteDetailsPage() {
  const router = useRouter();
  const { athleteId } = router.query;
  const { athletes, isLoading, isError } = useAthletes();

  const athlete = athletes
    ? athletes.find((athlete) => athlete.athlete_id === Number(athleteId))
    : null;

  const [isFetching, setIsFetching] = useState(false);
  const [result, setResult] = useState<FetchAthleteResult | null>(null);

  // One call covers the performances and the handicap, because the API reads
  // the athlete's Power of 10 page once and takes both off it.
  async function fetchFromPowerOfTen() {
    setIsFetching(true);
    setResult(null);

    try {
      setResult(await fetchAthlete(Number(athleteId)));
    } catch (error) {
      setResult({
        success: false,
        athleteId: Number(athleteId),
        name: null,
        message: error instanceof Error ? error.message : 'Failed',
      } as FetchAthleteResult);
    } finally {
      setIsFetching(false);
    }
  }

  const powerOfTenUrl = powerOfTenAthleteUrl(athlete?.po10_guid);

  if (isLoading) {
    return (
      <Stack>
        <Container>
          <div className="flex justify-center">
            <LoadingSpinner />
          </div>
        </Container>
      </Stack>
    );
  }

  if (!athlete) {
    return null;
  }

  return (
    <Stack>
      <Container>
        <p>
          <Link href={`/athletes`}>Back to athletes</Link>
        </p>

        <h1>{athlete.first_name + ' ' + athlete.last_name}</h1>

        <UpdateAthleteForm athlete={athlete} />

        <h2>Membership</h2>

        {athlete.membership ? (
          <MembershipDetail membership={athlete.membership} />
        ) : (
          <p>No membership record found.</p>
        )}

        <h2>Payment</h2>

        {athlete.payments && athlete.payments.length ? (
          <PaymentDetail payment={athlete.payments[0]} />
        ) : (
          <p>No payment record found.</p>
        )}

        <h2>Profiles</h2>

        <div className="mb-4">
          <span className="mr-4">
            <Button
              text="BPJ Race Results"
              link={`https://apps.bpj.org.uk/race-results/#/athlete/${athlete.athlete_id}`}
            ></Button>
          </span>

          {powerOfTenUrl ? (
            <Button text="Power of 10" link={powerOfTenUrl}></Button>
          ) : (
            <span className="text-gray-600">
              No Power of 10 profile is linked to this athlete, so there is
              nothing to fetch.
            </span>
          )}
        </div>

        <h2>Tools</h2>

        <div className="mb-4">
          <Button
            text={isFetching ? 'Fetching...' : 'Fetch from Power of 10'}
            onClick={() => (isFetching ? undefined : fetchFromPowerOfTen())}
          ></Button>
        </div>

        {result && (
          <p
            className={
              result.success
                ? 'text-green-700 font-medium'
                : 'text-red-700 font-medium'
            }
          >
            {result.success ? 'Fetched. ' : 'Failed. '}
            {describeFetch(result)}
          </p>
        )}
      </Container>
    </Stack>
  );
}

export default withAuthenticationRequired(AthleteDetailsPage);
