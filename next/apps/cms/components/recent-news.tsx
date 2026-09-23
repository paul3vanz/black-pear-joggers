import { BackgroundColour, Stack } from '@black-pear-joggers/stack';
import { Card } from '@black-pear-joggers/card';
import { Cards } from '../components/cards';
import { Container } from '@black-pear-joggers/container';
import { differenceInCalendarMonths, parseISO } from 'date-fns';
import { formatRelative, newsPostUrl } from '@black-pear-joggers/helpers';
import { portableTextBlocksToText } from '../core/portable-text/portable-text-components';
import { Post } from '../types';
import { urlFor } from '@black-pear-joggers/sanity';

interface RecentNewsProps {
  posts: Post[];
}

export function RecentNews(props: RecentNewsProps) {
  const recentPosts = props.posts?.filter(
    (post) =>
      differenceInCalendarMonths(new Date(), parseISO(post.publishedAt)) <= 2
  );

  return recentPosts?.length ? (
    <Stack backgroundColour={BackgroundColour.Dark}>
      <Container wide={true}>
        <h2>Recent news</h2>

        <Cards maxColumns={recentPosts.length < 3 ? recentPosts.length : 3}>
          {recentPosts.map((post) => (
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
  ) : null;
}
