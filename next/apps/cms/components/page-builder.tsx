import { Container } from '@black-pear-joggers/container';
import { CtaPlug } from './cta-plug';
import { FeatureList } from './feature-list';
import { InfoRows } from './info-rows';
import { LazyLoadImage } from '@black-pear-joggers/lazy-load-image';
import { Quote } from './quote';
import { ReactElement } from 'react';
import { Stack } from '@black-pear-joggers/stack';
import { urlFor } from '@black-pear-joggers/sanity';
import {
  ContentItem,
  CtaPlug as CtaPlugType,
  InfoRows as InfoRowsType,
} from '../types/content.types';

export interface PageBuilderProps {
  content: ContentItem[];
}

export function PageBuilder(props: PageBuilderProps): ReactElement {
  return (
    <>
      {props.content.map((contentItem) => {
        switch (contentItem._type) {
          case 'infoRows':
            return <InfoRows rows={contentItem.rows} />;
          case 'ctaPlug':
            return <CtaPlug ctaPlug={contentItem} />;
          case 'featureList':
            return <FeatureList featureList={contentItem} />;
          case 'quote':
            return <Quote quote={contentItem} />;
          case 'illustration':
            return (
              <LazyLoadImage>
                <img
                  className="w-full object-cover sm:h-auto"
                  src={urlFor(contentItem.image).url()}
                  alt={contentItem.image.alt}
                />
              </LazyLoadImage>
            );
          default:
            return (
              <Stack>
                <Container>
                  <pre>{JSON.stringify(contentItem, null, ' ')}</pre>
                </Container>
              </Stack>
            );
        }
      })}
    </>
  );
}
