import Head from 'next/head';
import { Container } from '@black-pear-joggers/container';
import { getAllRoutes } from '../core/queries/get-all-routes';
import { getRouteBySlug } from '../core/queries/get-route-by-slug';
import { PageBuilder } from '../components/page-builder';
import { Stack } from '@black-pear-joggers/stack';
import { useRouter } from 'next/router';
import {
  GetStaticPaths,
  GetStaticPropsContext,
  InferGetStaticPropsType,
} from 'next';

export default function Page(
  props: InferGetStaticPropsType<typeof getStaticProps>
) {
  const router = useRouter();

  return props.route?.page ? (
    <>
      <Head>
        <title>{props.route.page.title} | Black Pear Joggers</title>
      </Head>
      <PageBuilder content={props.route.page.content} />
    </>
  ) : (
    <Stack>
      <Container>
        <p>Page/route not found.</p>
      </Container>
    </Stack>
  );
}

export const getStaticPaths: GetStaticPaths = async () => {
  const routes = await getAllRoutes();

  return {
    paths: routes.map((route) => ({
      params: {
        slug: route.slug.current.split('/'),
        pageRef: route.page._id,
      },
    })),
    fallback: 'blocking',
  };
};

export const getStaticProps = async (context: GetStaticPropsContext) => {
  const slug = context.params['slug'] as string[];
  const route = await getRouteBySlug(slug.join('/'));

  return {
    props: {
      route,
    },
    revalidate: 120,
  };
};
