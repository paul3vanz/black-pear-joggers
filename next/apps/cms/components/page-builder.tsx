import { BackgroundColour, Stack } from '@black-pear-joggers/stack';
import { Card } from './card';
import { Cards } from './cards';
import { Container } from '@black-pear-joggers/container';
import { CtaPlug } from './cta-plug';
import { FeatureList } from './feature-list';
import { Hero } from './hero';
import { InfoRows } from './info-rows';
import { LazyLoadImage } from '@black-pear-joggers/lazy-load-image';
import { PortableText } from '@portabletext/react';
import { portableTextComponents } from '../core/portable-text/portable-text-components';
import { Quote } from './quote';
import { ReactElement } from 'react';
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
            return <InfoRows key={contentItem._key} rows={contentItem.rows} />;
          case 'ctaPlug':
            return <CtaPlug key={contentItem._key} ctaPlug={contentItem} />;
          case 'featureList':
            return (
              <FeatureList key={contentItem._key} featureList={contentItem} />
            );
          case 'quote':
            return <Quote key={contentItem._key} quote={contentItem} />;
          case 'hero':
            return <Hero key={contentItem._key} hero={contentItem} />;
          case 'illustration':
            return (
              <LazyLoadImage key={contentItem._key}>
                <img
                  className="w-full object-cover sm:h-auto"
                  src={
                    contentItem.image.externalUrl ||
                    urlFor(contentItem.image).url()
                  }
                  alt={contentItem.image.alt}
                />
              </LazyLoadImage>
            );
          case 'cards':
            return (
              <Stack
                key={contentItem._key}
                backgroundColour={BackgroundColour.Light}
              >
                <Container wide={true}>
                  {contentItem.title || contentItem.subtitle ? (
                    <div className="mb-8">
                      {contentItem.title ? <h2>{contentItem.title}</h2> : null}

                      {contentItem.subtitle ? (
                        <PortableText
                          components={portableTextComponents}
                          value={contentItem.subtitle}
                        />
                      ) : null}
                    </div>
                  ) : null}

                  <Cards maxColumns={contentItem.maxColumns || null}>
                    {contentItem.cards.map((card) => (
                      <Card
                        key={card._key}
                        headline={card.title}
                        link={card.link}
                        content={
                          <PortableText
                            components={portableTextComponents}
                            value={card.content}
                          />
                        }
                        imageUrl={
                          card.image?.externalUrl ||
                          urlFor(card.image.asset).url()
                        }
                      />
                    ))}
                  </Cards>
                </Container>
              </Stack>
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
