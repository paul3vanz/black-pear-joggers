import { Button } from '@black-pear-joggers/button';
import { Container } from '@black-pear-joggers/container';
import { Stack } from '@black-pear-joggers/stack';

export interface ResultsStepProps {
  onNext: () => void;
}

export function ResultsStep(props: ResultsStepProps) {
  return (
    <Stack>
      <Container>
        <h2>Enter your results</h2>

        <p>Enter your results</p>

        <Button text="Next" onClick={props.onNext} />
      </Container>
    </Stack>
  );
}
