import { Button } from '@black-pear-joggers/button';
import { Container } from '@black-pear-joggers/container';
import { PersonalBestsTable } from './personal-bests-table';
import { Stack } from '@black-pear-joggers/stack';

export function RecentPersonalBests() {
  return (
    <Stack>
      <Container>
        <h2>Recent personal bests</h2>

        <p>
          Well done to the following members who have recently ran PBs over
          recent times.
        </p>

        <PersonalBestsTable />

        <Button
          text="More race results"
          link="https://apps.bpj.org.uk/race-results/"
        />
      </Container>
    </Stack>
  );
}
