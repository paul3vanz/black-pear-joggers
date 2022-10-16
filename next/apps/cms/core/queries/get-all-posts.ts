import { getClient } from '@black-pear-joggers/sanity';
import { groq } from 'next-sanity';
import { Post } from 'apps/cms/types';

export function getAllPosts(): Promise<Post[]> {
    return getClient(false).fetch(groq`
    *[
      _type=="post"
    ] |
    order(title) {
      _id,
      title,
      slug,
    }
  `);
}