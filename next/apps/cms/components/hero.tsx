import styled from 'styled-components';
import { BackgroundColour, Stack } from '@black-pear-joggers/stack';
import { ButtonLightTextDarkBackground } from '@black-pear-joggers/button';
import { Container } from '@black-pear-joggers/container';
import { Hero as HeroType } from '../types/content.types';
import { LazyLoadImage } from '@black-pear-joggers/lazy-load-image';
import { PortableText } from '@portabletext/react';
import { portableTextComponents } from '../core/portable-text/portable-text-components';
import { urlFor } from '@black-pear-joggers/sanity';

interface HeroProps {
  hero: HeroType;
}

const StyledTaglineWrapper = styled.div`
  p {
    display: inline;
    -webkit-box-decoration-break: clone;
    background-color: rgb(255, 255, 255);
    color: rgb(34, 34, 34);
    padding: 0px 8px;
    line-height: 36px;
  }

  a {
    white-space: nowrap;
  }
`;

export function Hero({ hero }: HeroProps) {
  return (
    <Stack backgroundImage={urlFor(hero.illustration.image).url()}>
      <Container>
        <div className="flex flex-col content-center text-center text-white">
          <h1 className="mb-4 sm:mb-8 inline-block bg-gray-900 inline-block px-4 py-2 mx-auto text-3xl sm:text-4xl">
            {hero.heading}
          </h1>

          <div className="w-4/5 lg:w-2/3 mx-auto">
            <div className="mb-4 sm:mb-8 text-lg">
              <StyledTaglineWrapper>
                <PortableText
                  components={portableTextComponents}
                  value={hero.tagline}
                />
              </StyledTaglineWrapper>
            </div>

            {hero.cta ? (
              <ButtonLightTextDarkBackground
                text={hero.cta.title}
                link={hero.cta.link}
              />
            ) : null}
          </div>
        </div>
      </Container>
    </Stack>
  );
}
