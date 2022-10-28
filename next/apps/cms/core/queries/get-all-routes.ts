import { getClient } from '@black-pear-joggers/sanity';
import { groq } from 'next-sanity';
import { Route } from '../../types/route.types';

export function getAllRoutes(): Promise<Route[]> {
    return getClient(false).fetch(groq`
    *[
      _type=="route"
    ] |
    order(path.current) {
      slug,
      page->{
        _id,
        title
      }
    }
  `);
}