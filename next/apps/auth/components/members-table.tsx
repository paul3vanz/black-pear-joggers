import { toTitleCase } from '../helpers/formatters';
import Link from 'next/link';
import { Athlete } from '../services/members.interface';

interface MembersTableProps {
  search: string;
  clubId: string;
  members: Athlete[];
}

function getActiveMembers(members: Athlete[]): number {
  return members.filter((member) => {
    return !['Resigned From Club', 'Membership with Club Lapsed'].includes(
      member.CompetitiveRegStatus
    );
  }).length;
}

function MembersTable(props: MembersTableProps) {
  const filteredMembers = props.search
    ? props.members.filter((member) => {
        const search = props.search.toLowerCase();
        const name = `${member.Firstname} ${member.Lastname}`.toLowerCase();

        return name.includes(search);
      })
    : props.members;

  return (
    <>
      <p>
        <strong>{filteredMembers.length}</strong> members (
        <strong>{getActiveMembers(filteredMembers)}</strong> active)
      </p>
      <table className="w-full">
        <thead className="divide-y divide-gray-200">
          <tr>
            <th className="px-4 py-2">URN</th>
            <th className="px-4 py-2">Name</th>
            <th className="px-4 py-2">Date of birth</th>
            <th className="px-4 py-2">Gender</th>
            <th className="px-4 py-2">Registration status</th>
          </tr>
        </thead>
        <tbody className="divide-y divide-gray-200">
          {filteredMembers.map((member, index) => (
            <tr
              key={member.Urn}
              className={index % 2 === 0 ? 'bg-gray-100' : ''}
            >
              <td className="px-4 py-2">{member.Urn}</td>
              <td className="px-4 py-2">
                <Link href={`/clubs/${props.clubId}/members/${member.Urn}`}>
                  {member.Firstname + ' ' + member.Lastname}
                </Link>
              </td>
              <td className="px-4 py-2">{toTitleCase(member.Gender)}</td>
              <td className="px-4 py-2">{member.Dob}</td>
              <td className="px-4 py-2">{member.CompetitiveRegStatus}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </>
  );
}

export default MembersTable;
