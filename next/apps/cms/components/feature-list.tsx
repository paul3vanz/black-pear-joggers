import { BackgroundColour, Stack } from '@black-pear-joggers/stack';
import { classNames } from '@black-pear-joggers/helpers';
import { Container } from '@black-pear-joggers/container';
import { FeatureList as FeatureListType } from '../types/content.types';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import { PortableText } from '@portabletext/react';
import { portableTextComponents } from '../core/portable-text/portable-text-components';

interface FeatureListProps {
  featureList: FeatureListType;
}

export function FeatureList({ featureList }: FeatureListProps) {
  const isHorizontal = featureList.orientation !== 'vertical';

  return (
    <Stack backgroundColour={BackgroundColour.Light}>
      <Container>
        <div
          className={classNames(
            'grid gap-4 grid-cols-1',
            isHorizontal && 'sm:grid-cols-2 md:grid-cols-4'
          )}
        >
          {featureList.features.map((feature) => (
            <div
              className={isHorizontal ? 'text-center' : 'flex'}
              key={feature._key}
            >
              {feature.icon ? (
                <div>
                  <FontAwesomeIcon
                    className={classNames('mb-4', !isHorizontal && 'mr-4')}
                    size="4x"
                    icon={['fas', feature.icon as any]}
                  />
                </div>
              ) : null}

              <div>
                {feature.title ? (
                  <h3 className="text-xl">{feature.title}</h3>
                ) : null}

                <PortableText
                  components={portableTextComponents}
                  value={feature.subtitle}
                />
              </div>
            </div>
          ))}
        </div>
      </Container>
    </Stack>
  );
}
