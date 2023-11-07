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

function AthleteDetailsPage() {
  const router = useRouter();
  const { athleteId } = router.query;
  const { athletes, isLoading, isError } = useAthletes();

  const athlete = athletes
    ? athletes.find((athlete) => athlete.athlete_id === Number(athleteId))
    : null;

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
              link={`https://apps.bpj.org.uk/race-results/#/athlete/${athleteId}`}
            ></Button>
          </span>

          <span className="mr-4">
            <Button
              text="Power of 10"
              link={`https://thepowerof10.info/athletes/profile.aspx?athleteid=${athleteId}`}
            ></Button>
          </span>

          <Button
            text="runbritain Rankings"
            link={`https://www.runbritainrankings.com/runners/profile.aspx?athleteid=${athleteId}`}
          ></Button>
        </div>

        <h2>Tools</h2>

        <span className="mr-4">
          <Button
            text="Fetch Performances"
            link={`https://bpj.org.uk/api/public/index.php/fetch/performances/${athleteId}`}
          ></Button>
        </span>

        <Button
          text="Fetch Rankings"
          link={`https://bpj.org.uk/api/public/index.php/fetch/rankings/${athleteId}`}
        ></Button>
      </Container>
    </Stack>
  );
}

export default withAuthenticationRequired(AthleteDetailsPage);
