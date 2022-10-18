import { classNames } from '@black-pear-joggers/helpers';
import { Container } from '@black-pear-joggers/container';
import { LazyLoadImage } from '@black-pear-joggers/lazy-load-image';
import { PortableText } from '@portabletext/react';
import { portableTextComponents } from '../core/portable-text/portable-text-components';
import { Stack } from '@black-pear-joggers/stack';
import { TextWithIllustration } from '../types/content.types';
import { urlFor } from '@black-pear-joggers/sanity';

export interface InfoRowsProps {
  rows: TextWithIllustration[];
}

export function InfoRowText(props) {
  return (
    <>
      <h2>{props.title}</h2>

      <PortableText components={portableTextComponents} value={props.text} />
    </>
  );
}

export function InfoRow(props) {
  return (
    <Stack backgroundColour={props.backgroundColour}>
      {props.illustration ? (
        <Container wide={true}>
          <div
            className={classNames(
              'flex flex-col items-center',
              props.reverse ? 'md:flex-row-reverse' : 'md:flex-row'
            )}
          >
            <div className="flex-1">
              <div className="md:mx-8 lg:mx-12 xl:mx-24">
                <InfoRowText {...props} />
              </div>
            </div>

            <LazyLoadImage className="md:flex-1 h-56 xs:h-64 sm:h-96 mb-12 md:mb-0">
              <img
                src={urlFor(props.illustration.image).url()}
                alt=""
                className="w-full h-56 xs:h-64 sm:h-96 object-cover object-center rounded-sm"
              />
            </LazyLoadImage>
          </div>
        </Container>
      ) : (
        <Container>
          <InfoRowText {...props} />
        </Container>
      )}
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
            reverse={index % 2 === 0 ? false : true}
          />
        );
      })}
    </>
  );
}
