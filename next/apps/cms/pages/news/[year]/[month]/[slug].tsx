import { Container } from '@black-pear-joggers/container';
import { Frontmatter } from '../../../../components/news/frontmatter/frontmatter';
import { getAllPosts } from '../../../../core/queries/get-all-posts';
import { getPostBySlug } from '../../../../core/queries/get-post-by-slug';
import { GetStaticPaths } from 'next';
import { PortableText, PortableTextComponents } from '@portabletext/react';
import { Post } from '../../../../types';
import { Stack } from '@black-pear-joggers/stack';
import { useRouter } from 'next/router';

const portableTextComponents: PortableTextComponents = {
  list: {
    // eslint-disable-next-line react/display-name
    bullet: ({ children }) => <ul className="list-disc pl-5">{children}</ul>,
  },
  listItem: {
    // eslint-disable-next-line react/display-name
    bullet: ({ children }) => <li className="mb-2">{children}</li>,
  },
};

export default function NewsPost(props: Props) {
  const router = useRouter();

  return (
    <>
      <Frontmatter
        title={props.post.title}
        publishDate={props.post.publishedAt}
        author={{
          name: props.post.authors[0].author.name,
          avatarUrl: props.post.authors[0].author.imageUrl,
        }}
        imageUrl={
          props.post.imageUrl ||
          'https://cdn.sanity.io/images/hojqww2q/production/c542d0e1d0c4f86bf40e84923b4e4bd4fd939048-1200x183.jpg'
        }
      />

      <Stack>
        <Container>
          <PortableText
            value={props.post.body}
            components={portableTextComponents}
          />
        </Container>
      </Stack>
    </>
  );
}

export const getStaticPaths: GetStaticPaths = async () => {
  const posts = await getAllPosts();

  return {
    paths: (posts as any).map((post) => {
      return {
        params: { year: '2022', month: '10', slug: post.slug.current },
      };
    }),
    fallback: false,
  };
};

export const getStaticProps = async (context) => {
  const post = await getPostBySlug(context.params.slug.toString());

  return {
    props: {
      post,
    },
  };
};

type UnwrapPromise<T> = T extends Promise<infer U> ? U : T;
type Props = UnwrapPromise<ReturnType<typeof getStaticProps>>['props'];
