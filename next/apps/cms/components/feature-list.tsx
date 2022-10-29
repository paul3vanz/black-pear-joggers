import { BackgroundColour, Stack } from '@black-pear-joggers/stack';
import { Container } from '@black-pear-joggers/container';
import { FeatureList as FeatureListType } from '../types/content.types';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import { PortableText } from '@portabletext/react';
import { portableTextComponents } from '../core/portable-text/portable-text-components';

interface FeatureListProps {
  featureList: FeatureListType;
}

export function FeatureList({ featureList }: FeatureListProps) {
  return (
    <Stack backgroundColour={BackgroundColour.Light}>
      <Container>
        <div className="grid gap-4 grid-cols-1 sm:grid-cols-2 md:grid-cols-4">
          {featureList.features.map((feature) => (
            <div className="text-center" key={feature._key}>
              {feature.icon ? (
                <FontAwesomeIcon
                  className="mb-4"
                  size="4x"
                  icon={['fas', feature.icon as any]}
                />
              ) : null}

              <h3 className="text-xl">{feature.title}</h3>

              <PortableText
                components={portableTextComponents}
                value={feature.subtitle}
              />
            </div>
          ))}
        </div>
      </Container>
    </Stack>
  );
}
