import { classNames } from '@black-pear-joggers/helpers';
import { Container } from '@black-pear-joggers/container';
import { PortableText } from '@portabletext/react';
import { portableTextComponents } from '../core/portable-text/portable-text-components';
import { Stack } from '@black-pear-joggers/stack';

export const Steps = (props) => (
  <Stack>
    <Container>
      <h2>{props.steps.title}</h2>

      <PortableText
        components={portableTextComponents}
        value={props.steps.subtitle}
      />

      <ul>
        {props.steps.steps.map((step, index) => (
          <li key={index} className="mt-4">
            <div className="flex items-center">
              <div className="w-9 h-9 mr-3 text-2xl px-3 rounded-full bg-primary text-white font-bold flex items-center justify-center">
                <span>{index + 1}</span>
              </div>

              <h3 className="mt-5">{step.title}</h3>
            </div>

            <div className="ml-12">
              <PortableText
                components={portableTextComponents}
                value={step.content}
              />
            </div>
          </li>
        ))}
      </ul>
    </Container>
  </Stack>
);
