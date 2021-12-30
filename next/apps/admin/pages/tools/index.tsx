import { Button } from '@black-pear-joggers/button';
import { config } from '@black-pear-joggers/core-services';
import { Container } from '@black-pear-joggers/container';
import { Stack } from '@black-pear-joggers/stack';

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
            link={`${config.baseApiUrl}/performances/syncmagicmile`}
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
