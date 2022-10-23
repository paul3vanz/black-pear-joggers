import { BackgroundColour, Stack } from '@black-pear-joggers/stack';
import { Button } from '@black-pear-joggers/button';
import { Container } from '@black-pear-joggers/container';

export interface ConfirmStepProps {
  onNext: () => void;
}

export function ConfirmStep(props: ConfirmStepProps) {
  return (
    <Stack backgroundColour={BackgroundColour.Dark}>
      <Container>
        <h2>Confirm your claim details</h2>

        <p>Content here...</p>

        <Button colour="light" text="Next" onClick={props.onNext} />
      </Container>
    </Stack>
  );
}
