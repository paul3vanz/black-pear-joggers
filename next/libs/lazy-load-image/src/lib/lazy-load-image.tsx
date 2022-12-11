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
        'flex items-center justify-center',
        props.rounded && 'rounded-sm',
        loading && 'bg-gray-100 animate-pulse'
      )}
    >
      {loading ? (
        <FontAwesomeIcon
          className="animate-spin text-primary-400 my-4"
          size="2x"
          icon={faCircleNotch}
        ></FontAwesomeIcon>
      ) : null}

      <LazyLoad offset={100} onContentVisible={() => setLoading(false)}>
        {props.children}
      </LazyLoad>
    </div>
  );
};
