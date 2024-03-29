import styled from 'styled-components';
import { classNames, mapClassNames } from '@black-pear-joggers/helpers';
import { Container } from '@black-pear-joggers/container';
import { PropsWithChildren } from 'react';

export enum BackgroundColour {
  White = 'white',
  Dark = 'dark',
  Light = 'light',
  Bright = 'bright',
  Success = 'success',
  Info = 'info',
  Warning = 'warning',
  Error = 'error',
}

interface Props {
  backgroundColour?: BackgroundColour;
  backgroundImage?: string;
  heading?: string;
  padding?: string;
}

export function Section(props: PropsWithChildren<Props>) {
  return (
    <section
      className={classNames(
        props.backgroundColour,
        'relative',
        mapClassNames(props.backgroundColour, {
          [BackgroundColour.Dark]: 'bg-gray-900 text-white',
          [BackgroundColour.Bright]: 'bg-primary',
          [BackgroundColour.Light]: 'bg-gray-100',
          [BackgroundColour.Success]: 'bg-teal-100',
          [BackgroundColour.Info]: 'bg-yellow-100',
          [BackgroundColour.Warning]: 'bg-orange-100',
          [BackgroundColour.Error]: 'bg-red-100',
          default: 'bg-white',
        }),
        mapClassNames(props.padding, {
          larger: 'py-16 sm:py-32',
          sm: 'py-8',
          default: 'py-12 sm:py-16',
          noBottom: 'pt-12 sm:pt-16',
        })
      )}
    >
      {props.children}
    </section>
  );
}

export const Stack = (props: PropsWithChildren<Props>) => (
  <>
    <Section backgroundColour={props.backgroundColour} padding={props.padding}>
      {props.backgroundImage && (
        <div className="absolute z-10 top-0 bottom-0 w-full overflow-hidden pointer-events-none">
          <img
            className="w-full h-full object-cover object-center"
            src={props.backgroundImage}
            alt=""
          />
        </div>
      )}
      <div className="relative z-20">
        {props.heading && (
          <Container>
            <div className="mx-auto">
              <h2>{props.heading}</h2>
            </div>
          </Container>
        )}
        {props.children}
      </div>
    </Section>
  </>
);
