import { PortableTextComponents } from '@portabletext/react';

export const portableTextComponents: PortableTextComponents = {
  list: {
    // eslint-disable-next-line react/display-name
    bullet: ({ children }) => <ul className="list-disc pl-5">{children}</ul>,
  },
  listItem: {
    // eslint-disable-next-line react/display-name
    bullet: ({ children }) => <li className="mb-2">{children}</li>,
  },
};
