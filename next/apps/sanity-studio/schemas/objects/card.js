export default {
  type: 'object',
  name: 'card',
  title: 'Card',
  fields: [
    {
      title: 'Title',
      name: 'title',
      type: 'string',
    },
    {
      title: 'Content',
      name: 'content',
      type: 'simpleBlockContent',
    },
    {
      title: 'Link',
      name: 'link',
      type: 'string',
    },
    {
      title: 'Image',
      name: 'image',
      type: 'mainImage',
    },
  ],
};
