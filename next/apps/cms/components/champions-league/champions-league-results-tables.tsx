import { BackgroundColour, Stack } from '@black-pear-joggers/stack';
import { Container } from '@black-pear-joggers/container';
import { DescriptionModal } from './description-modal';
import { useQuery } from '@tanstack/react-query';
import { useState } from 'react';

const results = [
  {
    year: 2024,
    results: {
      men: {
        url: 'https://docs.google.com/spreadsheets/d/1ue3nCnaiAqEVxZWz1bgHHA8u20J109H7Fw-SS6xA1Y4/edit?gid=454885501#gid=454885501',
        topTen: [
          { position: 1, name: 'Richard Drewett', races: 10, points: 300 },
          { position: 2, name: 'Adam Knights', races: 12, points: 280 },
          { position: 3, name: 'Paul Naughton', races: 9, points: 270 },
          { position: 4, name: 'Keith Lawrence', races: 10, points: 259 },
          { position: 5, name: 'Steve Bradley', races: 10, points: 253 },
          { position: 6, name: 'Stuart Wakelam', races: 9, points: 241 },
          { position: 7, name: 'Bertie Ballinger', races: 9, points: 236 },
          { position: 8, name: 'Matthew Capel', races: 10, points: 195 },
          { position: 9, name: 'Tim Jenkins', races: 9, points: 170 },
          { position: 10, name: 'Wayne Hartley', races: 6, points: 129 },
        ],
      },
      women: {
        url: 'https://docs.google.com/spreadsheets/d/1ue3nCnaiAqEVxZWz1bgHHA8u20J109H7Fw-SS6xA1Y4/edit?gid=6426148#gid=6426148',
        topTen: [
          { position: 1, name: 'Karen Moseley', races: 10, points: 296 },
          { position: 2, name: 'Deborah Band', races: 9, points: 261 },
          { position: 3, name: 'Lucy Capel', races: 10, points: 251 },
          { position: 4, name: 'Anya Lees', races: 9, points: 219 },
          { position: 5, name: 'Alison Walker', races: 8, points: 218 },
          { position: 6, name: 'Diana Fox', races: 6, points: 205 },
          { position: 7, name: 'Susan Harrison', races: 7, points: 176 },
          { position: 8, name: 'Lucy Davison', races: 5, points: 158 },
          { position: 9, name: 'Jennie Smith', races: 7, points: 147 },
          { position: 10, name: 'Samantha McClory', races: 5, points: 123 },
        ],
      },
    },
  },

  {
    year: 2023,
    results: {
      men: {
        url: 'https://docs.google.com/spreadsheets/d/1nl7A-V0NJCatddJWlnVhucFymBzQD60JDkGGxU3q9Gk/edit#gid=454885501',
        topTen: [
          { position: 1, name: 'Adam Knights', races: 15, points: 300 },
          { position: 2, name: 'Jonathan Phillips', races: 10, points: 283 },
          { position: 3, name: 'Rob Bowery', races: 13, points: 272 },
          { position: 4, name: 'Howard Thompson', races: 10, points: 266 },
          { position: 5, name: 'Steve Bradley', races: 11, points: 257 },
          { position: 6, name: 'Keith Lawrence', races: 11, points: 237 },
          { position: 7, name: 'Richard Drewett', races: 10, points: 223 },
          { position: 8, name: 'Wayne Hartley', races: 11, points: 221 },
          { position: 9, name: 'Bertie Ballinger', races: 10, points: 209 },
          { position: 10, name: 'Matthew Capel', races: 13, points: 201 },
        ],
      },
      women: {
        url: 'https://docs.google.com/spreadsheets/d/1nl7A-V0NJCatddJWlnVhucFymBzQD60JDkGGxU3q9Gk/edit#gid=6426148',
        topTen: [
          { position: 1, name: 'Isabel Alford', races: 10, points: 298 },
          { position: 2, name: 'Alison Walker', races: 18, points: 296 },
          { position: 3, name: 'Rachael Lewis', races: 16, points: 280 },
          { position: 4, name: 'Lucy Capel', races: 15, points: 267 },
          { position: 5, name: 'Deborah Band', races: 16, points: 259 },
          { position: 6, name: 'Lucy Davison', races: 9, points: 245 },
          { position: 7, name: 'Anya Lees', races: 15, points: 237 },
          { position: 8, name: 'Kirsten Beard', races: 11, points: 224 },
          { position: 9, name: 'Sarah Richards', races: 12, points: 220 },
          { position: 10, name: 'Claire Shacklock', races: 10, points: 185 },
        ],
      },
    },
  },

  {
    year: 2022,
    results: {
      men: {
        url: 'https://docs.google.com/spreadsheets/d/e/2PACX-1vSYrj1dxjL2C6cbyL9C5oML9HIPvzeNqFqMNxtEy5M0cTb-t8LRZTH5z4dUZmubi8AUFJAIZWPEEes5/pubhtml?gid=454885501&single=true',
        topTen: [
          { position: 1, name: 'Rob Bowery', races: 13, points: 272 },
          { position: 2, name: 'Jonathan Phillips', races: 13, points: 271 },
          { position: 3, name: 'Adam Knights', races: 13, points: 257 },
          { position: 4, name: 'Dale Bozward', races: 14, points: 242 },
          { position: 5, name: 'Peter Darwen', races: 9, points: 210 },
          { position: 6, name: 'Matthew Capel', races: 12, points: 203 },
          { position: 7, name: 'Stuart Wakelam', races: 13, points: 199 },
          { position: 8, name: 'Paul Naughton', races: 10, points: 196 },
          { position: 9, name: 'Steve Bradley', races: 8, points: 178 },
          { position: 10, name: 'Dave Williams', races: 7, points: 122 },
        ],
      },
      women: {
        url: 'https://docs.google.com/spreadsheets/d/e/2PACX-1vSYrj1dxjL2C6cbyL9C5oML9HIPvzeNqFqMNxtEy5M0cTb-t8LRZTH5z4dUZmubi8AUFJAIZWPEEes5/pubhtml?gid=6426148&single=true',
        topTen: [
          { position: 1, name: 'Alison Walker', races: 13, points: 274 },
          { position: 2, name: 'Katie Gromski', races: 11, points: 251 },
          { position: 3, name: 'Deborah Band', races: 14, points: 238 },
          { position: 4, name: 'Anya Lees', races: 12, points: 226 },
          { position: 5, name: 'Rachael Lewis', races: 8, points: 203 },
          { position: 6, name: 'Tamara Cullen', races: 9, points: 190 },
          { position: 7, name: 'Ewelina Skolimowska', races: 5, points: 116 },
          { position: 8, name: 'Claire Shacklock', races: 4, points: 85 },
          { position: 9, name: 'Avril Munday', races: 4, points: 83 },
          {
            position: 10,
            name: 'Sarah Williams-Hubbard',
            races: 4,
            points: 76,
          },
        ],
      },
    },
  },
  {
    year: 2019,
    results: {
      men: {
        url: 'https://bpj.org.uk/wp-content/uploads/2019/12/Black-Pear-Joggers-Mens-Champion-League-2019-FINAL-END-OF-LEAGUE-RESULTS.xlsx',
        topTen: [
          { position: 1, name: 'Rob Bowery', races: 17, points: 268 },
          { position: 2, name: 'Jeremy Jones', races: 13, points: 262 },
          { position: 3, name: 'Ryan Little', races: 12, points: 256 },
          { position: 4, name: 'Darren Mckay', races: 11, points: 206 },
          { position: 5, name: 'Anthony Jones', races: 13, points: 203 },
          { position: 6, name: 'Dave Shacklock', races: 13, points: 186 },
          { position: 7, name: 'Matthew Capel', races: 11, points: 172 },
          { position: 8, name: 'Phil Parkes', races: 9, points: 157 },
          { position: 9, name: 'Ed Yau', races: 7, points: 156 },
          { position: 10, name: 'Gerald Sanders', races: 11, points: 151 },
        ],
      },
      women: {
        url: 'https://bpj.org.uk/wp-content/uploads/2019/12/Black-Pear-Joggers-Womens-Champions-League-2019-FINAL-END-OF-LEAGUE-RESULTS.xlsx',
        topTen: [
          { position: 1, name: 'Megan Judge', races: 12, points: 274 },
          { position: 2, name: 'Helen Ciancio', races: 10, points: 269 },
          { position: 3, name: 'Lindsey Goodrum', races: 9, points: 230 },
          { position: 4, name: 'Karen Moseley', races: 13, points: 222 },
          { position: 5, name: 'Claire Shacklock', races: 9, points: 201 },
          { position: 6, name: 'Catherine Jones', races: 13, points: 201 },
          { position: 7, name: 'Alison Walker', races: 8, points: 200 },
          {
            position: 8,
            name: 'Sarah Williams-Hubbard',
            races: 9,
            points: 166,
          },
          { position: 9, name: 'Charm Whitehouse', races: 7, points: 134 },
          { position: 10, name: 'Sam McClory', races: 11, points: 134 },
        ],
      },
    },
  },
  {
    year: 2018,
    results: {
      men: {
        url: 'https://bpj.org.uk/wp-content/uploads/2019/02/BPJ-Mens-Champions-League-2018-Final-Results.xlsx',
        topTen: [
          { position: 1, name: 'Paul Evans', races: 13, points: 262 },
          { position: 2, name: 'Nic Dauncey', races: 11, points: 249 },
          { position: 3, name: 'Kevin Garness', races: 19, points: 240 },
          { position: 4, name: 'Gerald Sanders', races: 13, points: 195 },
          { position: 5, name: 'Richard Drewett', races: 9, points: 188 },
          { position: 6, name: 'Alan Southwick', races: 7, points: 157 },
          { position: 7, name: 'Mark Peverelli', races: 9, points: 155 },
          { position: 8, name: 'Mark Dillon', races: 9, points: 147 },
          { position: 9, name: 'Matt Pillott', races: 10, points: 146 },
          { position: 10, name: 'Tony Farnsworth', races: 5, points: 145 },
        ],
      },
      women: {
        url: 'https://bpj.org.uk/wp-content/uploads/2019/02/BPJ-Ladies-Champions-League-2018-Final-Results.xlsx',
        topTen: [
          { position: 1, name: 'Becky Dillon', races: 12, points: 272 },
          { position: 2, name: 'Rachel Booth', races: 15, points: 267 },
          { position: 3, name: 'Kareen Mann', races: 11, points: 251 },
          { position: 4, name: 'Lindsey Goodrum', races: 14, points: 240 },
          { position: 5, name: 'Lucy Capel', races: 11, points: 226 },
          { position: 6, name: 'Rhian Protheroe', races: 9, points: 187 },
          { position: 7, name: 'Ann Hewlett', races: 9, points: 175 },
          { position: 8, name: 'Sam McClory', races: 12, points: 167 },
          { position: 9, name: 'Sue Dillon', races: 9, points: 162 },
          { position: 10, name: 'Rebecca Spencer', races: 9, points: 159 },
        ],
      },
    },
  },
  {
    year: 2017,
    results: {
      men: {
        url: 'https://bpj.org.uk/wp-content/uploads/2019/02/BPJ-Mens-Champions-League-2017-Final-Results.xlsx',
        topTen: [
          { position: 1, name: 'Paul Childs', races: 10, points: 243 },
          { position: 2, name: 'Rob Gilbert', races: 16, points: 225 },
          { position: 3, name: 'Chris Attwood', races: 9, points: 205 },
          { position: 4, name: 'Chris Berry', races: 13, points: 196 },
          { position: 5, name: 'Richard Drewett', races: 10, points: 188 },
          { position: 6, name: 'Ian Walwyn', races: 13, points: 179 },
          { position: 7, name: 'Howard Thompson', races: 8, points: 157 },
          { position: 8, name: 'Glenn Barker', races: 14, points: 153 },
          { position: 9, name: 'Steve McNelis', races: 11, points: 151 },
          { position: 10, name: 'Neil Laurenson', races: 6, points: 146 },
        ],
      },
      women: {
        url: 'https://bpj.org.uk/wp-content/uploads/2019/02/BPJ-Ladies-Champions-League-2017-Final-Results.xlsx',
        topTen: [
          { position: 1, name: 'Sally Dring', races: 14, points: 246 },
          { position: 2, name: 'Anita Hennessey', races: 13, points: 216 },
          { position: 3, name: 'Iwona Hudson', races: 12, points: 206 },
          { position: 4, name: 'Ann Hewlett', races: 11, points: 190 },
          { position: 5, name: 'Nichola Robinson', races: 7, points: 148 },
          { position: 6, name: 'Becky Hardie', races: 6, points: 143 },
          { position: 7, name: 'Claire Shacklock', races: 7, points: 141 },
          { position: 8, name: 'Viv Tolley', races: 8, points: 124 },
          { position: 9, name: 'Avril Munday', races: 8, points: 121 },
          { position: 10, name: 'Sarah Kellett', races: 5, points: 121 },
        ],
      },
    },
  },
  {
    year: 2016,
    results: {
      men: {
        url: 'https://bpj.org.uk/wp-content/uploads/2019/02/BPJ-Champions-League-2016-Final-Results.xlsx',
        topTen: [
          { position: 1, name: 'Matthew Davis', races: 8, points: 192 },
          { position: 2, name: 'Steve McNelis', races: 12, points: 176 },
          { position: 3, name: 'Mark Dillon', races: 14, points: 174 },
          { position: 4, name: 'Rob Gilbert', races: 9, points: 174 },
          { position: 5, name: 'Neil Laurenson', races: 6, points: 140 },
          { position: 6, name: 'Chris Attwood', races: 7, points: 123 },
          { position: 7, name: 'Ian Wild', races: 5, points: 118 },
          { position: 8, name: 'Dan Cale', races: 6, points: 108 },
          { position: 9, name: 'Leo Taggio', races: 5, points: 100 },
          { position: 10, name: 'Alan Southwick', races: 6, points: 99 },
        ],
      },
      women: {
        url: 'https://bpj.org.uk/wp-content/uploads/2019/02/BPJ-Champions-League-2016-Final-Results.xlsx',
        topTen: [
          { position: 1, name: 'Becky Hardie', races: 10, points: 243 },
          { position: 2, name: 'Lorraine Griffiths', races: 7, points: 161 },
          { position: 3, name: 'Claire Shacklock', races: 8, points: 160 },
          { position: 4, name: 'Sue Dillon', races: 8, points: 140 },
          { position: 5, name: 'Sarah Morris', races: 7, points: 131 },
          {
            position: 6,
            name: 'Sarah Williams-Hubbard',
            races: 8,
            points: 129,
          },
          { position: 7, name: 'Sarah Kellett', races: 5, points: 124 },
          { position: 8, name: 'Nichola Robinson', races: 6, points: 123 },
          { position: 9, name: 'Helen Stanley', races: 5, points: 108 },
          { position: 10, name: 'Rebecca Spencer', races: 6, points: 105 },
        ],
      },
    },
  },
  {
    year: 2015,
    results: {
      men: {
        url: 'https://bpj.org.uk/wp-content/uploads/2019/02/BPJ-Champions-League-2015-Final-Results.xlsx',
        topTen: [
          { position: 1, name: 'Matthew Davis', races: 11, points: 250 },
          { position: 2, name: 'Alan Southwick', races: 9, points: 185 },
          { position: 3, name: 'Richard Drewett', races: 10, points: 149 },
          { position: 4, name: 'Neil Laurenson', races: 6, points: 143 },
          { position: 5, name: 'Chris Attwood', races: 6, points: 134 },
          { position: 6, name: 'Ian Wild', races: 6, points: 132 },
          { position: 7, name: 'Clive Andrews', races: 5, points: 109 },
          { position: 8, name: 'Benjamin Dillon', races: 6, points: 100 },
          { position: 9, name: 'Clive Griffiths', races: 5, points: 99 },
          { position: 10, name: 'Derek Jackson', races: 5, points: 99 },
        ],
      },
      women: {
        url: 'https://bpj.org.uk/wp-content/uploads/2019/02/BPJ-Champions-League-2015-Final-Results.xlsx',
        topTen: [
          { position: 1, name: 'Becky Hardie', races: 11, points: 154 },
          { position: 2, name: 'Sarah Morris', races: 9, points: 60 },
          { position: 3, name: 'Emily Seward', races: 3, points: 49 },
          { position: 4, name: 'Ewelina Skolimowska', races: 7, points: 47 },
          { position: 5, name: 'Cherilyn King', races: 6, points: 41 },
          { position: 6, name: 'Natasha Day', races: 2, points: 30 },
          { position: 7, name: 'Donna Rushton', races: 4, points: 28 },
          { position: 8, name: 'Lorraine Griffiths', races: 4, points: 23 },
          { position: 9, name: 'Jemima Lowe', races: 3, points: 20 },
          { position: 10, name: 'Cindy Richards', races: 3, points: 19 },
        ],
      },
    },
  },
];

export function ChampionsLeagueResultsTables() {
  const [activeYear, setActiveYear] = useState<number>();

  return (
    <Stack backgroundColour={BackgroundColour.Dark}>
      <Container>
        <h2>Previous years</h2>

        <p>
          Thank you to <strong>Mat Capel</strong>, <strong>Lucy Capel</strong>,{' '}
          <strong>Peter Darwen</strong>, <strong>Sarah Morris</strong>,{' '}
          <strong>Mark Dillon</strong> and <strong>Ben Dillon</strong> who have
          taken on the administration of the league in recent years.
        </p>

        {results.map((result) => (
          <>
            <div className="grid sm:grid-cols-2 gap-4 mb-6">
              {['men', 'women'].map((gender) => (
                <div key={gender}>
                  <h3 className="mb-0">{result.year}</h3>

                  <h4 className="font-bold text-lg mb-4">Top 10 {gender}</h4>

                  <p>
                    <a
                      href={result.results[gender].url}
                      target="_blank"
                      rel="noreferrer"
                    >
                      Download full results
                    </a>
                  </p>

                  <table className="w-full">
                    <thead>
                      <tr>
                        <th className="px-4 py-1">#</th>
                        <th className="px-4 py-1">Name</th>
                        <th className="px-4 py-1 hidden xs:table-cell">
                          Races
                        </th>
                        <th className="px-4 py-1">Points</th>
                      </tr>
                    </thead>
                    <tbody>
                      {result.results[gender].topTen.map((athlete) => (
                        <tr
                          className={
                            athlete.position === 1 ? 'font-bold' : null
                          }
                          key={athlete.position}
                        >
                          <td className="px-4 py-1">{athlete.position}</td>
                          <td className="px-4 py-1">{athlete.name}</td>
                          <td className="px-4 py-1 hidden xs:table-cell">
                            {athlete.races}
                          </td>
                          <td className="px-4 py-1">{athlete.points}</td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              ))}
            </div>
          </>
        ))}
      </Container>
    </Stack>
  );
}
