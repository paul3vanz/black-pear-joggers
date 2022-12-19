import { BackgroundColour, Stack } from '@black-pear-joggers/stack';
import { classNames } from '@black-pear-joggers/helpers';
import { Container } from '@black-pear-joggers/container';
import { LazyLoadImage } from '@black-pear-joggers/lazy-load-image';
import { PortableText } from '@portabletext/react';
import { portableTextComponents } from '../core/portable-text/portable-text-components';
import { TextWithIllustration } from '../types/content.types';
import { urlFor } from '@black-pear-joggers/sanity';

export interface InfoRowProps {
  row: TextWithIllustration;
  backgroundColour?: BackgroundColour;
  reverse?: boolean;
}

export interface InfoRowsProps {
  rows: TextWithIllustration[];
}

export function InfoRowText(props) {
  return (
    <>
      {props.title ? <h2>{props.title}</h2> : null}

      <PortableText components={portableTextComponents} value={props.text} />
    </>
  );
}

export function InfoRow(props: InfoRowProps) {
  console.log('props.row.illustration', props.row.illustration);

  const illustrations = props.row.illustration
    ? props.row.illustration.image
      ? [props.row.illustration.image]
      : props.row.illustration.images
    : null;

  return (
    <Stack
      backgroundColour={
        props.row.backgroundColour || props.backgroundColour || null
      }
    >
      {props.row.illustration ? (
        <Container wide={true}>
          <div
            className={classNames(
              'flex flex-col items-center',
              props.reverse ? 'md:flex-row-reverse' : 'md:flex-row'
            )}
          >
            <div
              className="flex-1"
              style={
                props.row.width === 'wide'
                  ? { flexGrow: 0.5 }
                  : props.row.width === 'narrow'
                  ? { flexGrow: 2 }
                  : null
              }
            >
              <div className="md:mx-8 lg:mx-12 xl:mx-24">
                <InfoRowText {...props.row} />
              </div>
            </div>

            {illustrations.map((illustration) => (
              <div
                className={classNames(
                  'md:flex-1 mb-12 md:mb-0',
                  props.row.cropToFit && 'h-56 xs:h-64 sm:h-96'
                )}
              >
                <LazyLoadImage
                  key={illustration.externalUrl || illustration.asset._id}
                >
                  <img
                    src={illustration.externalUrl || urlFor(illustration).url()}
                    alt={illustration.alt}
                    className={classNames(
                      'w-full rounded-sm',
                      props.row.cropToFit &&
                        'h-56 xs:h-64 sm:h-96 object-cover object-center'
                    )}
                  />
                </LazyLoadImage>
                {illustration.caption ? (
                  <div className="mt-2 text-center text-sm italic">
                    {illustration.caption}
                  </div>
                ) : null}
              </div>
            ))}
          </div>
        </Container>
      ) : (
        <Container>
          <InfoRowText {...props.row} />
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
            key={index}
            row={row}
            backgroundColour={
              index % 3 === 0
                ? null
                : index % 2 === 0
                ? BackgroundColour.Dark
                : BackgroundColour.Light
            }
            reverse={index % 2 === 0 ? false : true}
          />
        );
      })}
    </>
  );
}
