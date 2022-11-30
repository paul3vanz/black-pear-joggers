import { Button } from '@black-pear-joggers/button';
import { Container } from '@black-pear-joggers/container';
import { PersonalBestsTable } from './personal-bests-table';
import { Stack } from '@black-pear-joggers/stack';

export function RecentPersonalBests() {
  return (
    <Stack>
      <Container>
        <h2 className="flex">
          <span>Recent personal bests</span>
          <span className="flex items-center">
            <span className="rounded-md bg-black text-white text-sm ml-4 px-3 py-1 font-mono">
              BETA
            </span>
          </span>
        </h2>

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
