import { Button } from '@black-pear-joggers/button';
import { Container } from '@black-pear-joggers/container';
import { Stack } from '@black-pear-joggers/stack';

export interface ConfirmStepProps {
  onNext: () => void;
}

export function ConfirmStep(props: ConfirmStepProps) {
  return (
    <Stack backgroundColour="dark">
      <Container>
        <h2>Confirm your claim details</h2>

        <p>Content here...</p>

        <Button colour="light" text="Next" onClick={props.onNext} />
      </Container>
    </Stack>
  );
}
