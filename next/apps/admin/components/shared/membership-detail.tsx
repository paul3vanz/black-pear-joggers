import Link from 'next/link';
import { Membership } from '@black-pear-joggers/core-services';
import { toTitleCase } from '../../helpers/formatters';
import { timestamp } from '@black-pear-joggers/helpers';

interface MembershipDetailProps {
  membership: Membership;
}

export function MembershipDetail(props: MembershipDetailProps) {
  return (
    <ul className="list-disc list-inside mb-4">
      <li>
        <strong>Registration status:</strong>{' '}
        {props.membership.competitiveRegStatus}
      </li>

      <li>
        <strong>Gender:</strong> {toTitleCase(props.membership.gender)}
      </li>

      <li>
        <strong>First claim club:</strong>{' '}
        <Link href={`/clubs/${props.membership.firstClaimClubId}/members`}>
          {props.membership.firstClaimClubName}
        </Link>
      </li>

      <li>
        <strong>First claim other club:</strong>{' '}
        {props.membership.firstClaimOtherId ? (
          <Link href={`/clubs/${props.membership.firstClaimOtherId}/members`}>
            {props.membership.firstClaimOtherName}
          </Link>
        ) : (
          'None'
        )}
      </li>

      <li>
        <strong>Second claim club:</strong>{' '}
        {props.membership.secondClaimClubId ? (
          <Link href={`/clubs/${props.membership.secondClaimClubId}/members`}>
            {props.membership.secondClaimClubName}
          </Link>
        ) : (
          'None'
        )}
      </li>

      <li>
        <strong>Higher claim club:</strong>{' '}
        {props.membership.higherClaimClubId ? (
          <Link href={`/clubs/${props.membership.secondClaimClubId}/members`}>
            {props.membership.secondClaimClubName}
          </Link>
        ) : (
          'None'
        )}
      </li>

      <li>
        <strong>Foreign flag:</strong>{' '}
        {props.membership.foreignFlag ? 'Yes' : 'No'}
      </li>

      <li>
        <strong>Created date:</strong> {timestamp(props.membership.created_at)}
      </li>

      <li>
        <strong>Updated date:</strong> {timestamp(props.membership.updated_at)}
      </li>
    </ul>
  );
}
