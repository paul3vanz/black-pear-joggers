import { BackgroundColour, Stack } from '@black-pear-joggers/stack';
import { Button } from '@black-pear-joggers/button';
import { Container } from '@black-pear-joggers/container';

export interface ContactStepProps {
  onNext: () => void;
}

export function ContactStep(props: ContactStepProps) {
  return (
    <Stack backgroundColour={BackgroundColour.Light}>
      <Container>
        <h2>Add your contact details</h2>

        <p>Content here...</p>

        <Button text="Next" onClick={props.onNext} />
      </Container>
    </Stack>
  );
}
