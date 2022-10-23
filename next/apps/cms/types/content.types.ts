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
    image: {
        alt: string;
    }
}

export interface Quote extends BaseType {
    _key: string;
    _type: 'quote';
    content: PortableTextBlock[];
    name: string;
    backgroundColour: BackgroundColour;
}

export interface Feature {
    _key: string;
    _type: string;
    subtitle: PortableTextBlock[];
    title: string;
    icon: string;
}

export interface FeatureList {
    _key: string;
    _type: 'featureList';
    features: Feature[];
}



export type ContentItem = InfoRows | CtaPlug | Illustration | Quote | FeatureList;