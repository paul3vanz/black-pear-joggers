import { Container } from '@black-pear-joggers/container';
import { CtaPlug } from './cta-plug';
import { InfoRows } from './info-rows';
import { Stack } from '@black-pear-joggers/stack';
import {
  ContentItem,
  CtaPlug as CtaPlugType,
  InfoRows as InfoRowsType,
} from '../types/content.types';

export interface PageBuilderProps {
  content: ContentItem[];
}

export function PageBuilder(props: PageBuilderProps) {
  return props.content.map((contentItem) => {
    switch (contentItem._type) {
      case 'infoRows':
        return <InfoRows rows={contentItem.rows} />;
      case 'ctaPlug':
        return <CtaPlug {...contentItem} />;
    }
  });
}
