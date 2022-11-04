import { getClient } from '@black-pear-joggers/sanity';
import { groq } from 'next-sanity';
import { Page } from '../../types/page.types';

export function getFrontPage(): Promise<Page> {
    return getClient(false).fetch(groq`
    *[
      _type=="page" &&
      _id=="frontpage"
    ] {
        _id,
        title,
        navMenu->,
        content
    }[0]
  `);
}