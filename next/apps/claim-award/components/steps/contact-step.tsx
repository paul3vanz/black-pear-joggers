import { Button } from '@black-pear-joggers/button';
import { Container } from '@black-pear-joggers/container';
import { Stack } from '@black-pear-joggers/stack';

export interface ContactStepProps {
  onNext: () => void;
}

export function ContactStep(props: ContactStepProps) {
  return (
    <Stack backgroundColour="light">
      <Container>
        <h2>Add your contact details</h2>

        <p>Content here...</p>

        <Button text="Next" onClick={props.onNext} />
      </Container>
    </Stack>
  );
}
