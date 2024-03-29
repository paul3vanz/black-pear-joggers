import { getClient } from '@black-pear-joggers/sanity';
import { groq } from 'next-sanity';
import { Post } from '../../types';


export function getPostBySlug(slug: string): Promise<Post> {
    return getClient(false).fetch(groq`
    *[
      _type=="post" &&
      slug.current=="${slug}"
    ] |
    order(title) {
      _id,
      title,
      slug,
      body,
      publishedAt,
      mainImage,
      authors[]{author->{name, image}}
    }[0]
  `);
}