export default {
  name: 'quote',
  type: 'object',
  title: 'Quote',
  fields: [
    {
      name: 'content',
      type: 'blockContent',
    },
    {
      name: 'name',
      type: 'string',
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
      content: 'name',
    },
    prepare({ content }) {
      return {
        title: `Quote - ${content}`,
      };
    },
  },
};
