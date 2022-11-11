import { classNames } from '@black-pear-joggers/helpers';
import { PropsWithChildren } from 'react';

export const Cards = (props: PropsWithChildren<{ maxColumns?: number }>) => (
  <div
    className={classNames(
      'grid md:grid-cols-2 gap-4',
      props.maxColumns === 3 && `xl:grid-cols-3`,
      props.maxColumns === 4 && `xl:grid-cols-4`
    )}
  >
    {props.children}
  </div>
);
