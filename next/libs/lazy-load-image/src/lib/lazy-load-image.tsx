import LazyLoad from 'react-lazy-load';
import { classNames } from '@black-pear-joggers/helpers';
import { faCircleNotch } from '@fortawesome/free-solid-svg-icons';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import { PropsWithChildren, useState } from 'react';

export const LazyLoadImage = (
  props: PropsWithChildren<{ rounded?: boolean; className?: string }>
) => {
  const [loading, setLoading] = useState(true);

  return (
    <div
      className={classNames(
        props.className,
        props.rounded && 'rounded-sm',
        loading && 'bg-gray-100 animate-pulse flex items-center justify-center'
      )}
    >
      {loading ? (
        <FontAwesomeIcon
          className="animate-spin text-primary-400 my-4 w-8 h-8"
          size="2x"
          icon={faCircleNotch}
        ></FontAwesomeIcon>
      ) : null}

      <LazyLoad offset={100} onContentVisible={() => setLoading(true)}>
        <span></span>
      </LazyLoad>
    </div>
  );
};
