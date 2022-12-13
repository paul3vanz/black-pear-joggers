import Link from 'next/link';
import { BackgroundColour, Stack } from '@black-pear-joggers/stack';
import { Button } from '@black-pear-joggers/button';
import { Container } from '@black-pear-joggers/container';

export interface NotFoundProps {
  onGoBack: () => void;
}

export function NotFound(props: NotFoundProps) {
  return (
    <Stack backgroundColour={BackgroundColour.Bright}>
      <Container>
        <h2>We can&rsquo;t find your details</h2>

        <p>First, please check your details are correct.</p>
        <p>
          If you&rsquo;ve recently joined you may need to wait a little longer.
        </p>
        <p>
          If in doubt,{' '}
          <Link href="https://bpj.org.uk/contact?reason=website">
            get in touch
          </Link>{' '}
          and we&rsquo;ll look into it.
        </p>

        <Button text="Back" onClick={props.onGoBack} />
      </Container>
    </Stack>
  );
}
