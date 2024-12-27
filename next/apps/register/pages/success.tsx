import { Button } from '@black-pear-joggers/button';
import { Container } from '@black-pear-joggers/container';
import { faCheckCircle } from '@fortawesome/free-solid-svg-icons';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import { LoadingSpinner } from '../components/loading-spinner';
import { Stack } from '@black-pear-joggers/stack';
import { useUser } from '@black-pear-joggers/core-services';
import { withAuthenticationRequired } from '@auth0/auth0-react';

interface SuccessPageProps {
  athleteId: number;
}

function SuccessPage(props: SuccessPageProps) {
  const { data: user, isLoading } = useUser();

  return (
    <Stack>
      <Container>
        <div className="text-center">
          <FontAwesomeIcon
            className="cursor-pointer mr-2 text-green-600 mb-4"
            size="6x"
            icon={faCheckCircle}
          />

          <h1>Registration complete</h1>

          <p className="mb-6">You&rsquo;re now registered.</p>

          {isLoading ? (
            <div className="inline-block">
              <LoadingSpinner />
            </div>
          ) : user?.athleteId ? (
            <Button
              text="Go to your profile"
              link={`https://bpj.org.uk/profile`}
            />
          ) : (
            <p>Something went wrong - athlete ID unknown</p>
          )}
        </div>
      </Container>
    </Stack>
  );
}

export default withAuthenticationRequired(SuccessPage);
