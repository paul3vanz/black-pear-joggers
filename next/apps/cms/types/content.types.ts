import { PortableTextBlock } from '@portabletext/types';

export interface InfoRows {
    _type: 'infoRows';
    title: string;
    rows: TextWithIllustration[];
}

export interface TextWithIllustration {
    title: string;
    text: PortableTextBlock[];
    illustration: string;
}

export interface CtaPlug {
    _type: 'ctaPlug';
    label: string;
    title: string;
    body: PortableTextBlock[];
    ctas: Cta[];
}

export interface Cta {
    title: string;
}

export interface Illustration {
    _type: 'illustration',
    image: {
        alt: string;
    }
}

export type ContentItem = InfoRows | CtaPlug | Illustration;