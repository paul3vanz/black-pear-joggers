import { BackgroundColour } from '@black-pear-joggers/stack';
import { PortableTextBlock } from '@portabletext/types';
import { SanityImageAsset } from 'libs/sanity/src/lib/schema';

interface BaseType {
    _key: string;
    _type: string;
}

export interface InfoRows extends BaseType {
    _type: 'infoRows';
    title: string;
    rows: TextWithIllustration[];
}

export interface TextWithIllustration {
    title: string;
    text: PortableTextBlock[];
    illustration: Illustration;
    width: 'narrow' | 'wide';
    cropToFit: boolean;
    backgroundColour: BackgroundColour;
}

export interface CtaPlug extends BaseType {
    _type: 'ctaPlug';
    label: string;
    title: string;
    body: PortableTextBlock[];
    ctas: Cta[];
}

export interface Cta {
    title: string;
    link: string;
}

export interface Illustration extends BaseType {
    _type: 'illustration',
    image: Image;
}

export interface Image {
    _type: 'mainImage',
    alt: string;
    externalUrl?: string;
    asset?: SanityImageAsset;

}

export interface Quote extends BaseType {
    _type: 'quote';
    content: PortableTextBlock[];
    name: string;
    backgroundColour: BackgroundColour;
}

export interface Feature extends BaseType {
    subtitle: PortableTextBlock[];
    title: string;
    icon: string;
}

export interface FeatureList extends BaseType {
    _type: 'featureList';
    features: Feature[];
}

export interface Cards extends BaseType {
    _type: 'cards',
    cards: Card[];
    title: string;
    subtitle: PortableTextBlock[];
}

export interface Card extends BaseType {
    _type: 'card',
    title: string;
    content: PortableTextBlock[];
    link: string;
    image: Image;
}

export interface Hero extends BaseType {
    _type: 'hero';
    label: string;
    heading: string;
    tagline: PortableTextBlock[];
    illustration: Illustration;
    cta: Cta;
}

export type ContentItem = InfoRows | CtaPlug | Illustration | Quote | FeatureList | Cards | Hero;