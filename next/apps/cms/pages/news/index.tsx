import Link from 'next/link';
import { Container } from '@black-pear-joggers/container';
import { formatRelative, friendlyDate } from '@black-pear-joggers/helpers';
import { getAllPosts } from '../../core/queries/get-all-posts';
import { InferGetStaticPropsType } from 'next';
import { legacyPosts } from '../../data/legacyPosts';
import { RecentNews } from '../../components/recent-news';
import { Stack } from '@black-pear-joggers/stack';

export default function SiteMap(
  props: InferGetStaticPropsType<typeof getStaticProps>
) {
  return (
    <>
      <Stack>
        <Container>
          <h1>News</h1>

          <p className="mb-8">
            Stay up to date with important club news and updates.{' '}
            <Link href="/contact">
              <a>Let us know</a>
            </Link>{' '}
            if you have some news that you&rsquo;d like to share. Also, check
            out our very active club{' '}
            <a
              href="https://www.facebook.com/groups/blackpearjoggers/"
              target="_blank"
              rel="noopener noreferrer"
            >
              Facebook&nbsp;group
            </a>
            &nbsp;to catch the latest news.
          </p>
        </Container>
      </Stack>

      <RecentNews posts={props.posts} />

      <Stack>
        <Container>
          <h2>Older posts</h2>

          <ul className="list-disc pl-5 mb-4">
            {legacyPosts.reverse().map((post) => (
              <li className="mb-2" key={post.date}>
                <a href={post.url}>{post.title}</a>{' '}
                <span className="text-gray-500">
                  {formatRelative(post.date)} ({friendlyDate(post.date)})
                </span>
              </li>
            ))}
          </ul>
        </Container>
      </Stack>
    </>
  );
}

export async function getStaticProps() {
  const posts = await getAllPosts();

  return {
    props: { posts: posts },
  };
}
