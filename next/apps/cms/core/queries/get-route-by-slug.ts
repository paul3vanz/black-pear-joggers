import { getClient } from '@black-pear-joggers/sanity';
import { groq } from 'next-sanity';
import { Route } from '../../types';

export function getRouteBySlug(slug: string): Promise<Route> {
    return getClient(false).fetch(groq`
    *[
      _type=="route" &&
      slug.current=="${slug}"
    ] |
    order(path) {
      _id,
      title,
      page->{
        _id,
        title,
        navMenu->,
        content
      }
    }[0]
  `);
}