import { faCircleNotch } from '@fortawesome/free-solid-svg-icons';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';

interface LoadingSpinnerProps {
  text?: string;
}

export function LoadingSpinner(props: LoadingSpinnerProps) {
  return (
    <div className="text-xl flex">
      <FontAwesomeIcon
        className="animate-spin text-primary-400 w-8 h-8"
        size="lg"
        icon={faCircleNotch}
      ></FontAwesomeIcon>
      <span className="pl-2">{props.text || 'Loading...'}</span>
    </div>
  );
}
