import Link from 'next/link';
import { Container } from '@black-pear-joggers/container';
import { getAllPosts } from '../core/queries/get-all-posts';
import { getAllRoutes } from '../core/queries/get-all-routes';
import { GetStaticPropsContext, InferGetStaticPropsType } from 'next';
import { Hero } from '../components/hero';
import { newsPostUrl, shortDate } from '@black-pear-joggers/helpers';
import { Stack } from '@black-pear-joggers/stack';
import { useRouter } from 'next/router';

export default function Page(
  props: InferGetStaticPropsType<typeof getStaticProps>
) {
  const router = useRouter();

  return (
    <>
      <Hero
        hero={{
          heading: 'Welcome to Worcester’s friendly running club',
          tagline: (
            <p>
              Groups for all abilities from jog/walk to faster paced running
              groups. An England Athletics affiliated club, offering&nbsp;
              <a href="https://bpj.org.uk/couch-to-5k/">Couch to 5K</a>
              &nbsp;groups for beginners, a range of social and running events
              and take part in many races and&nbsp;
              <a href="https://bpj.org.uk/leagues/cross-country/">
                cross country
              </a>
              &nbsp;leagues.
            </p>
          ),
        }}
      />
      <Stack>
        <Container>
          <h1>Welcome to Black Pear Joggers</h1>
        </Container>
      </Stack>
    </>
  );
}

export const getStaticProps = async (context: GetStaticPropsContext) => {
  const pages = await getAllRoutes();
  const posts = await getAllPosts();

  return {
    props: {},
  };
};
