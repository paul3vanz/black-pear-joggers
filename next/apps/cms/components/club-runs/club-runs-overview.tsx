import Link from 'next/link';
import { BackgroundColour, Stack } from '@black-pear-joggers/stack';
import { Card } from '../card';
import { ClubRun } from '../../types/club-run.types';
import { Container } from '@black-pear-joggers/container';
import { urlFor } from '@black-pear-joggers/sanity';

type ClubRunsOverviewProps = {
  runs: ClubRun[];
};

export function ClubRunsOverview(props: ClubRunsOverviewProps) {
  return (
    <Stack backgroundColour={BackgroundColour.Bright}>
      <Container wide={true}>
        <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-6">
          {props.runs.sort(sortByDayOfWeek).map((run) => {
            return (
              <div key={run._id} className="flex">
                <Card
                  imageUrl={
                    run.image.externalUrl ||
                    urlFor(run.image).width(400).height(400).url()
                  }
                  headline={run.title}
                  link={`/club-runs/${run.slug.current}`}
                  content={
                    <p>
                      <strong>{run.day}</strong> at <strong>{run.time}</strong>
                    </p>
                  }
                />
              </div>
            );
          })}
        </div>
      </Container>
    </Stack>
  );
}

function sortByDayOfWeek(a: ClubRun, b: ClubRun) {
  const dayOrder = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  return dayOrder.indexOf(a.day) - dayOrder.indexOf(b.day);
}
