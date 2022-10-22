import { Button } from '@black-pear-joggers/button';
import { Container } from '@black-pear-joggers/container';
import { PortableText } from '@portabletext/react';
import { portableTextComponents } from '../core/portable-text/portable-text-components';
import { Stack } from '@black-pear-joggers/stack';
import {
  CtaPlug as CtaPlugType,
  TextWithIllustration,
} from '../types/content.types';

export interface InfoRowsProps {
  ctaPlug: CtaPlugType[];
}

export function CtaPlug(props) {
  return (
    <Stack backgroundColour="bright">
      <Container>
        <h2>{props.title}</h2>
        <PortableText components={portableTextComponents} value={props.body} />

        {props.ctas.map((cta) => (
          <Button key={cta.title} text={cta.title} link={cta.link} />
        ))}
      </Container>
    </Stack>
  );
}
