import Link from 'next/link';
import { AwardClaim, Standard } from '@black-pear-joggers/core-services';
import { AwardClaimDetailsModal } from './award-claim-details-modal';
import { dateIsBefore, friendlyDate } from '@black-pear-joggers/helpers';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import { Pill } from '@black-pear-joggers/ui/atoms/pill';
import { StandardsBadge } from '../standards-badge';
import { StandardsTable } from './standards-table';
import { useRouter } from 'next/router';
import { useState } from 'react';
import {
  allEventsAreAllowedDistances,
  checkRacesCompletedInCorrectCategory,
  checkRacesCompletedInSameCalendarYear,
  checkRacesMeetStandardClaimed,
  checkThreeOrMoreDistances,
} from '@black-pear-joggers/core-services';
import {
  faArchive,
  faCheckCircle,
  faEnvelope,
  faPrint,
  faTimesCircle,
  faTrash,
} from '@fortawesome/free-solid-svg-icons';

interface AwardClaimsTableProps {
  search: string;
  awardClaims: AwardClaim[];
  standards: Standard[];
  onToggleVerified: (awardClaim: AwardClaim) => void;
  onDelete: (awardClaim: AwardClaim) => void;
  onArchive: (awardClaim: AwardClaim) => void;
}

enum TableFilterStates {
  All,
  Active,
  Archived,
}

export function AwardClaimsTable(props: AwardClaimsTableProps) {
  const router = useRouter();
  const [isRacesModalOpen, setIsRacesModalOpen] = useState(false);
  const [tableFilterState, setTableFilterState] = useState<TableFilterStates>(
    TableFilterStates.Active
  );
  const [selectedAwardClaim, setSelectedAwardClaim] =
    useState<AwardClaim>(null);

  const filteredAwardClaims = props.awardClaims
    ? props.awardClaims
        .sort((a, b) => (dateIsBefore(a.createdDate, b.createdDate) ? 0 : -1))
        .filter((awardClaim) => {
          switch (tableFilterState) {
            case TableFilterStates.Archived:
              return awardClaim.archived;
            case TableFilterStates.Active:
              return !awardClaim.archived;
            default:
              return true;
          }
        })
        .filter((awardClaim) => {
          if (!props.search) {
            return true;
          }

          const search = props.search.toLowerCase();
          const name =
            `${awardClaim.firstName} ${awardClaim.lastName}`.toLowerCase();

          return name.includes(search);
        })
    : [];

  return (
    <>
      <AwardClaimDetailsModal
        isOpen={isRacesModalOpen}
        onClose={() => setIsRacesModalOpen(false)}
      >
        <AwardClaimRaces
          awardClaim={selectedAwardClaim}
          standards={props.standards}
        />
      </AwardClaimDetailsModal>

      <p>
        <strong>{filteredAwardClaims.length}</strong> award claims
      </p>

      <p>
        Show
        {Object.keys(TableFilterStates)
          .filter((v) => isNaN(Number(v)))
          .map((filterState, index) => (
            <Pill
              key={index}
              onClick={() =>
                setTableFilterState(TableFilterStates[filterState])
              }
              active={tableFilterState === TableFilterStates[filterState]}
              text={filterState}
            />
          ))}
      </p>

      <table className="w-full">
        <thead className="divide-y divide-gray-200">
          <tr>
            <th className="px-4 py-2">Submitted</th>
            <th className="px-4 py-2">Name</th>
            <th className="px-4 py-2">Category</th>
            <th className="px-4 py-2">Award</th>
            <th className="px-4 py-2">Races</th>
            <th className="px-4 py-2">Verified</th>
            <th className="px-4 py-2">Actions</th>
          </tr>
        </thead>

        <tbody className="divide-y divide-gray-200">
          {filteredAwardClaims.map((awardClaim, index) => (
            <tr
              key={awardClaim.id}
              className={index % 2 === 0 ? 'bg-gray-100' : ''}
            >
              <td className="px-4 py-2">
                {friendlyDate(awardClaim.createdDate)}
              </td>

              <td className="px-4 py-2">
                <Link href={`/club-standards/${awardClaim.id}`}>
                  {awardClaim.firstName + ' ' + awardClaim.lastName}
                </Link>
              </td>

              <td className="px-4 py-2">{awardClaim.category}</td>

              <td className="px-4 py-2">
                {awardClaim.award && (
                  <StandardsBadge standard={awardClaim.award} />
                )}
              </td>

              <td className="px-4 py-2">
                <button
                  className="text-orange-400 font-bold"
                  onClick={() => {
                    setSelectedAwardClaim(awardClaim);
                    setIsRacesModalOpen(true);
                  }}
                >
                  {awardClaim.races.length}
                </button>
              </td>

              <td className="px-4 py-2">
                <button
                  onClick={() => props.onToggleVerified(awardClaim)}
                  className="cursor-pointer"
                >
                  {awardClaim.verified ? (
                    <FontAwesomeIcon
                      className="text-green-600"
                      size="lg"
                      icon={faCheckCircle}
                    />
                  ) : (
                    <FontAwesomeIcon
                      className="text-red-600"
                      size="lg"
                      icon={faTimesCircle}
                    />
                  )}
                </button>
              </td>

              <td className="px-4 py-2">
                <button
                  className="mr-3"
                  title="View certificate"
                  onClick={() =>
                    window.open(
                      'https://black-pear-joggers.netlify.com/apps/club-standards/?certificateId=' +
                        awardClaim.id
                    )
                  }
                >
                  <FontAwesomeIcon
                    className="cursor-pointer"
                    size="lg"
                    icon={faPrint}
                  />
                </button>

                <button
                  className="mr-3"
                  title="Email"
                  onClick={() =>
                    router.push(`/club-standards/${awardClaim.id}/email`)
                  }
                >
                  <FontAwesomeIcon
                    className="cursor-pointer"
                    size="lg"
                    icon={faEnvelope}
                  />
                </button>

                <button
                  className="mr-3"
                  title="Archive"
                  onClick={() => props.onArchive(awardClaim)}
                >
                  <FontAwesomeIcon
                    className="cursor-pointer"
                    size="lg"
                    icon={faArchive}
                  />
                </button>

                <button
                  title="Delete"
                  onClick={() => props.onDelete(awardClaim)}
                >
                  <FontAwesomeIcon
                    className="cursor-pointer"
                    size="lg"
                    icon={faTrash}
                  />
                </button>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </>
  );
}

function AwardClaimRaces(props: {
  awardClaim: AwardClaim;
  standards: Standard[];
}) {
  return (
    <>
      <h2 className="text-2xl">Details</h2>

      <ul className="mb-4 list-disc list-inside">
        <li className="mb-2">
          <strong>Name:</strong> {props.awardClaim.firstName}{' '}
          {props.awardClaim.lastName}
        </li>
        <li className="mb-2">
          <strong>Category:</strong> {props.awardClaim.gender}
          {props.awardClaim.category}
        </li>
        <li className="mb-2">
          <strong>Award:</strong> {props.awardClaim.award}
        </li>
      </ul>

      <h2 className="text-2xl">Races</h2>

      <div>
        {props.awardClaim && (
          <ul className="mb-4 list-disc list-inside">
            {props.awardClaim.races.map((race) => (
              <li key={race.id} className="mb-2">
                <strong>{race.date}:</strong> {race.distance} - {race.race} ={' '}
                {race.time}
              </li>
            ))}
          </ul>
        )}
      </div>

      <h2 className="text-2xl">Checks</h2>

      <ul className="mb-4">
        <li className="mb-2">
          <CheckResult
            isSuccess={checkRacesCompletedInSameCalendarYear(props.awardClaim)}
            label="Races completed in the same calendar year"
          />
        </li>

        <li className="mb-2">
          <CheckResult
            isSuccess={allEventsAreAllowedDistances(props.awardClaim)}
            label="All event distances count (Mile, 5K, 10K, HM, Mar)"
          />
        </li>

        <li className="mb-2">
          <CheckResult
            isSuccess={checkThreeOrMoreDistances(props.awardClaim)}
            label="Three or more different distances completed"
          />
        </li>

        <li className="mb-2">
          <CheckResult
            isSuccess={checkRacesMeetStandardClaimed(
              props.awardClaim,
              props.standards
            )}
            label="Races meet the standard claimed"
          />
        </li>

        <li className="mb-2">
          <CheckResult
            isSuccess={checkRacesCompletedInCorrectCategory(
              props.awardClaim,
              props.standards
            )}
            label="[Manual Check] All races completed in claimed age category"
          />
        </li>
      </ul>

      <h2 className="text-2xl">Standards</h2>

      <StandardsTable
        standards={props.standards}
        gender={props.awardClaim.gender}
        category={props.awardClaim.category}
        standardClaimed={props.awardClaim.award}
      />
    </>
  );
}

function CheckResult(props: { isSuccess: boolean; label: string }) {
  return (
    <>
      <FontAwesomeIcon
        size="lg"
        className={props.isSuccess ? 'text-green-600' : 'text-red-600'}
        icon={props.isSuccess ? faCheckCircle : faTimesCircle}
        title={props.isSuccess ? 'Pass' : 'Fail'}
      />

      <span className="ml-2">{props.label}</span>
    </>
  );
}
