import { createPortal } from 'react-dom';
import { faTimes } from '@fortawesome/free-solid-svg-icons';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import { hasWindow } from '@black-pear-joggers/helpers';
import { friendlyDate, timeFormatted } from '@black-pear-joggers/helpers';
import { MagicMileResult } from '@black-pear-joggers/core-services';
import { toTitleCase } from '../../helpers/formatters';

interface MagicMileDetailsModalProps {
  isOpen: boolean;
  onClose: () => void;
  result: MagicMileResult | null;
}

export function MagicMileDetailsModal(props: MagicMileDetailsModalProps) {
  const modalContainer =
    hasWindow() && document.getElementById('modalContainer');

  if (!props.result || !modalContainer) {
    return null;
  }

  function formatLocation(location: string): string {
    const search = location.match(/\(.*?(?=\))/);
    return search ? search[0].replace('(', '') : location;
  }

  return props.isOpen
    ? createPortal(
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
                onClick={() => props.onClose()}
              ></div>
              <span
                className="hidden sm:inline-block sm:align-middle sm:h-screen"
                aria-hidden="true"
              >
                &#8203;
              </span>
              <div className="inline-block align-bottom bg-white rounded-lg text-left overflow-hidden shadow-xl transform transition-all sm:my-8 sm:align-middle sm:max-w-lg sm:w-full">
                <div className="bg-white px-4 pt-5 pb-4 sm:p-6 sm:pb-4">
                  <FontAwesomeIcon
                    icon={faTimes}
                    onClick={() => props.onClose()}
                    title="Close"
                    size="2x"
                    className="absolute right-0 top-0 mt-2 mr-3 cursor-pointer hover:text-gray-600"
                  />
                  <div className="mt-3 text-center sm:mt-0 sm:text-left">
                    <h3
                      className="text-lg leading-6 font-medium text-gray-900 mb-4"
                      id="modal-title"
                    >
                      Magic Mile Result Details
                    </h3>
                    <div className="space-y-3">
                      <div className="grid grid-cols-2 gap-4">
                        <div>
                          <span className="font-semibold text-gray-700">
                            Name:
                          </span>
                          <p className="text-gray-900">
                            {props.result.firstName} {props.result.lastName}
                          </p>
                        </div>
                        <div>
                          <span className="font-semibold text-gray-700">
                            Date:
                          </span>
                          <p className="text-gray-900">
                            {friendlyDate(props.result.date)}
                          </p>
                        </div>
                      </div>

                      <div className="grid grid-cols-2 gap-4">
                        <div>
                          <span className="font-semibold text-gray-700">
                            Gender:
                          </span>
                          <p className="text-gray-900">
                            {toTitleCase(props.result.gender)}
                          </p>
                        </div>
                        <div>
                          <span className="font-semibold text-gray-700">
                            Category:
                          </span>
                          <p className="text-gray-900">
                            {props.result.category}
                          </p>
                        </div>
                      </div>

                      <div className="grid grid-cols-2 gap-4">
                        <div>
                          <span className="font-semibold text-gray-700">
                            Predicted Time:
                          </span>
                          <p className="text-gray-900">
                            {timeFormatted(props.result.predictedTime)}
                          </p>
                        </div>
                        <div>
                          <span className="font-semibold text-gray-700">
                            Actual Time:
                          </span>
                          <p className="text-gray-900 font-bold">
                            {timeFormatted(props.result.actualTime)}
                          </p>
                        </div>
                      </div>

                      <div>
                        <span className="font-semibold text-gray-700">
                          Location:
                        </span>
                        <p className="text-gray-900">
                          {formatLocation(props.result.location)}
                        </p>
                      </div>

                      <div>
                        <span className="font-semibold text-gray-700">
                          Difference:
                        </span>
                        <p
                          className={`font-semibold ${
                            props.result.actualTime < props.result.predictedTime
                              ? 'text-green-600'
                              : props.result.actualTime >
                                props.result.predictedTime
                              ? 'text-red-600'
                              : 'text-gray-900'
                          }`}
                        >
                          {props.result.actualTime < props.result.predictedTime
                            ? `-${timeFormatted(
                                props.result.predictedTime -
                                  props.result.actualTime
                              )}`
                            : props.result.actualTime >
                              props.result.predictedTime
                            ? `+${timeFormatted(
                                props.result.actualTime -
                                  props.result.predictedTime
                              )}`
                            : 'Exact match!'}
                        </p>
                      </div>

                      {props.result.athleteId && (
                        <div>
                          <span className="font-semibold text-gray-700">
                            Athlete ID:
                          </span>
                          <p className="text-gray-900">
                            {props.result.athleteId}
                          </p>
                        </div>
                      )}
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </>,
        modalContainer
      )
    : null;
}

export default MagicMileDetailsModal;
