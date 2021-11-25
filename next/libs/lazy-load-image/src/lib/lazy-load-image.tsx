import { PropsWithChildren, useState } from 'react';

import LazyLoad from 'react-lazy-load';

export const LazyLoadImage = (
  props: PropsWithChildren<{ rounded?: boolean; className?: string }>
) => {
  const [loading, setLoading] = useState(true);

  return (
    <div
      className={[
        'bg-gray-100',
        props.className,
        props.rounded && 'rounded-sm',
        loading && 'animate-pulse',
      ].join(' ')}
    >
      <LazyLoad offset={100} onContentVisible={() => setLoading(false)}>
        {props.children}
      </LazyLoad>
    </div>
  );
};
