export default {
  name: 'table',
  type: 'object',
  title: 'Table',
  fields: [
    {
      name: 'caption',
      type: 'string',
      title: 'Caption',
      description: 'Optional heading shown above the table',
    },
    {
      name: 'columns',
      type: 'array',
      title: 'Column headers',
      of: [{ type: 'string' }],
      options: { layout: 'tags' },
    },
    {
      name: 'rows',
      type: 'array',
      title: 'Rows',
      of: [
        {
          type: 'object',
          name: 'tableRow',
          title: 'Row',
          fields: [
            {
              name: 'cells',
              type: 'array',
              title: 'Cells',
              of: [{ type: 'string' }],
              options: { layout: 'tags' },
            },
          ],
          preview: {
            select: { cells: 'cells' },
            prepare({ cells }) {
              return { title: (cells || []).join(' | ') || 'Empty row' };
            },
          },
        },
      ],
    },
    {
      name: 'backgroundColour',
      type: 'string',
      options: {
        list: [
          { title: 'White', value: 'white' },
          { title: 'Light', value: 'light' },
          { title: 'Dark', value: 'dark' },
        ],
      },
    },
  ],
  preview: {
    select: { caption: 'caption', rows: 'rows' },
    prepare({ caption, rows }) {
      return {
        title: caption ? `Table: ${caption}` : 'Table',
        subtitle: `${(rows || []).length} rows`,
      };
    },
  },
};
