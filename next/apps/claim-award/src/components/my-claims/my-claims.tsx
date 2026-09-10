import { Container } from '@black-pear-joggers/container';
import { BackgroundColour, Stack } from '@black-pear-joggers/stack';
import { AwardClaim, useMyAwardClaims } from '@black-pear-joggers/core-services';
import { friendlyDate } from '@black-pear-joggers/helpers';
import Link from 'next/link';

export function MyClaims(props: { athleteId?: number }) {
  const { myAwardClaims, isLoading } = useMyAwardClaims(props.athleteId);

  const activeClaims = (myAwardClaims || []).filter((claim) => !claim.archived);

  if (isLoading) {
    return (
      <Stack backgroundColour={BackgroundColour.Light}>
        <Container>
          <h2>Your claims</h2>
          <p>Loading...</p>
        </Container>
      </Stack>
    );
  }

  if (!activeClaims.length) {
    return null;
  }

  return (
    <Stack backgroundColour={BackgroundColour.Light}>
      <Container>
        <h2>Your claims</h2>

        <ul className="divide-y divide-gray-200">
          {activeClaims.map((claim) => (
            <li key={claim.id} className="py-3 flex items-center justify-between">
              <span>
                <strong>{claim.award}</strong> &mdash;{' '}
                {claim.category.replace('SEN', 'Senior')}, submitted{' '}
                {friendlyDate(claim.createdDate)}
              </span>

              <StatusAndLink claim={claim} />
            </li>
          ))}
        </ul>
      </Container>
    </Stack>
  );
}

function StatusAndLink(props: { claim: AwardClaim }) {
  const { claim } = props;

  return (
    <span className="flex items-center gap-3">
      <span
        className={
          claim.verified
            ? 'text-green-700 font-semibold'
            : 'text-orange-500 font-semibold'
        }
      >
        {claim.verified ? 'Verified' : 'Pending verification'}
      </span>

      {claim.token && (
        <Link
          href={`/certificate?id=${claim.id}&token=${claim.token}`}
          className="underline"
        >
          View certificate
        </Link>
      )}
    </span>
  );
}
