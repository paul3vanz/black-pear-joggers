export default {
  name: 'vacancy',
  title: 'Vacancy',
  type: 'document',
  fields: [
    {
      name: 'title',
      title: 'Title',
      type: 'string',
    },
    {
      name: 'slug',
      title: 'Slug',
      type: 'slug',
      options: {
        source: 'title',
        maxLength: 96,
      },
    },
    {
      name: 'image',
      title: 'Image',
      type: 'image',
    },
    {
      name: 'summary',
      title: 'Summary',
      type: 'blockContent',
    },
    {
      name: 'responsibilities',
      title: 'Responsibilities',
      type: 'blockContent',
    },
    {
      name: 'howToApply',
      title: 'How to apply',
      type: 'blockContent',
    },
    {
      name: 'status',
      title: 'Status',
      type: 'string',
      options: {
        list: [
          { title: 'Recruiting', value: 'recruiting' },
          { title: 'Filled', value: 'filled' },
          { title: 'Hidden', value: 'hidden' },
        ],
      },
    },
    {
      name: 'newRecruit',
      title: 'New recruit',
      type: 'string',
    },
  ],
  preview: {
    select: {
      title: 'title',
      media: 'logo',
    },
  },
};
