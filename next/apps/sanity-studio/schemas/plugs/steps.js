import React from 'react';
import BlockContent from '@sanity/block-content-to-react';

const Preview = ({ value: { blocks } }) => <BlockContent blocks={blocks} />;

export default {
  type: 'object',
  name: 'steps',
  title: 'Steps',
  preview: {
    select: {
      blocks: 'subtitle',
    },
    component: Preview,
  },
  fields: [
    {
      title: 'Title',
      name: 'title',
      type: 'string',
    },
    {
      title: 'Subtitle',
      name: 'subtitle',
      type: 'simpleBlockContent',
    },
    {
      title: 'Steps',
      name: 'steps',
      type: 'array',
      of: [
        {
          name: 'item',
          type: 'object',
          fields: [
            {
              name: 'title',
              type: 'string',
            },
            {
              name: 'content',
              type: 'blockContent',
            },
          ],
        },
      ],
    },
  ],
  preview: {
    select: {
      title: 'title',
    },
  },
};
