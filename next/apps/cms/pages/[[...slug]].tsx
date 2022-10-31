import { getAllRoutes } from '../core/queries/get-all-routes';
import { getRouteBySlug } from '../core/queries/get-route-by-slug';
import { GetStaticPaths, GetStaticPropsContext } from 'next';
import { PageBuilder } from '../components/page-builder';
import { useRouter } from 'next/router';

export default function Page(props: Props) {
  const router = useRouter();

  return <PageBuilder content={props.route.page.content} />;
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

type UnwrapPromise<T> = T extends Promise<infer U> ? U : T;
type Props = UnwrapPromise<ReturnType<typeof getStaticProps>>['props'];
