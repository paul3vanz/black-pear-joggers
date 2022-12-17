import Link from 'next/link';
import { Container } from '@black-pear-joggers/container';
import { getAllPosts } from '../core/queries/get-all-posts';
import { getAllRoutes } from '../core/queries/get-all-routes';
import { GetStaticPropsContext } from 'next';
import { newsPostUrl, shortDate } from '@black-pear-joggers/helpers';
import { Stack } from '@black-pear-joggers/stack';
import { useRouter } from 'next/router';

export default function Page(props: Props) {
  const router = useRouter();

  return (
    <Stack>
      <Container>
        <h1>Site map</h1>

        <h2>Pages</h2>

        <ul className="list-disc mb-4 ml-5">
          {props.pages
            .sort((a, b) => (a.slug.current < b.slug.current ? -1 : 0))
            .map((page) => (
              <li key={page._id}>
                <Link
                  href={page.slug.current === 'home' ? '/' : page.slug.current}
                >
                  {page.page.title}
                </Link>
              </li>
            ))}
        </ul>

        <h2>News</h2>

        <ul className="list-disc ml-5">
          {props.posts?.map((post) => (
            <li key={post._id}>
              <Link href={newsPostUrl(post.publishedAt, post.slug.current)}>
                {shortDate(post.publishedAt)}: {post.title}
              </Link>
            </li>
          ))}
        </ul>
      </Container>
    </Stack>
  );
}

export const getStaticProps = async (context: GetStaticPropsContext) => {
  const pages = await getAllRoutes();
  const posts = await getAllPosts();

  return {
    props: {
      pages,
      posts,
    },
  };
};

type UnwrapPromise<T> = T extends Promise<infer U> ? U : T;
type Props = UnwrapPromise<ReturnType<typeof getStaticProps>>['props'];
