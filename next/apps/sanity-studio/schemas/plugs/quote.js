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
  ],
  preview: {
    select: {
      content: 'content',
    },
    prepare({ content }) {
      return {
        title: 'Quote',
      };
    },
  },
};
