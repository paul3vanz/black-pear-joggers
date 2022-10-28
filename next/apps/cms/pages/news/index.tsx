import Link from 'next/link';
import { BackgroundColour, Stack } from '@black-pear-joggers/stack';
import { Card } from '@black-pear-joggers/card';
import { Cards } from '../../components/cards';
import { Container } from '@black-pear-joggers/container';
import { formatRelative, newsPostUrl } from '@black-pear-joggers/helpers';
import { getAllPosts } from '../../core/queries/get-all-posts';
import { InferGetStaticPropsType } from 'next';
import { portableTextBlocksToText } from '../../core/portable-text/portable-text-components';

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
          <Cards>
            {props.posts?.map((post) => (
              <Card
                key={post._id}
                headline={post.title}
                link={newsPostUrl(post.publishedAt, post.slug.current)}
                imageUrl={post.imageUrl}
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
    </>
  );
}

export async function getStaticProps() {
  const posts = await getAllPosts();

  return {
    props: { posts },
  };
}
