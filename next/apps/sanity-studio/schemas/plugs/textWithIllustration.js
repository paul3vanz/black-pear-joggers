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
      name: 'label',
      description: 'Not displayed, used for reference',
    },
    {
      type: 'string',
      name: 'title',
      description: 'Visible title of the section (shown as a <h2>)',
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
  preview: {
    select: {
      label: 'label',
      title: 'title',
      disabled: 'disabled',
    },
    prepare({ label, title, disabled }) {
      return {
        title: `${disabled ? '🚫 ' : ''}${label || title}`,
      };
    },
  },
};
