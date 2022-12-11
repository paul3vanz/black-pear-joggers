export default {
  type: 'document',
  name: 'page',
  title: 'Page',
  fields: [
    {
      name: 'title',
      type: 'string',
      title: 'Title',
    },
    {
      name: 'navMenu',
      type: 'reference',
      title: 'Navigation menu',
      to: [{ type: 'navigationMenu' }],
      description: 'Which nav menu should be shown, if any',
    },
    {
      name: 'content',
      type: 'array',
      title: 'Page sections',
      description: 'Add, edit, and reorder sections',
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
};
