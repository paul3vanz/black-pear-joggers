export default {
  name: 'cards',
  type: 'object',
  title: 'Cards',
  fieldsets: [
    {
      name: 'settings',
      title: 'Settings',
      options: {
        collapsible: true,
        collapsed: true,
      },
    },
    {
      name: 'listSettings',
      title: 'List settings',
      options: {
        collapsible: true,
        collapsed: true,
      },
    },
  ],
  fields: [
    {
      name: 'label',
      type: 'string',
      fieldset: 'settings',
    },
    {
      name: 'title',
      type: 'string',
      fieldset: 'settings',
    },
    {
      name: 'subtitle',
      type: 'simpleBlockContent',
      fieldset: 'settings',
    },
    {
      title: 'Max columns',
      description: 'Max columns to display. Will shrink on smaller devices',
      name: 'maxColumns',
      type: 'number',
      fieldset: 'listSettings',
      min: 3,
      max: 4,
    },
    {
      name: 'backgroundColour',
      type: 'string',
      fieldset: 'listSettings',
      options: {
        list: [
          { title: 'Dark', value: 'dark' },
          { title: 'Light', value: 'light' },
          { title: 'Bright', value: 'bright' },
        ],
      },
    },
    {
      name: 'cards',
      type: 'array',
      of: [
        {
          name: 'card',
          type: 'card',
        },
      ],
    },
  ],
  preview: {
    select: {
      label: 'label',
      title: 'title',
      cards: 'cards',
    },
    prepare({ label, title, cards }) {
      return {
        title: title || label ? `Cards: ${title || label}` : 'Untitled cards',
        subtitle: `cards: ${cards.map((f) => f.title).join(', ')}±`,
      };
    },
  },
};
