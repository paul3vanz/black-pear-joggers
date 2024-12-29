import { Button } from '@black-pear-joggers/button';
import { Container } from '@black-pear-joggers/container';
import {
  GenderFull,
  usePerformances,
  useUser,
} from '@black-pear-joggers/core-services';
import { shortUkDate } from '@black-pear-joggers/helpers';
import { BackgroundColour, Stack } from '@black-pear-joggers/stack';
import { useMemo } from 'react';
import { CertificatePreview } from '../certificate-preview/certificate-preview';

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
  const results = usePerformances(userProfile?.athleteId);

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
                  {Object.keys(performances[year]).map((category) => (
                    <>
                      {performances[year][category].award ? (
                        <div className="bg-white mb-8 w-auto p-4 relative">
                          {/* <CertificatePreview /> */}
                          <img
                            src={`https://bpj.org.uk/certificate/certificate-badge-${Award[
                              performances[year][category].award
                            ].toLowerCase()}.png`}
                            className="mb-4 w-20 right-4 absolute top-4"
                            alt=""
                          />

                          <p className="uppercase font-semibold mb-0 text-xl">
                            Club Standard
                          </p>

                          <p className="uppercase text-orange-400 font-extrabold text-3xl">
                            Certificate
                          </p>

                          <p className="border-l-orange-400 pl-4 border-l-4 ml-4">
                            This certificate is awarded to
                            <br />
                            <strong className="text-orange-400 text-3xl">
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
                            the{' '}
                            <strong>
                              {GenderFull[userProfile.athlete.gender]}{' '}
                              {category.replace('SEN', 'Senior')}
                            </strong>{' '}
                            category for <strong>{year}</strong> with the
                            following runs:
                          </p>
                          <table className="ml-8">
                            <thead>
                              <tr>
                                <th className="text-orange-400">Date</th>
                                <th className="text-orange-400">Time</th>
                                <th className="text-orange-400">Event</th>
                                <th className="text-orange-400">Standard</th>
                              </tr>
                            </thead>

                            <tbody>
                              {Object.keys(
                                performances[year][category].performances
                              ).map((event) => (
                                <tr
                                  key={
                                    performances[year][category].performances[
                                      event
                                    ].id
                                  }
                                >
                                  <td className="pr-4">
                                    {shortUkDate(
                                      performances[year][category].performances[
                                        event
                                      ].date
                                    )}
                                  </td>
                                  <td className="pr-4">
                                    <strong>
                                      {
                                        performances[year][category]
                                          .performances[event].time
                                      }
                                    </strong>
                                  </td>
                                  <td className="pr-4">
                                    {
                                      performances[year][category].performances[
                                        event
                                      ].meetingName
                                    }
                                  </td>
                                  <td>
                                    {
                                      Award[
                                        performances[year][category]
                                          .performances[event].award
                                      ]
                                    }
                                  </td>
                                </tr>
                              ))}
                            </tbody>
                          </table>
                        </div>
                      ) : (
                        // <p>No award earned</p>
                        <></>
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
