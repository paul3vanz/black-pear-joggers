import { BackgroundColour, Stack } from '@black-pear-joggers/stack';
import { classNames } from '@black-pear-joggers/helpers';
import { Container } from '@black-pear-joggers/container';
import { FeatureList as FeatureListType } from '../types/content.types';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import { PortableText } from '@portabletext/react';
import { portableTextComponents } from '../core/portable-text/portable-text-components';
import {
  faArrowPointer,
  faCalendarDays,
  faCar,
  faChartLine,
  faCreditCard,
  faLightbulb,
  faPeopleGroup,
  faPersonRunning,
  faStopwatch20,
  faTrophy,
  faVest,
} from '@fortawesome/free-solid-svg-icons';

interface FeatureListProps {
  featureList: FeatureListType;
}

export function FeatureList({ featureList }: FeatureListProps) {
  const isHorizontal = featureList.orientation !== 'vertical';

  return (
    <Stack backgroundColour={BackgroundColour.Light}>
      <Container>
        <ul
          className={classNames(
            'grid gap-4 grid-cols-1',
            isHorizontal && 'sm:grid-cols-2 md:grid-cols-4'
          )}
        >
          {featureList.features.map((feature) => (
            <li
              className={isHorizontal ? 'text-center' : 'flex'}
              key={feature._key}
            >
              {feature.icon ? (
                <div>
                  <FontAwesomeIcon
                    className={classNames('mb-4', !isHorizontal && 'mr-4')}
                    size="4x"
                    icon={getIcon(feature.icon)}
                  />
                </div>
              ) : null}

              <div>
                {feature.title ? (
                  <p className="text-xl">
                    <strong>{feature.title}</strong>
                  </p>
                ) : null}

                <PortableText
                  components={portableTextComponents}
                  value={feature.subtitle}
                />
              </div>
            </li>
          ))}
        </ul>
      </Container>
    </Stack>
  );
}

function getIcon(icon: string) {
  switch (icon) {
    case 'person-running':
      return faPersonRunning;
    case 'chart-line':
      return faChartLine;
    case 'people-group':
      return faPeopleGroup;
    case 'lightbulb':
      return faLightbulb;
    case 'arrow-pointer':
      return faArrowPointer;
    case 'trophy':
      return faTrophy;
    case 'credit-card':
      return faCreditCard;
    case 'car':
      return faCar;
    case 'calendar-days':
      return faCalendarDays;
    case 'stopwatch-20':
      return faStopwatch20;
    case 'vest':
      return faVest;
    default:
      return null;
  }
}
