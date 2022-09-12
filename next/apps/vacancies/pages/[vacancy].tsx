import Link from 'next/link';
import { Card } from '@black-pear-joggers/card';
import { Container } from '@black-pear-joggers/container';
import { GetStaticPaths, GetStaticProps } from 'next';
import { GetVacancies, getVacancies } from '../core/queries/getVacancies';
import { PortableText } from '@portabletext/react';
import { Stack } from '@black-pear-joggers/stack';
import { useEffect, useState } from 'react';
import { useRouter } from 'next/router';

type VacancyProps = {
  vacancies: GetVacancies[];
};

const BackToVacanciesPage = () => (
  <Stack padding="noBottom">
    <Container>
      <Link href="/">
        <a>&laquo; Back to Vacancies</a>
      </Link>
    </Container>
  </Stack>
);

export const Vacancy = (props: VacancyProps) => {
  const { query } = useRouter();
  const { vacancy } = query;
  const [activeVacancy, setActiveVacancy] = useState(null);

  useEffect(() => {
    setActiveVacancy(props.vacancies.find((_) => _.slug.current === vacancy));
  }, [query]);

  if (!props.vacancies)
    return (
      <div className="text-center mt-8 font-bold text-2xl">
        No vacancies found
      </div>
    );

  if (!activeVacancy) return <div>Loading...</div>;

  return (
    <>
      <div>
        <img
          src={activeVacancy.imageUrl}
          alt=""
          className="w-full object-cover h-64 sm:h-auto"
          width="1080"
          height="212"
        />
      </div>

      <BackToVacanciesPage />

      <Stack>
        <Container>
          <h1>{activeVacancy.title}</h1>

          <PortableText value={activeVacancy.summary} />
        </Container>
      </Stack>

      <Stack backgroundColour="light">
        <Container>
          <h2>Responsibilities</h2>

          <PortableText value={activeVacancy.responsibilities} />
        </Container>
      </Stack>

      <Stack backgroundColour="bright">
        <Container>
          <h2>How to apply</h2>

          <PortableText value={activeVacancy.howToApply} />
        </Container>
      </Stack>

      <Stack backgroundColour="dark">
        <Container>
          <h2>Other vacancies</h2>
          <div className="grid md:grid-cols-2 xl:grid-cols-4 gap-4">
            {props.vacancies
              .filter((_) => _.slug.current !== vacancy)
              .map((vacancy, index) => {
                return (
                  <Card
                    imageUrl={
                      vacancy.imageUrl ||
                      `https://bpj.org.uk/wp-content/uploads/2022/09/club-photo.jpg`
                    }
                    link={`/${vacancy.slug.current}`}
                    headline={vacancy.title}
                    key={vacancy.slug.current}
                  />
                );
              })}
          </div>
        </Container>
      </Stack>
    </>
  );
};

export const getStaticPaths: GetStaticPaths = async () => {
  const vacancies = await getVacancies();

  return {
    paths: vacancies.map((vacancy) => {
      return {
        params: { vacancy: vacancy.slug.current },
      };
    }),
    fallback: false,
  };
};

export const getStaticProps: GetStaticProps = async (context) => {
  const vacancies = await getVacancies();

  return {
    props: {
      vacancies,
    },
  };
};

export default Vacancy;
