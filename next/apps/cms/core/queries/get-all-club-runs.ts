import { ClubRun } from '../../types/club-run.types';
import { getClient } from '@black-pear-joggers/sanity';
import { groq } from 'next-sanity';

export function getAllClubRuns(): Promise<ClubRun[]> {
    return getClient(false).fetch(groq`
    *[
      _type == "clubRun" &&
      disabled != true
    ] |
    order(day desc) {
      _id,
      disabled,
      title,
      slug,
      day,
      time,
      image,
    }
  `);
}