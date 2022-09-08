import { Button } from '@black-pear-joggers/button';
import { Container } from '@black-pear-joggers/container';
import { Stack } from '@black-pear-joggers/stack';

export interface SuccessStepProps {
  onNext: () => void;
}

export function SuccessStep(props: SuccessStepProps) {
  return (
    <Stack backgroundColour="bright">
      <Container>
        <h2>Claim submitted</h2>

        <p>Content here...</p>

        <Button text="Next" onClick={props.onNext} />
      </Container>
    </Stack>
  );
}
