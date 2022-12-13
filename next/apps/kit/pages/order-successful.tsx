import { Button } from '@black-pear-joggers/button';
import { Container } from '@black-pear-joggers/container';
import { Stack } from '@black-pear-joggers/stack';

export default function OrderSuccessfulPage() {
  return (
    <Stack>
      <Container>
        <h1>Thank you for your order</h1>

        <p>
          Please get in touch with our kit coordinator Avril Munday to arrange
          collection of your kit.
        </p>

        <Button
          text="Contact Avril"
          link="https://bpj.org.uk/contact?reason=kit"
        />
      </Container>
    </Stack>
  );
}
