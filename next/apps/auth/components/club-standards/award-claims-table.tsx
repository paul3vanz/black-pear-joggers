import { toTitleCase } from '../../helpers/formatters';
import Link from 'next/link';
import { friendlyDate, dateIsBefore } from '@black-pear-joggers/helpers';
import { AwardClaim } from '../../services/award-claims.interface';
import { StandardsBadge } from '../standards-badge';
import { useState } from 'react';
import { createPortal } from 'react-dom';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import {
  faCheckCircle,
  faTimesCircle,
  faPrint,
} from '@fortawesome/free-solid-svg-icons';

interface AwardClaimsTableProps {
  search: string;
  awardClaims: AwardClaim[];
  onToggleVerified: (awardClaim: AwardClaim) => void;
}

function AwardClaimsTable(props: AwardClaimsTableProps) {
  const [isRacesModalOpen, setIsRacesModalOpen] = useState(false);
  const [selectedAwardClaim, setSelectedAwardClaim] =
    useState<AwardClaim>(null);

  console.log(props.awardClaims);

  const filteredAwardClaims = props.awardClaims
    ? props.awardClaims
        .sort((a, b) => (dateIsBefore(a.createdDate, b.createdDate) ? 0 : -1))
        .filter((awardClaim) => !awardClaim.archived)
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
        <AwardClaimRaces awardClaim={selectedAwardClaim} />
      </AwardClaimDetailsModal>

      <p>
        <strong>{filteredAwardClaims.length}</strong> award claims
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
            <th className="px-4 py-2">Checks</th>
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
                {awardClaim.athleteId ? (
                  <Link href={`/athletes/${awardClaim.athleteId}`}>
                    {awardClaim.firstName + ' ' + awardClaim.lastName}
                  </Link>
                ) : (
                  <>{awardClaim.firstName + ' ' + awardClaim.lastName}</>
                )}
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
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </>
  );
}

function AwardClaimRaces(props: { awardClaim: AwardClaim }) {
  return (
    <div>
      {props.awardClaim && (
        <>
          {props.awardClaim.races.map((race) => (
            <p key={race.id}>
              {race.date}: {race.race} ({race.distance}) = {race.time}
            </p>
          ))}
        </>
      )}
    </div>
  );
}

function AwardClaimDetailsModal(props: {
  isOpen: boolean;
  onClose: () => void;
  children: JSX.Element;
}) {
  const modalContainer = document.getElementById('modalContainer');

  return (
    props.isOpen &&
    createPortal(
      <>
        <div
          className="fixed z-50 inset-0 overflow-y-auto"
          aria-labelledby="modal-title"
          role="dialog"
          aria-modal="true"
        >
          <div className="flex items-end justify-center min-h-screen pt-4 px-4 pb-20 text-center sm:block sm:p-0">
            <div
              className="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity"
              aria-hidden="true"
            ></div>
            <span
              className="hidden sm:inline-block sm:align-middle sm:h-screen"
              aria-hidden="true"
            >
              &#8203;
            </span>
            <div className="inline-block align-bottom bg-white rounded-lg text-left overflow-hidden shadow-xl transform transition-all sm:my-8 sm:align-middle sm:max-w-lg sm:w-full">
              <div className="bg-white px-4 pt-5 pb-4 sm:p-6 sm:pb-4">
                <div className="mt-3 text-center sm:mt-0 sm:text-left">
                  {props.children}
                </div>
              </div>
              <div className="bg-gray-50 px-4 py-3 sm:px-6 sm:flex sm:flex-row-reverse">
                <button
                  onClick={() => props.onClose()}
                  type="button"
                  className="mt-3 w-full inline-flex justify-center rounded-md border border-gray-300 shadow-sm px-4 py-2 bg-white text-base font-medium text-gray-700 hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 sm:mt-0 sm:ml-3 sm:w-auto sm:text-sm"
                >
                  Close
                </button>
              </div>
            </div>
          </div>
        </div>
      </>,
      modalContainer
    )
  );
}

export default AwardClaimsTable;
