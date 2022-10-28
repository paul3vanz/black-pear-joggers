import { PortableTextComponents } from '@portabletext/react';

export const portableTextComponents: PortableTextComponents = {
  list: {
    // eslint-disable-next-line react/display-name
    bullet: ({ children }) => (
      <ul className="list-disc pl-5 mb-4">{children}</ul>
    ),
  },
  listItem: {
    // eslint-disable-next-line react/display-name
    bullet: ({ children }) => <li className="mb-2">{children}</li>,
  },
};

export function portableTextBlocksToText(blocks, opts = {}) {
  const defaults = { nonTextBehavior: 'remove' };

  const options = { ...defaults, ...opts };

  return blocks
    .map((block) => {
      if (block._type !== 'block' || !block.children) {
        return options.nonTextBehavior === 'remove'
          ? ''
          : `[${block._type} block]`;
      }

      return block.children.map((child) => child.text).join('');
    })
    .join('\n\n');
}
