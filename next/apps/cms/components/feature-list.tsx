import { Container } from '@black-pear-joggers/container';
import { FeatureList as FeatureListType } from '../types/content.types';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import { PortableText } from '@portabletext/react';
import { portableTextComponents } from '../core/portable-text/portable-text-components';
import { Stack } from '@black-pear-joggers/stack';

interface FeatureListProps {
  featureList: FeatureListType;
}

export function FeatureList({ featureList }: FeatureListProps) {
  return (
    <Stack>
      <Container>
        <div className="grid gap-4 grid-cols-1 sm:grid-cols-2 md:grid-cols-4">
          {featureList.features.map((feature, index) => (
            <div className="text-center">
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
