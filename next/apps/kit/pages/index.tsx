import { Card } from '@black-pear-joggers/card';
import { Container } from '@black-pear-joggers/container';
import { getCategories } from '../core/queries/getCategories';
import { getClient } from '@black-pear-joggers/sanity';
import { GetStaticPaths, GetStaticProps } from 'next';
import { groq } from 'next-sanity';
import { Stack } from '@black-pear-joggers/stack';

type KitPageProps = {
  categories: {
    title: string;
    description: string;
    slug: {
      current: string;
    };
    imageUrl: string;
  }[];
};

export function KitPage(props: KitPageProps) {
  return (
    <>
      <Stack>
        <Container>
          <h1>Kit</h1>

          <p>
            Once you&apos;ve{' '}
            <a href="https://bpj.org.uk/joining-the-club/">become a BPJ</a>,
            look the part with some club kit!
          </p>
        </Container>
      </Stack>

      <Stack backgroundColour="bright">
        <Container>
          <h2>Collecting your kit</h2>
          <p>
            We don&apos;t post kit, <strong>it must be collected</strong>. Once
            you&apos;ve paid for your kit, Avril Munday, our kit co-ordinator
            will get in touch to give the next available collection date -
            usually at the following Monday night club run at Old Elizabethans.
            If you&apos;re unable to make any of the dates, you can arrange for
            a friend to come and collect on your behalf.
          </p>
        </Container>
      </Stack>

      <Stack backgroundColour="light">
        <Container>
          <div className="grid md:grid-cols-2 xl:grid-cols-4 gap-4">
            {props.categories.map((category) => {
              return (
                <Card
                  imageUrl={
                    category.imageUrl ||
                    `https://bpj.org.uk/wp-content/uploads/2012/03/montage-2017.jpg`
                  }
                  link={`/${category.slug.current}`}
                  headline={category.title}
                  key={category.slug.current}
                />
              );
            })}
          </div>
        </Container>
      </Stack>
    </>
  );
}

export const getStaticProps: GetStaticProps = async () => {
  const categories = await getCategories();

  return {
    props: {
      categories,
    },
  };
};

export default KitPage;
