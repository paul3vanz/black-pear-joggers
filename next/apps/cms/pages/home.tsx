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
