import Link from 'next/link';
import { BackgroundColour, Stack } from '@black-pear-joggers/stack';
import { Card } from '@black-pear-joggers/card';
import { Cards } from '../../components/cards';
import { Container } from '@black-pear-joggers/container';
import { getAllPosts } from '../../core/queries/get-all-posts';
import { InferGetStaticPropsType } from 'next';
import { legacyPosts } from '../../data/legacyPosts';
import { portableTextBlocksToText } from '../../core/portable-text/portable-text-components';
import { urlFor } from '@black-pear-joggers/sanity';
import {
  formatRelative,
  friendlyDate,
  newsPostUrl,
} from '@black-pear-joggers/helpers';

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

      <Stack backgroundColour={BackgroundColour.Dark}>
        <Container wide={true}>
          <Cards maxColumns={props.posts.length < 3 ? props.posts.length : 3}>
            {props.posts?.map((post) => (
              <Card
                key={post._id}
                headline={post.title}
                link={newsPostUrl(post.publishedAt, post.slug.current)}
                imageUrl={
                  post.mainImage
                    ? post.mainImage.externalUrl || urlFor(post.mainImage).url()
                    : null
                }
                content={
                  <>
                    <p className="mb-2 text-gray-500">
                      {formatRelative(post.publishedAt)}
                    </p>

                    <p>{portableTextBlocksToText(post.body).substr(0, 110)}</p>
                  </>
                }
              />
            ))}
          </Cards>
        </Container>
      </Stack>

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
