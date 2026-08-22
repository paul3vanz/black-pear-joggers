import { config } from '@black-pear-joggers/core-services';
import { FetchAthleteResult } from '../types/power-of-ten';

/**
 * Read one athlete's performances and handicap from Power of 10.
 *
 * A single call covers both, because the API reads their profile page once and
 * takes what it needs from it.
 */
export async function fetchAthlete(
  athleteId: number
): Promise<FetchAthleteResult> {
  const response = await fetch(`${config.baseApiUrl}/fetch/athlete/${athleteId}`);

  if (!response.ok) {
    throw new Error(`The API returned ${response.status}`);
  }

  const body = await response.json();

  // Unknown routes on the API answer 200 with a body of 0 rather than a 404,
  // so a typo in the URL would otherwise read as a silent success.
  if (!body || typeof body !== 'object' || !('success' in body)) {
    throw new Error('The API returned something unexpected');
  }

  return body as FetchAthleteResult;
}

/**
 * A sentence describing how a fetch went, for a tooltip.
 */
export function describeFetch(result: FetchAthleteResult): string {
  if (!result.success) {
    return result.message ?? 'Failed';
  }

  const { added, firstDate, lastDate } = result.performances;
  const range =
    firstDate && lastDate ? `, ${firstDate} to ${lastDate}` : '';
  const handicap = result.rankings.added
    ? `, ${result.rankings.added} handicap readings`
    : '';

  return `${added} performance${added === 1 ? '' : 's'}${range}${handicap}`;
}
