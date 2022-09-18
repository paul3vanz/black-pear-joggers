import Link from 'next/link';
import { classNames } from '@black-pear-joggers/helpers';
import { RegisteredAthlete } from '@black-pear-joggers/core-services';
import { toTitleCase } from '../helpers/formatters';
import { useMemo, useState } from 'react';

interface MembersTableProps {
  search: string;
  clubId: string;
  members: RegisteredAthlete[];
}

function isActiveMember(member: RegisteredAthlete): boolean {
  return ['Registered'].includes(member.CompetitiveRegStatus);
}

function Pill(props) {
  return (
    <button
      onClick={props.onClick}
      className={classNames(
        props.active && 'font-bold bg-green-600 text-white',
        !props.active && 'bg-gray-200 text-black',
        'inline-block px-2 py-1 ml-2 rounded-md'
      )}
    >
      {props.text}
    </button>
  );
}

function MembersTable(props: MembersTableProps) {
  const [showActiveOnly, setShowActiveOnly] = useState(true);

  const filteredMembers = useMemo(() => {
    return (
      props.search
        ? props.members.filter((member) => {
            const search = props.search.toLowerCase();
            const name = `${member.Firstname} ${member.Lastname}`.toLowerCase();

            return name.includes(search);
          })
        : props.members
    ).filter((member) => (showActiveOnly ? isActiveMember(member) : true));
  }, [showActiveOnly, props.members, props.search]);

  return (
    <>
      <p>
        Showing <strong>{filteredMembers.length}</strong> members
      </p>

      <p>
        Show
        <Pill
          onClick={() => setShowActiveOnly(false)}
          active={!showActiveOnly}
          text="All"
        />
        <Pill
          onClick={() => setShowActiveOnly(true)}
          active={showActiveOnly}
          text="Registered"
        />
      </p>

      <table className="w-full">
        <thead className="divide-y divide-gray-200">
          <tr>
            <th className="px-4 py-2">URN</th>
            <th className="px-4 py-2">Name</th>
            <th className="px-4 py-2 hidden md:table-cell">Date of birth</th>
            <th className="px-4 py-2 hidden md:table-cell">Gender</th>
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
              <td className="px-4 py-2 hidden md:table-cell">
                {toTitleCase(member.Gender)}
              </td>
              <td className="px-4 py-2 hidden md:table-cell">{member.Dob}</td>
              <td className="px-4 py-2">{member.CompetitiveRegStatus}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </>
  );
}

export default MembersTable;
