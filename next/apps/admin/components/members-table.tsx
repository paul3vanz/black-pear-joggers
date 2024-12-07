import Link from 'next/link';
import { ageCategories } from '../helpers/enums';
import { Pill } from '@black-pear-joggers/ui/atoms/pill';
import { RegisteredAthlete } from '@black-pear-joggers/core-services';
import { toAgeCategory, toTitleCase } from '../helpers/formatters';
import { useMemo, useState } from 'react';

interface MembersTableProps {
  search: string;
  clubId: string;
  members: RegisteredAthlete[];
}

function isActiveMember(member: RegisteredAthlete): boolean {
  return ['Registered'].includes(member.CompetitiveRegStatus);
}

function MembersTable(props: MembersTableProps) {
  const [showActiveOnly, setShowActiveOnly] = useState(true);
  const [filterGender, setFilterGender] = useState<string>(null);
  const [filterCategory, setFilterCategory] = useState(null);

  const filteredMembers = useMemo(() => {
    return (
      props.search
        ? props.members.filter((member) => {
            const search = props.search.toLowerCase();
            const name = `${member.Firstname} ${member.Lastname}`.toLowerCase();

            return name.includes(search);
          })
        : props.members
    )
      .filter((member) => (showActiveOnly ? isActiveMember(member) : true))
      .filter((member) =>
        filterGender
          ? member.Gender === filterGender.toUpperCase()
            ? true
            : false
          : true
      )
      .filter((member) =>
        filterCategory
          ? toAgeCategory(member.Dob) === filterCategory
            ? true
            : false
          : true
      );
  }, [
    showActiveOnly,
    filterGender,
    filterCategory,
    props.members,
    props.search,
  ]);

  return (
    <>
      <p>
        Showing <strong>{filteredMembers.length}</strong> members
      </p>

      <p>
        <strong>Status</strong>
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

      <p>
        <strong>Gender</strong>
        <Pill
          onClick={() => setFilterGender(null)}
          active={!filterGender}
          text="All"
        />
        <Pill
          onClick={() => setFilterGender('Male')}
          active={filterGender === 'Male'}
          text="Male"
        />
        <Pill
          onClick={() => setFilterGender('Female')}
          active={filterGender === 'Female'}
          text="Female"
        />
      </p>

      <p>
        <strong>Category</strong>
        <Pill
          onClick={() => setFilterCategory(null)}
          active={!filterCategory}
          text="All"
        />
        {ageCategories.map((ageCategory) => (
          <Pill
            onClick={() => setFilterCategory(ageCategory)}
            active={filterCategory === ageCategory}
            text={ageCategory}
          />
        ))}
      </p>

      <table className="w-full">
        <thead className="divide-y divide-gray-200">
          <tr>
            <th className="px-4 py-2">URN</th>
            <th className="px-4 py-2">Name</th>
            <th className="px-4 py-2 hidden md:table-cell">Gender</th>
            <th className="px-4 py-2 hidden md:table-cell">Date of birth</th>
            <th className="px-4 py-2 hidden md:table-cell">Category</th>
            <th className="px-4 py-2">Registration status</th>
          </tr>
        </thead>
        <tbody className="divide-y divide-gray-200">
          {filteredMembers.map((member, index) => (
            <tr
              key={`${member.Urn}-${member.FirstClaimClubId}-${member.SecondClaimClubId}`}
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
              <td className="px-4 py-2 hidden md:table-cell">
                {toAgeCategory(member.Dob)}
              </td>
              <td className="px-4 py-2">{member.CompetitiveRegStatus}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </>
  );
}

export default MembersTable;
