import { ClubRun } from '../../types/club-run.types';
import { getClient } from '@black-pear-joggers/sanity';
import { groq } from 'next-sanity';
import { Post } from '../../types';


export function getClubRunBySlug(slug: string): Promise<ClubRun> {
    return getClient(false).fetch(groq`
    *[
      _type=="clubRun" &&
      slug.current=="${slug}"
    ] |
    order(title) {
      _id,
      title,
      day,
      time,
      slug,
      summary,
      content,
      venue->,
      image,
      authors[]{author->{name, image}}
    }[0]
  `);
}