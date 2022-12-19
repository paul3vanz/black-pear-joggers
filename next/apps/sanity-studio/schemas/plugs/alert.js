export default {
  title: 'Alert',
  name: 'alert',
  type: 'object',
  fields: [
    {
      type: 'string',
      name: 'label',
      description: 'Not displayed, used for reference',
    },
    {
      type: 'string',
      name: 'title',
      description: 'Visible title of the alert (shown as a <h2>)',
    },
    {
      title: 'Content',
      name: 'content',
      type: 'bodyPortableText',
    },
    {
      title: 'Type',
      name: 'type',
      type: 'string',
      options: {
        list: [
          { title: 'Success', value: 'success' },
          { title: 'Info', value: 'info' },
          { title: 'Warning', value: 'warning' },
          { title: 'Error', value: 'error' },
        ],
      },
    },
  ],
  preview: {
    select: {
      title: 'title',
      label: 'label',
      type: 'type',
    },
    prepare({ title, label, type }) {
      return {
        title: `Alert: ${type || 'Title not set'}`,
        subtitle: label || title,
      };
    },
  },
};
