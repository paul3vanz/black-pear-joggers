import { BackgroundColour, Stack } from '@black-pear-joggers/stack';
import { Button } from '@black-pear-joggers/button';
import { Container } from '@black-pear-joggers/container';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import { getAllClubRuns } from '../../core/queries/get-all-club-runs';
import { getClubRunBySlug } from '../../core/queries/get-club-run-by-slug';
import { InferGetStaticPropsType } from 'next';
import { LazyLoadImage } from '@black-pear-joggers/lazy-load-image';
import { PageBuilder } from '../../components/page-builder';
import { PortableText } from '@portabletext/react';
import { portableTextComponents } from '../../core/portable-text/portable-text-components';
import { urlFor } from '@black-pear-joggers/sanity';
import {
  faCalendarAlt,
  faMapLocationDot,
} from '@fortawesome/free-solid-svg-icons';

export default function NewsPost(
  props: InferGetStaticPropsType<typeof getStaticProps>
) {
  return (
    <>
      <Stack>
        <Container>
          <h1>{props.run.title}</h1>

          <PortableText
            value={props.run.summary}
            components={portableTextComponents}
          />
        </Container>
      </Stack>

      <Stack backgroundColour={BackgroundColour.Dark}>
        <Container>
          <div className="flex">
            <div className="mr-8">
              <FontAwesomeIcon icon={faCalendarAlt} size="4x" />
            </div>
            <div>
              <h2 className="mb-1">When?</h2>
              <div className="text-2xl">
                <strong>{props.run.time}</strong> on{' '}
                <strong>{props.run.day}s</strong>
              </div>
            </div>
          </div>
        </Container>
      </Stack>

      {props.run.venue ? (
        <Stack backgroundColour={BackgroundColour.Light}>
          <Container wide={true}>
            <div className="flex flex-col md:flex-row items-center">
              <div className="md:mx-8 lg:mx-12 xl:mx-24 flex">
                <div className="mr-8">
                  <FontAwesomeIcon icon={faMapLocationDot} size="4x" />
                </div>
                <div>
                  <h2>Where?</h2>
                  <h3 className="mb-0 text-2xl">{props.run.venue.title}</h3>
                  <p className="text-lg font-bold whitespace-pre-wrap">
                    {props.run.venue.address}
                  </p>
                  <Button
                    text="View on Google Maps"
                    link={props.run.venue.mapUrl}
                  />
                </div>
              </div>
              <div className="flex-1" style={{ flexGrow: 2 }}>
                <LazyLoadImage className="md:flex-1 mb-12 md:mb-0 h-56 xs:h-64 sm:h-96">
                  <img
                    src={
                      props.run.venue.image.externalUrl ||
                      urlFor(props.run.venue.image).url()
                    }
                    alt={props.run.venue.image.alt}
                    className="w-full rounded-sm h-56 xs:h-64 sm:h-96 object-cover object-center"
                  />
                </LazyLoadImage>
              </div>
            </div>
          </Container>
        </Stack>
      ) : null}

      {props.run.content ? <PageBuilder content={props.run.content} /> : null}
    </>
  );
}

export const getStaticPaths = async () => {
  const runs = await getAllClubRuns();

  return {
    paths: runs.map((run) => {
      return {
        params: { slug: run.slug.current },
      };
    }),
    fallback: 'blocking',
  };
};

export async function getStaticProps(context) {
  const run = await getClubRunBySlug(context.params.slug.toString());

  return {
    props: {
      run,
    },
    revalidate: 3600,
  };
}
