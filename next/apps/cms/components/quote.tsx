import styled from 'styled-components';
import { BackgroundColour, Stack } from '@black-pear-joggers/stack';
import { Container } from '@black-pear-joggers/container';
import { PortableText } from '@portabletext/react';
import { portableTextComponents } from '../core/portable-text/portable-text-components';
import { Quote as QuoteType } from '../types/content.types';

interface QuoteProps {
  quote: QuoteType;
}

const StyledQuoteContainer = styled.div`
  * {
    display: inline;
  }
`;

export function Quote({ quote }: QuoteProps) {
  return (
    <Stack backgroundColour={quote.backgroundColour || BackgroundColour.Dark}>
      <Container>
        <StyledQuoteContainer className="text-2xl font-bold italic inline">
          &ldquo;
          <PortableText
            components={portableTextComponents}
            value={quote.content}
          />
          &rdquo; <span className="font-normal"> - {quote.name}</span>
        </StyledQuoteContainer>
      </Container>
    </Stack>
  );
}
