import { BackgroundColour, Stack } from '@black-pear-joggers/stack';
import { Button } from '@black-pear-joggers/button';
import { Container } from '@black-pear-joggers/container';
import { PortableText } from '@portabletext/react';
import { portableTextComponents } from '../core/portable-text/portable-text-components';
import { CtaPlug as CtaPlugType } from '../types/content.types';

interface CtaPlugProps {
  ctaPlug: CtaPlugType;
}

export function CtaPlug({ ctaPlug }: CtaPlugProps) {
  return (
    <Stack
      backgroundColour={ctaPlug.backgroundColour || BackgroundColour.Bright}
    >
      <Container>
        <h2>{ctaPlug.title}</h2>
        <PortableText
          components={portableTextComponents}
          value={ctaPlug.body}
        />

        {ctaPlug.ctas.map((cta) => (
          <div className="inline-block xs:mr-4 mb-4 sm:mb-0" key={cta.title}>
            <Button
              key={cta.title}
              text={cta.title}
              link={cta.link}
              colour={
                ctaPlug.backgroundColour === BackgroundColour.Dark
                  ? BackgroundColour.Light
                  : undefined
              }
            />
          </div>
        ))}
      </Container>
    </Stack>
  );
}
