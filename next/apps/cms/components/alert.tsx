import { Alert as AlertType, AlertTypes } from '../types/content.types';
import { BackgroundColour, Stack } from '@black-pear-joggers/stack';
import { Container } from '@black-pear-joggers/container';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import { PortableText } from '@portabletext/react';
import { portableTextComponents } from '../core/portable-text/portable-text-components';
import {
  faCheckCircle,
  faExclamationCircle,
  faExclamationTriangle,
  faTimesCircle,
} from '@fortawesome/free-solid-svg-icons';

export const Alert = (props: { alert: AlertType }) => (
  <Stack
    backgroundColour={
      BackgroundColour[
        `${props.alert.type[0].toUpperCase()}${props.alert.type.substring(1)}`
      ]
    }
  >
    <Container>
      <div className="flex">
        <Icon type={props.alert.type} />
        <div className="ml-4">
          <h2 className="mb-2">{props.alert.title}</h2>

          <PortableText
            components={portableTextComponents}
            value={props.alert.content}
          />
        </div>
      </div>
    </Container>
  </Stack>
);

const Icon = (props: { type: AlertTypes }) => {
  switch (props.type) {
    case AlertTypes.Info:
      return <FontAwesomeIcon size="2x" icon={faExclamationCircle} />;
    case AlertTypes.Warning:
      return <FontAwesomeIcon size="2x" icon={faExclamationTriangle} />;
    case AlertTypes.Success:
      return <FontAwesomeIcon size="2x" icon={faCheckCircle} />;
    case AlertTypes.Error:
      return <FontAwesomeIcon size="2x" icon={faTimesCircle} />;
    default:
      return <FontAwesomeIcon size="2x" icon={faExclamationCircle} />;
  }
};
