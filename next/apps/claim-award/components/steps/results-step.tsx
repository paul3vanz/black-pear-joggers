import { Button } from '@black-pear-joggers/button';
import { Container } from '@black-pear-joggers/container';
import { usePerformances, useUser } from '@black-pear-joggers/core-services';
import { BackgroundColour, Stack } from '@black-pear-joggers/stack';
import { useMemo } from 'react';

export interface ResultsStepProps {
  onNext: () => void;
}
enum Award {
  Bronze = 1,
  Silver = 2,
  Gold = 3,
  Platinum = 4,
}

export function ResultsStep(props: ResultsStepProps) {
  const { data: userProfile } = useUser();
  const results = usePerformances(450606);

  const performances = useMemo(() => {
    return results?.data ? groupPerformances(results?.data?.data) : null;
  }, [results]);

  return (
    <Stack backgroundColour={BackgroundColour.Light}>
      <Container>
        <h2>Your awards</h2>

        <p>See the awards you have earned</p>

        <ul>
          {performances &&
            Object.keys(performances)
              .reverse()
              .map((year) => (
                <>
                  <h2>{year}</h2>

                  {Object.keys(performances[year]).map((category) => (
                    <>
                      <h3>{category}</h3>

                      {performances[year][category].award ? (
                        <>
                          <p>
                            This certificate is awarded to
                            <br />
                            <strong>
                              {userProfile.athlete.first_name}{' '}
                              {userProfile.athlete.last_name}
                            </strong>
                            <br />
                            For achieving the Black Pear Joggers{' '}
                            <strong>
                              {Award[performances[year][category].award]}
                            </strong>{' '}
                            Standard in
                            <br />
                            the {userProfile.athlete.gender}{' '}
                            <strong>{category}</strong> category for{' '}
                            <strong>{year}</strong> with the following runs
                          </p>
                          <table>
                            {Object.keys(
                              performances[year][category].performances
                            ).map((event) => (
                              <tr>
                                <td>
                                  {
                                    performances[year][category].performances[
                                      event
                                    ].date
                                  }
                                </td>
                                <td>
                                  {
                                    performances[year][category].performances[
                                      event
                                    ].time
                                  }
                                </td>
                                <td>
                                  {
                                    performances[year][category].performances[
                                      event
                                    ].race
                                  }
                                </td>
                                <td>
                                  {
                                    Award[
                                      performances[year][category].performances[
                                        event
                                      ].award
                                    ]
                                  }
                                </td>
                              </tr>
                            ))}
                          </table>
                        </>
                      ) : (
                        <p>No award earned</p>
                      )}
                    </>
                  ))}
                </>
              ))}
        </ul>

        <Button text="Next" onClick={props.onNext} />
      </Container>
    </Stack>
  );
}

function groupPerformances(data) {
  const groupedData = {};

  const eventDistances = {
    '1M': 'Mile',
    Mile: 'Mile',
    '5K': '5K',
    parkrun: '5K',
    '10K': '10K',
    '10KMT': '10K',
    HM: 'HM',
    HMMT: 'HM',
    Mar: 'Mar',
    MarMT: 'Mar',
  };

  data.forEach((entry) => {
    if (!entry.award) {
      return;
    }
    const year = new Date(entry.date).getFullYear();
    const category = entry.category;
    const event = entry.event;

    if (!groupedData[year]) {
      groupedData[year] = {};
    }
    if (!groupedData[year][category]) {
      groupedData[year][category] = { performances: {}, award: null };
    }
    if (!groupedData[year][category].performances[eventDistances[event]]) {
      groupedData[year][category].performances[eventDistances[event]] = entry;
    }

    if (
      Number(entry.timeParsed) <
      Number(
        groupedData[year][category].performances[eventDistances[event]]
          .timeParsed
      )
    ) {
      groupedData[year][category].performances[eventDistances[event]] = entry;
    }

    if (Object.keys(groupedData[year][category].performances).length >= 3) {
      groupedData[year][category].award = Math.min(
        ...Object.values(groupedData[year][category].performances).map(
          (a: any) => a.award
        )
      );
    }
  });

  return groupedData;
}
