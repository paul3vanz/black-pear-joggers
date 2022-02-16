import { getClient } from '@black-pear-joggers/sanity';
import { groq } from 'next-sanity';

export type GetCategories = {
  _id: string;
  title: string;
  description: string;
  slug: {
    current: string
  };
  imageUrl: string;
}

export function getCategories() {
    return getClient(false).fetch<GetCategories[]>(groq`
      *[
        _type=="category" &&
        references("bc0003f3-3e71-4c5d-866d-35de9454f2fd")
      ] |
      order(title) {
        _id,
        title,
        description,
        slug,
        "imageUrl": image.asset->url
      }
    `);
  }