export default {
  name: 'clubRun',
  title: 'Club run',
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
      name: 'summary',
      title: 'Summary',
      type: 'blockContent',
    },
    {
      name: 'day',
      title: 'Day',
      type: 'string',
      options: {
        list: [
          'Monday',
          'Tuesday',
          'Wednesday',
          'Thursday',
          'Friday',
          'Saturday',
          'Sunday',
        ],
      },
    },
    {
      name: 'time',
      title: 'Time',
      type: 'string',
    },
    {
      name: 'venue',
      title: 'Venue',
      type: 'reference',
      to: [{ type: 'venue' }],
    },
    {
      name: 'image',
      title: 'Image',
      type: 'mainImage',
    },
    {
      type: 'array',
      name: 'content',
      of: [{ type: 'textWithIllustration' }],
    },
  ],
  preview: {
    select: {
      title: 'title',
      media: 'logo',
    },
  },
};
