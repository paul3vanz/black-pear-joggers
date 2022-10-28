import { PropsWithChildren } from 'react';

export const Cards = ({
  children,
}: PropsWithChildren<Record<string, unknown>>) => (
  <div className="grid md:grid-cols-2 xl:grid-cols-3 gap-4">{children}</div>
);
