import { Button } from '@black-pear-joggers/button';
import { Container } from '@black-pear-joggers/container';
import { faCheckCircle } from '@fortawesome/free-solid-svg-icons';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import { Stack } from '@black-pear-joggers/stack';
import { withAuthenticationRequired } from '@auth0/auth0-react';

interface SuccessPageProps {
  athleteId: number;
}

function SuccessPage(props: SuccessPageProps) {
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

          <p className="mb-6">You're now registered. </p>

          <Button
            text="Go to your results"
            link={`https://apps.bpj.org.uk/race-results/#/athlete/${props.athleteId}`}
          />
        </div>
      </Container>
    </Stack>
  );
}

export default withAuthenticationRequired(SuccessPage);
