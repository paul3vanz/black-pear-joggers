import { Stack } from '@black-pear-joggers/stack';
import { Container } from '@black-pear-joggers/container';
import { Button } from '@black-pear-joggers/button';
import { config } from '../../helpers/config';

export default function Tools() {
  return (
    <Stack>
      <Container>
        <h1>Tools</h1>

        <h2>Fetch</h2>

        <p>
          <Button
            text="Fetch all performances"
            link={`${config.baseApiUrl}/fetch/performances`}
          ></Button>
        </p>

        <p>
          <Button
            text="Fetch all rankings"
            link={`${config.baseApiUrl}/fetch/rankings`}
          ></Button>
        </p>

        <p>
          <Button
            text="Sync magic mile"
            link={`${config.baseApiUrl}/fetch/syncmagicmile`}
          ></Button>
        </p>

        <p>
          <Button
            text="Update personal bests"
            link={`${config.baseApiUrl}/fetch/updatepersonalbests`}
          ></Button>
        </p>
      </Container>
    </Stack>
  );
}
