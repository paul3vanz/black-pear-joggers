import { BackgroundColour, Stack } from '@black-pear-joggers/stack';
import { Container } from '@black-pear-joggers/container';
import { DescriptionModal } from './description-modal';
import { useQuery } from '@tanstack/react-query';
import { useState } from 'react';

interface Fixture {
  event: string;
  day: string;
  date: string;
  name: string;
  link: string;
  description: string;
}

const fixturesUrl =
  'https://docs.google.com/spreadsheets/d/e/2PACX-1vQxZiDUnDXzlDia1oF0xjyiujVhIeGbKgi330Glq-RIiw0DEFJgj9ZSft1sCFyhTE5Q2y9PzFxuKFOj/pub?gid=0&single=true&output=csv';

export function ChampionsLeagueFixtures() {
  const [activeFixture, setActiveFixture] = useState<Fixture>();

  const { isLoading, data } = useQuery<Fixture[]>(['fixtures'], () =>
    fetch(fixturesUrl)
      .then((response) => response.text())
      .then((data) =>
        data
          .split('\n')
          .filter((line) => !new RegExp('^(#|,)').test(line))
          .map((line) => {
            const cells = line.match(/".*"|[^,"]+/g);

            return {
              event: cells[0],
              day: cells[1],
              date: cells[2],
              name: cells[3],
              link: cells[4],
              description: cells[5],
            };
          })
      )
  );

  return (
    <Stack backgroundColour={BackgroundColour.Dark}>
      <Container>
        <h2>Fixtures</h2>

        <DescriptionModal
          isOpen={!!activeFixture}
          onClose={() => setActiveFixture(null)}
        >
          {activeFixture ? (
            <>
              <h2>{activeFixture.name}</h2>

              <p>{activeFixture.description}</p>

              <p>
                <a href={activeFixture.link} target="_blank" rel="noreferrer">
                  Visit website
                </a>
              </p>
            </>
          ) : null}
        </DescriptionModal>

        {isLoading ? (
          <p>Loading...</p>
        ) : (
          <table className="w-full">
            <thead>
              <tr>
                <th className="px-4 py-1 hidden xs:table-cell">#</th>
                <th className="px-4 py-1 hidden sm:table-cell">Day</th>
                <th className="px-4 py-1">Date</th>
                <th className="px-4 py-1">Race</th>
              </tr>
            </thead>
            <tbody>
              {data.map((fixture) => (
                <tr key={fixture.event}>
                  <td className="px-4 py-1 border-b-1 hidden xs:table-cell">
                    {fixture.event}
                  </td>
                  <td className="px-4 py-1 border-b-1 hidden sm:table-cell">
                    {fixture.day}
                  </td>
                  <td className="px-4 py-1 border-b-1 align-top whitespace-nowrap">
                    {fixture.date}
                  </td>
                  <td className="px-4 py-1 border-b-1">
                    <button
                      className="font-bold underline text-left"
                      onClick={() => setActiveFixture(fixture)}
                    >
                      {fixture.name}
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </Container>
    </Stack>
  );
}
