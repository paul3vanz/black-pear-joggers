import { Stack } from '@black-pear-joggers/stack';
import { Container } from '@black-pear-joggers/container';
import { Button } from '@black-pear-joggers/button';
import { withAuthenticationRequired } from '@auth0/auth0-react';

import Link from 'next/link';
import { useRouter } from 'next/dist/client/router';
import { useEffect } from 'react';
import { useMember } from '../../../../services/members';

function MemberDetailsPage() {
  const router = useRouter();
  const { urn, id: clubId } = router.query;
  const { member, isLoading, isError } = useMember(Number(urn));

  if (isLoading) {
    return (
      <Stack>
        <Container>
          <p>Loading...</p>
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
            <strong>CompetitiveRegStatus:</strong> {member.CompetitiveRegStatus}
          </li>
          <li>
            <strong>Dob:</strong> {member.Dob}
          </li>
          <li>
            <strong>FirstClaimClubId:</strong> {member.FirstClaimClubId}
          </li>
          <li>
            <strong>FirstClaimClubName:</strong> {member.FirstClaimClubName}
          </li>
          <li>
            <strong>FirstClaimOtherId:</strong> {member.FirstClaimOtherId}
          </li>
          <li>
            <strong>FirstClaimOtherName:</strong> {member.FirstClaimOtherName}
          </li>
          <li>
            <strong>Firstname:</strong> {member.Firstname}
          </li>
          <li>
            <strong>ForeignFlag:</strong> {member.ForeignFlag}
          </li>
          <li>
            <strong>Gender:</strong> {member.Gender}
          </li>
          <li>
            <strong>HigherClaimClubId:</strong> {member.HigherClaimClubId}
          </li>
          <li>
            <strong>HigherClaimClubName:</strong> {member.HigherClaimClubName}
          </li>
          <li>
            <strong>Lastname:</strong> {member.Lastname}
          </li>
          <li>
            <strong>SecondClaimClubId:</strong> {member.SecondClaimClubId}
          </li>
          <li>
            <strong>SecondClaimClubName:</strong> {member.SecondClaimClubName}
          </li>
          <li>
            <strong>Urn:</strong> {member.Urn}
          </li>
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
