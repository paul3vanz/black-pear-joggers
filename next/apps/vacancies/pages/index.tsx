import { Card } from '@black-pear-joggers/card';
import { Container } from '@black-pear-joggers/container';
import { GetStaticProps } from 'next';
import { GetVacancies, getVacancies } from '../core/queries/getVacancies';
import { PortableText } from '@portabletext/react';
import { Stack } from '@black-pear-joggers/stack';

type KitPageProps = {
  vacancies: GetVacancies[];
};

export function KitPage(props: KitPageProps) {
  return (
    <>
      <Stack>
        <Container>
          <h1>Vacancies</h1>

          <p>
            The success of the club comes from the dedicated volunteers. The
            club regularly needs more volunteers; from leading groups on club
            runs to joining the committee, check out...
          </p>
        </Container>
      </Stack>

      <Stack backgroundColour="light">
        <Container>
          <div className="grid md:grid-cols-2 xl:grid-cols-4 gap-4">
            {props.vacancies
              ? props.vacancies.map((vacancy) => {
                  return (
                    <Card
                      imageUrl={
                        vacancy.imageUrl ||
                        `https://bpj.org.uk/wp-content/uploads/2022/09/club-photo.jpg`
                      }
                      link={`/${vacancy.slug.current}`}
                      headline={vacancy.title}
                      content={<PortableText value={vacancy.summary} />}
                      key={vacancy.slug.current}
                    />
                  );
                })
              : null}
          </div>
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

export default KitPage;
