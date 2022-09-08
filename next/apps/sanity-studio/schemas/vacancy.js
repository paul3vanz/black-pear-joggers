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
  ],
  preview: {
    select: {
      title: 'title',
      media: 'logo',
    },
  },
};
