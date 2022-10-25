import LazyLoad from 'react-lazy-load';
import { classNames } from '@black-pear-joggers/helpers';
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
        loading && 'bg-gray-100 animate-pulse'
      )}
    >
      <LazyLoad offset={100} onContentVisible={() => setLoading(false)}>
        {props.children}
      </LazyLoad>
    </div>
  );
};
