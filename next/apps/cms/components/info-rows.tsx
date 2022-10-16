import { Container } from '@black-pear-joggers/container';
import { PortableText } from '@portabletext/react';
import { portableTextComponents } from '../core/portable-text/portable-text-components';
import { Stack } from '@black-pear-joggers/stack';
import { TextWithIllustration } from '../types/content.types';

export interface InfoRowsProps {
  rows: TextWithIllustration[];
}

export function InfoRow(props) {
  return (
    <Stack backgroundColour={props.backgroundColour}>
      <Container>
        <h2>{props.title}</h2>
        <PortableText components={portableTextComponents} value={props.text} />
      </Container>
    </Stack>
  );
}

export function InfoRows(props: InfoRowsProps) {
  return (
    <>
      {props.rows.map((row, index) => {
        return (
          <InfoRow
            key={row.title}
            {...row}
            backgroundColour={
              index % 3 === 0 ? null : index % 2 === 0 ? 'dark' : 'light'
            }
          />
        );
      })}
    </>
  );
}
