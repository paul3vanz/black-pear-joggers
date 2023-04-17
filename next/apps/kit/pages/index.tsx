import { BackgroundColour, Stack } from '@black-pear-joggers/stack';
import { Card } from '@black-pear-joggers/card';
import { Container } from '@black-pear-joggers/container';
import { getCategories } from '../core/queries/getCategories';
import { getClient } from '@black-pear-joggers/sanity';
import { GetStaticPaths, GetStaticProps } from 'next';
import { groq } from 'next-sanity';

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
            <a href="https://bpj.org.uk/membership">become a BPJ</a>, look the
            part with some club kit!
          </p>
        </Container>
      </Stack>

      <Stack backgroundColour={BackgroundColour.Bright}>
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

      <Stack backgroundColour={BackgroundColour.Light}>
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

      <Stack backgroundColour={BackgroundColour.Dark}>
        <Container>
          <h2>Name printing</h2>

          <p>
            Once you've got your club kit, it's well worth getting your name
            printed on the front of your top. The added cheers you get from
            people shouting your name in races definitely help give you a boost!
          </p>

          <p>The following local companies offer name printing services:</p>

          <h3>
            <a href="https://www.blackpearapparel.co.uk/">Black Pear Apparel</a>
          </h3>

          <p>Unit 60c Blackpole Trading Est West, WR3 8TJ</p>

          <ul>
            <li>£3.50-£5 depending on size.</li>
            <li>
              Contact them before to confirm and they can offer while you wait
              service.
            </li>
            <li>They also supply our club hoodies.</li>
          </ul>

          <h3>
            <a href="https://www.dyehard.co.uk/">Dyehard</a>
          </h3>

          <p>5 St Johns, WR2 5AE</p>

          <ul>
            <li>£6 per name.</li>
            <li>While you wait service.</li>
          </ul>

          <h3>
            <a href="http://www.jobtogs.co.uk/">Job togs</a>
          </h3>

          <p>44 The Tything, WR1 1JT</p>

          <ul>
            <li>£5-£6 per print.</li>
            <li>Turnaround is about 7-10 days (leaving top with them).</li>
          </ul>
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
