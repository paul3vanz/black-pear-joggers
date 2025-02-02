export default {
  type: 'object',
  name: 'ctaPlug',
  title: 'Call to action',
  fields: [
    {
      name: 'label',
      type: 'string',
    },
    {
      name: 'title',
      type: 'string',
      title: 'Title',
    },
    {
      name: 'body',
      type: 'simpleBlockContent',
      title: 'Body',
    },
    {
      name: 'ctas',
      type: 'array',
      of: [
        {
          name: 'cta',
          type: 'cta',
        },
      ],
    },
    {
      name: 'backgroundColour',
      type: 'string',
      options: {
        list: [
          { title: 'White', value: 'white' },
          { title: 'Dark', value: 'dark' },
          { title: 'Light', value: 'light' },
          { title: 'Bright', value: 'bright' },
        ],
      },
    },
  ],
  preview: {
    select: {
      title: 'title',
      subtitle: 'label',
    },
    prepare({ title, subtitle }) {
      return {
        title: `Call to action: ${title || 'Title not set'}`,
        subtitle,
      };
    },
  },
};
