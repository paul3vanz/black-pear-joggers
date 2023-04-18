export default {
  type: 'object',
  name: 'infoRows',
  title: 'Info rows',
  fields: [
    {
      type: 'string',
      name: 'title',
    },
    {
      type: 'array',
      name: 'rows',
      of: [{ type: 'textWithIllustration' }],
    },
  ],
  preview: {
    select: {
      title: 'title',
      rows: 'rows',
      disabled: 'disabled',
    },
    prepare({ title, rows, disabled }) {
      return {
        title: `${disabled ? '🚫 ' : ''}${
          title ? `Info rows: ${title}` : 'Info rows'
        }`,
        subtitle: `${rows.length} row${rows.length > 1 ? 's' : ''}: ${rows
          .map((row) => row.label || row.title || 'No label or title')
          .join(', ')}`,
      };
    },
  },
};
