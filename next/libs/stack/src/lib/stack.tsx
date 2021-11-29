import { classNames, mapClassNames } from '@black-pear-joggers/helpers';

import { Container } from '@black-pear-joggers/container';
import { PropsWithChildren } from 'react';
import styled from 'styled-components';

interface Props extends PropsWithChildren<{}> {
  backgroundColour?: string;
  backgroundImage?: string;
  children: any;
  heading?: string;
  padding?: string;
}

// .attrs((props: Props) => ({
//     className: classNames(
//       'relative',
//       mapClassNames(props.backgroundColour, {
//         dark: 'bg-gray-900 text-white',
//         bright: 'bg-primary',
//         light: 'bg-gray-100',
//         default: 'bg-white',
//       }),
//       mapClassNames(props.padding, {
//         larger: 'py-16 sm:py-32',
//         sm: 'py-8',
//         default: 'py-12 sm:py-16',
//       })
//     ),
//   }))

const Section = styled.section<Props>``;

export const Stack = (props: Props) => (
  <>
    <Section backgroundColour={props.backgroundColour} padding={props.padding}>
      {props.backgroundImage && (
        <div className="absolute z-10 top-0 bottom-0 w-full overflow-hidden pointer-events-none">
          {/* <LazyLoad> */}
          <img
            className="w-full h-full object-cover object-center"
            src={props.backgroundImage}
            alt=""
          />
          {/* </LazyLoad> */}
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
    {/* <style jsx>{`
      .image img {
        mix-blend-mode: multiply;
      }
    `}</style> */}
  </>
);
