import { getClient } from '@black-pear-joggers/sanity';
import { groq } from 'next-sanity';
import { Post } from '../../types';

export function getAllPosts(): Promise<Post[]> {
    return getClient(false).fetch(groq`
    *[
      _type=="post"
    ] |
    order(publishedAt desc) {
      _id,
      title,
      slug,
      body,
      publishedAt,
      mainImage,
    }
  `);
}