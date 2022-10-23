export default {
  type: 'object',
  name: 'textWithIllustration',
  initialValue: {
    cropToFit: true,
    width: 'normal',
  },
  fields: [
    {
      type: 'string',
      name: 'title',
    },
    {
      type: 'simpleBlockContent',
      name: 'text',
    },
    {
      type: 'illustration',
      name: 'illustration',
    },
    {
      title: 'Width',
      name: 'width',
      type: 'string',
      options: {
        list: [
          { title: 'Narrow', value: 'narrow' },
          { title: 'Wide', value: 'wide' },
        ],
      },
    },
    {
      type: 'boolean',
      name: 'cropToFit',
    },
    {
      name: 'backgroundColour',
      type: 'string',
      options: {
        list: [
          { title: 'Dark', value: 'dark' },
          { title: 'Light', value: 'light' },
          { title: 'Bright', value: 'bright' },
        ],
      },
    },
  ],
};
