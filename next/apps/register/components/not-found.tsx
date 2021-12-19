import Link from 'next/link';
import { Button } from '@black-pear-joggers/button';
import { Container } from '@black-pear-joggers/container';
import { Stack } from '@black-pear-joggers/stack';

export interface NotFoundProps {
  onGoBack: () => void;
}

export function NotFound(props: NotFoundProps) {
  return (
    <Stack backgroundColour="bright">
      <Container>
        <h2>We can't find your details</h2>

        <p>First, please check your details are correct.</p>
        <p>If you've recently joined you may need to wait a little longer.</p>
        <p>
          If in doubt,{' '}
          <Link href="https://bpj.org.uk/contact-the-club">get in touch</Link>{' '}
          and we'll look into it.
        </p>

        <Button text="Back" onClick={props.onGoBack} />
      </Container>
    </Stack>
  );
}
