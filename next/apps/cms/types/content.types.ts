import { BackgroundColour } from '@black-pear-joggers/stack';
import { PortableTextBlock } from '@portabletext/types';
import { SanityImageAsset } from 'libs/sanity/src/lib/schema';
import { Slug } from './slug.types';

interface BaseType {
    _key: string;
    _type: string;
    disabled: boolean;
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
    disabled: boolean;
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

export interface UiComponent extends BaseType {
    _type: 'uiComponentRef',
    name: string;
}

export interface Illustration extends BaseType {
    _type: 'illustration',
    image: Image;
    images: Image[];
}

export interface Image {
    _type: 'mainImage',
    alt: string;
    caption?: string;
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
    orientation: 'horizontal' | 'vertical';
}

export interface Cards extends BaseType {
    _type: 'cards',
    cards: Card[];
    title: string;
    subtitle: PortableTextBlock[];
    maxColumns?: number;
    backgroundColour: BackgroundColour;
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

export interface Steps extends BaseType {
    _type: 'steps';
    title: string;
    subtitle: PortableTextBlock[];
    steps: Step[];
}

export interface Step {
    title: string;
    content: PortableTextBlock[];
}

export enum AlertTypes {
    Success = 'success',
    Info = 'info',
    Warning = 'warning',
    Error = 'error'
}

export interface Alert extends BaseType {
    _type: 'alert';
    title: string;
    content: PortableTextBlock[];
    type: AlertTypes;
}

export type ContentItem = InfoRows | CtaPlug | Illustration | Quote | FeatureList | Cards | Hero | UiComponent | Steps | Alert;