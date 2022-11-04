import { classNames } from '@black-pear-joggers/helpers';
import { PropsWithChildren } from 'react';

export const Cards = (props: PropsWithChildren<{ maxColumns?: number }>) => (
  <div
    className={classNames(
      'grid md:grid-cols-2 gap-4',
      props.maxColumns && `xl:grid-cols-${props.maxColumns}`
    )}
  >
    {props.children}
  </div>
);
