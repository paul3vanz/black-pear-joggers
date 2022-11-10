import { Container } from '@black-pear-joggers/container';
import { Frontmatter } from '../../../../components/news/frontmatter/frontmatter';
import { getAllPosts } from '../../../../core/queries/get-all-posts';
import { getMonth, getYear } from 'date-fns';
import { getPostBySlug } from '../../../../core/queries/get-post-by-slug';
import { GetStaticPaths, InferGetStaticPropsType } from 'next';
import { PortableText } from '@portabletext/react';
import { portableTextComponents } from '../../../../core/portable-text/portable-text-components';
import { Stack } from '@black-pear-joggers/stack';
import { urlFor } from '@black-pear-joggers/sanity';
import { useRouter } from 'next/router';

export default function NewsPost(
  props: InferGetStaticPropsType<typeof getStaticProps>
) {
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
          props.post.mainImage
            ? props.post.mainImage.externalUrl ||
              urlFor(props.post.mainImage).url()
            : 'https://cdn.sanity.io/images/hojqww2q/production/c542d0e1d0c4f86bf40e84923b4e4bd4fd939048-1200x183.jpg'
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

export const getStaticPaths = async () => {
  const posts = await getAllPosts();

  return {
    paths: posts.map((post) => {
      const year = getYear(new Date(post.publishedAt)).toString();
      const month = (getMonth(new Date(post.publishedAt)) + 1)
        .toString()
        .padStart(2, '0');

      return {
        params: { year, month, slug: post.slug.current },
      };
    }),
    fallback: false,
  };
};

export async function getStaticProps(context) {
  const post = await getPostBySlug(context.params.slug.toString());

  return {
    props: {
      post,
    },
  };
}
