import { BackgroundColour, Stack } from '@black-pear-joggers/stack';
import { Button } from '@black-pear-joggers/button';
import { Container } from '@black-pear-joggers/container';

export interface SuccessStepProps {
  onNext: () => void;
}

export function SuccessStep(props: SuccessStepProps) {
  return (
    <Stack backgroundColour={BackgroundColour.Bright}>
      <Container>
        <h2>Claim submitted</h2>

        <p>Content here...</p>

        <Button text="Next" onClick={props.onNext} />
      </Container>
    </Stack>
  );
}
