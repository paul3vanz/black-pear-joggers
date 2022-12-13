export default {
  name: 'clubRun',
  title: 'Club run',
  type: 'document',
  fields: [
    {
      type: 'boolean',
      name: 'disabled',
    },
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
      options: {
        list: generateTimes(),
      },
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
      of: [
        { type: 'cards' },
        { type: 'ctaColumns' },
        { type: 'ctaPlug' },
        { type: 'featureList' },
        { type: 'hero' },
        { type: 'illustration' },
        { type: 'infoRows' },
        { type: 'pricing' },
        { type: 'quote' },
        { type: 'steps' },
        { type: 'uiComponentRef' },
        { type: 'venue' },
      ],
    },
  ],
  preview: {
    select: {
      title: 'title',
      media: 'logo',
    },
  },
};

function generateTimes() {
  const interval = 5;
  let times = [];
  let currentHour = 0;

  for (let i = 0; currentHour < 24 * 60; i++) {
    const hour = Math.floor(currentHour / 60);
    const minutes = currentHour % 60;
    const hourFormatted = (hour % 12).toString().slice(-2);
    const minutesFormatted = minutes ? ('0' + minutes).slice(-2) : '';

    times[i] =
      (hourFormatted === '0' ? '12' : hourFormatted) +
      (minutes ? ':' : '') +
      minutesFormatted +
      ['am', 'pm'][Math.floor(hour / 12)];

    currentHour = currentHour + interval;
  }

  return times;
}
