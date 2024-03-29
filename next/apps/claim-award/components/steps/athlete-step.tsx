import { Athlete, useAthletes } from '@black-pear-joggers/core-services';
import { BackgroundColour, Stack } from '@black-pear-joggers/stack';
import { Button } from '@black-pear-joggers/button';
import { Container } from '@black-pear-joggers/container';

export interface AthleteStepProps {
  firstName?: string;
  lastName?: string;
  athlete: Athlete;
  onNext: (e: Athlete) => void;
}

export function AthleteStep(props: AthleteStepProps) {
  const { athletes } = useAthletes();

  return (
    <Stack backgroundColour={BackgroundColour.Light}>
      <Container>
        <h2>Athlete details</h2>

        <pre>
          {JSON.stringify(
            athletes &&
              athletes.filter(
                (athlete) => athlete.first_name === props.firstName
              ),
            null,
            ' '
          )}
        </pre>

        <Button colour="light" text="Next" onClick={() => props.onNext(null)} />
      </Container>
    </Stack>
  );
}
