import { getClient } from '@black-pear-joggers/sanity';
import { groq } from 'next-sanity';
import { PortableTextBlock } from '@portabletext/types';

export enum VacancyStatus {
    Recruiting = 'recruiting',
    Filled = 'filled',
    Hidden = 'hidden'
}

export type GetVacancies = {
    _id: string;
    title: string;
    summary: PortableTextBlock[];
    responsibilities: PortableTextBlock[];
    howToApply: PortableTextBlock[];
    status: VacancyStatus;
    newRecruit?: string;
    slug: {
        current: string
    };
    imageUrl: string;
}

export function getVacancies() {
    return getClient(false).fetch<GetVacancies[]>(groq`
      *[
        _type=="vacancy"
      ] |
      order(title) {
        _id,
        title,
        slug,
        summary,
        responsibilities,
        howToApply,
        status,
        newRecruit,
        "imageUrl": image.asset->url
      }
    `);
}