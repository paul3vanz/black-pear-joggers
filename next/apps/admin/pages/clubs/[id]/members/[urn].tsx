import Link from 'next/link';
import { booleanLabels, toTitleCase } from '../../../../helpers/formatters';
import { Button } from '@black-pear-joggers/button';
import { Container } from '@black-pear-joggers/container';
import { LoadingSpinner } from 'apps/admin/components/loading-spinner';
import { Stack } from '@black-pear-joggers/stack';
import { useMember } from '@black-pear-joggers/core-services';
import { useRouter } from 'next/dist/client/router';
import { withAuthenticationRequired } from '@auth0/auth0-react';

function MemberDetailsPage() {
  const router = useRouter();
  const { urn, id: clubId } = router.query;
  const { member, isLoading, isError } = useMember(Number(urn));

  if (isLoading) {
    return (
      <Stack>
        <Container>
          <div className="flex justify-center">
            <LoadingSpinner />
          </div>
        </Container>
      </Stack>
    );
  }

  return (
    <Stack>
      <Container>
        <p>
          <Link href={`/clubs/${clubId}/members`}>Back to members</Link>
        </p>

        <h1>
          {member.Firstname} {member.Lastname}
        </h1>

        <ul className="list-disc list-inside mb-4">
          <li>
            <strong>URN:</strong> {member.Urn}
          </li>

          <li>
            <strong>Registration status:</strong> {member.CompetitiveRegStatus}
          </li>

          <li>
            <strong>Gender:</strong> {toTitleCase(member.Gender)}
          </li>

          <li>
            <strong>Date of birth:</strong> {member.Dob}
          </li>
          <li>
            <strong>First claim club:</strong>{' '}
            <Link href={`/clubs/${member.FirstClaimClubId}/members`}>
              {member.FirstClaimClubName}
            </Link>
          </li>

          {member.FirstClaimOtherId && (
            <li>
              <strong>First claim other club:</strong>{' '}
              <Link href={`/clubs/${member.FirstClaimOtherId}/members`}>
                {member.FirstClaimOtherName}
              </Link>
            </li>
          )}

          {member.SecondClaimClubId && (
            <li>
              <strong>Second claim club:</strong>{' '}
              <Link href={`/clubs/${member.SecondClaimClubId}/members`}>
                {member.SecondClaimClubName}
              </Link>
            </li>
          )}

          {member.HigherClaimClubId && (
            <li>
              <strong>Higher claim club:</strong>{' '}
              <Link href={`/clubs/${member.SecondClaimClubId}/members`}>
                {member.SecondClaimClubName}
              </Link>
            </li>
          )}

          {member.ForeignFlag && (
            <li>
              <strong>Foreign flag:</strong> {booleanLabels(member.ForeignFlag)}
            </li>
          )}
        </ul>

        <span className="mr-4">
          <Button
            text="Power of 10"
            link={`https://thepowerof10.info/athletes/profile.aspx?ukaurn=${urn}`}
          ></Button>
        </span>

        <Button
          text="runbritain Rankings"
          link={`https://www.runbritainrankings.com/runners/profile.aspx?ukaurn=${urn}`}
        ></Button>
      </Container>
    </Stack>
  );
}

export default withAuthenticationRequired(MemberDetailsPage);
