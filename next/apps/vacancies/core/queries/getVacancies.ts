import { getClient } from '@black-pear-joggers/sanity';
import { groq } from 'next-sanity';
import { PortableTextBlock } from '@portabletext/types';

export type GetVacancies = {
  _id: string;
  title: string;
  summary: PortableTextBlock;
  responsibilities: PortableTextBlock;
  howToApply: PortableTextBlock;
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
        "imageUrl": image.asset->url
      }
    `);
  }