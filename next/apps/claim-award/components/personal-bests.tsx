import { Container } from '@black-pear-joggers/container';
import {
  Performance,
  usePerformances,
  useUser,
} from '@black-pear-joggers/core-services';
import { shortUkDate } from '@black-pear-joggers/helpers';
import { BackgroundColour, Stack } from '@black-pear-joggers/stack';
import { useMemo } from 'react';
import { Award } from '../types/award';
import { AwardBadge } from './award-badge';

export function PersonalBests() {
  const { data: userProfile, isLoading: isLoadingUser } = useUser();
  const { data: results, isLoading: isLoadingPerformances } = usePerformances(
    userProfile?.athleteId
  );

  const personalBests = useMemo(() => {
    return results?.data ? getPersonalBests(results?.data) : null;
  }, [results]);

  return (
    <Stack backgroundColour={BackgroundColour.Bright}>
      <Container>
        <h2>Personal bests</h2>

        {isLoadingUser || isLoadingPerformances ? (
          <>
            <p>Loading...</p>
          </>
        ) : (
          <>
            <p className="mb-8">
              These are your personal bests across all years for the event
              distances that count towards the awards. Well done!
            </p>
            <div className="flex gap-4">
              {personalBests.map((personalBest) => (
                <PersonalBestCard
                  key={personalBest.event}
                  summary={personalBest}
                />
              ))}
            </div>
          </>
        )}
      </Container>
    </Stack>
  );
}

function PersonalBestCard(props: { summary: PersonalBestSummary }) {
  return (
    <div className="bg-white w-full rounded-md p-4 text-center">
      <p className="mb-0">{props.summary.event}</p>
      <p className="text-xl font-semibold mb-1">{props.summary.time}</p>
      <p className="text-xs mb-3">{shortUkDate(props.summary.date)}</p>
      <AwardBadge award={props.summary.award} />
    </div>
  );
}

type PersonalBestSummary = {
  event: string;
  time: string;
  timeParsed: string;
  date: string;
  award: Award;
};

function getPersonalBests(performances: Performance[]): PersonalBestSummary[] {
  const personalBests: PersonalBestSummary[] = [];

  const allowedEvents = [
    '1M',
    'Mile',
    '5K',
    'parkrun',
    '10K',
    '10KMT',
    'HM',
    'HMMT',
    'Mar',
    'MarMT',
  ];

  performances
    .filter(
      (performance) =>
        performance.isPersonalBest && allowedEvents.includes(performance.event)
    )
    .forEach((performance) => {
      const normalisedEvent = performance.event
        .replace('MT', '')
        .replace('1M', 'Mile')
        .replace('parkrun', '5K')
        .replace('Mar', 'Marathon')
        .replace('HM', 'Half Marathon');

      const eventIndex = personalBests.findIndex(
        (_) => _.event === normalisedEvent
      );

      console.log('eventIndex', eventIndex);

      if (eventIndex === -1) {
        personalBests.push({
          event: normalisedEvent,
          time: performance.time,
          timeParsed: performance.timeParsed,
          date: performance.date,
          award: performance.award,
        });
      }
    });

  return personalBests.sort((a, b) =>
    Number(a.timeParsed) < Number(b.timeParsed) ? -1 : 0
  );
}
