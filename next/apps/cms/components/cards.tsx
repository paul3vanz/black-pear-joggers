import { PropsWithChildren } from 'react';

export const Cards = ({ children }: PropsWithChildren<{}>) => (
  <div className="grid md:grid-cols-2 xl:grid-cols-4 gap-4">{children}</div>
);
