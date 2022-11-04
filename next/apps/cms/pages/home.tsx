import Head from 'next/head';
import { getAllPosts } from '../core/queries/get-all-posts';
import { getFrontPage } from '../core/queries/get-front-page';
import { GetStaticPropsContext, InferGetStaticPropsType } from 'next';
import { PageBuilder } from '../components/page-builder';
import { useRouter } from 'next/router';

export default function Page(
  props: InferGetStaticPropsType<typeof getStaticProps>
) {
  const router = useRouter();

  return (
    <>
      <Head>
        <title>{props.page.title} | Black Pear Joggers</title>
      </Head>

      <PageBuilder content={props.page.content} />
    </>
  );
}

export const getStaticProps = async (context: GetStaticPropsContext) => {
  const page = await getFrontPage();
  const posts = await getAllPosts();

  return {
    props: {
      page,
      posts,
    },
    revalidate: 120,
  };
};
