import { createPortal } from 'react-dom';
import { faTimes } from '@fortawesome/free-solid-svg-icons';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import { hasWindow } from '@black-pear-joggers/helpers';

export function DescriptionModal(props: {
  isOpen: boolean;
  onClose: () => void;
  children: JSX.Element;
}) {
  const modalContainer =
    hasWindow() && document.getElementById('modalContainer');

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
                  className="absolute right-0 top-0 mt-2 mr-3"
                />
                <div className="mt-3 text-center sm:mt-0 sm:text-left">
                  {props.children}
                </div>
              </div>
            </div>
          </div>
        </div>
      </>,
      modalContainer
    )
  );
}
