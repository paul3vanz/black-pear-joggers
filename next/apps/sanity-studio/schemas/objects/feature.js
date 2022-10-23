export default {
  type: 'object',
  name: 'feature',
  title: 'Feature',
  fields: [
    {
      title: 'Title',
      name: 'title',
      type: 'string',
    },
    {
      title: 'Subtitle',
      name: 'subtitle',
      type: 'simpleBlockContent',
    },
    {
      title: 'Icon',
      name: 'icon',
      type: 'string',
    },
  ],
};
