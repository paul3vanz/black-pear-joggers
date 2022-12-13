import { BackgroundColour, Stack } from '@black-pear-joggers/stack';
import { Card } from '@black-pear-joggers/card';
import { Container } from '@black-pear-joggers/container';
import { GetStaticProps } from 'next';
import { PortableText } from '@portabletext/react';
import { toPlainText } from '@black-pear-joggers/helpers';
import {
  GetVacancies,
  getVacancies,
  VacancyStatus,
} from '../core/queries/getVacancies';

type VacanciesPageProps = {
  vacancies: GetVacancies[];
};

function VacanciesCards(props: VacanciesPageProps) {
  return (
    <div className="grid md:grid-cols-2 xl:grid-cols-3 gap-4">
      {props.vacancies
        ? props.vacancies.map((vacancy) => {
            const summary = toPlainText(vacancy.summary);

            return (
              <Card
                imageUrl={
                  vacancy.imageUrl ||
                  `https://bpj.org.uk/wp-content/uploads/2022/09/club-photo.jpg`
                }
                link={`/${vacancy.slug.current}`}
                headline={vacancy.title}
                content={
                  <p>
                    {summary.length > 150
                      ? `${summary.substring(0, 150)}...`
                      : summary}
                  </p>
                }
                key={vacancy.slug.current}
              />
            );
          })
        : null}
    </div>
  );
}

export function VacanciesPage(props: VacanciesPageProps) {
  return (
    <>
      <Stack>
        <Container>
          <h1>Vacancies</h1>

          <p>
            The success of the club comes from the dedicated volunteers. The
            club regularly needs more volunteers; from leading groups on club
            runs to joining the committee, check out the vacancies below. If
            there&rsquo;s some other way you feel you could help the club that
            isn&rsquo;t listed below, please{' '}
            <a href="https://bpj.org.uk/contact-the-club/">get in touch</a>{' '}
            anyway.
          </p>
        </Container>
      </Stack>

      <Stack backgroundColour={BackgroundColour.Light}>
        <Container>
          <h2>Open vacancies</h2>

          <VacanciesCards
            vacancies={props.vacancies.filter(
              (vacancy) => vacancy.status === VacancyStatus.Recruiting
            )}
          />
        </Container>
      </Stack>

      <Stack backgroundColour={BackgroundColour.Dark}>
        <Container>
          <h2>Vacancies now filled</h2>

          <VacanciesCards
            vacancies={props.vacancies.filter(
              (vacancy) => vacancy.status === VacancyStatus.Filled
            )}
          />
        </Container>
      </Stack>
    </>
  );
}

export const getStaticProps: GetStaticProps = async () => {
  const vacancies = await getVacancies();

  return {
    props: {
      vacancies,
    },
  };
};

export default VacanciesPage;
