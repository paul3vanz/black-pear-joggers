import { AwardClaim, Performance } from '@black-pear-joggers/core-services';
import { Award } from '../types/award';

// Manual claims are stored as an AwardClaim + AwardClaimRace[], not as
// Performance[] the way auto-built awards are. CertificatePreview only cares
// about a handful of fields shared by both shapes, so map into that shape
// here rather than forking the component.
export function mapAwardClaimToCertificateProps(claim: AwardClaim) {
  const performances: Performance[] = claim.races.map((race) => ({
    id: race.id,
    award: Award[race.award as keyof typeof Award] ?? Award.None,
    athleteId: claim.athleteId ?? 0,
    firstName: claim.firstName,
    lastName: claim.lastName,
    gender: claim.gender,
    membershipStatus: '',
    category: claim.category,
    event: race.distance,
    time: race.time,
    timeParsed: String(race.timeParsed),
    meetingId: 0,
    meetingName: race.race,
    date: race.date,
    isPersonalBest: 0,
  }));

  return {
    athlete: {
      first_name: claim.firstName,
      last_name: claim.lastName,
      gender: claim.gender,
    },
    year: awardClaimYear(claim),
    category: claim.category,
    performances,
    award: Award[claim.award as keyof typeof Award] ?? Award.None,
  };
}

export function awardClaimYear(claim: AwardClaim): number {
  const firstRaceDate = claim.races[0]?.date;

  return firstRaceDate
    ? new Date(firstRaceDate).getFullYear()
    : new Date(claim.createdDate).getFullYear();
}
