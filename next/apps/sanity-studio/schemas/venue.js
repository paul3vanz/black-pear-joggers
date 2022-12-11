export default {
  name: 'venue',
  title: 'Venue',
  type: 'document',
  fields: [
    {
      name: 'title',
      title: 'Title',
      type: 'string',
    },
    {
      name: 'image',
      title: 'Image',
      type: 'mainImage',
    },
    {
      name: 'address',
      title: 'Address',
      type: 'text',
    },
    {
      name: 'mapUrl',
      title: 'Map URL',
      type: 'string',
    },
    // {
    //   name: 'gettingThere',
    //   title: 'Getting there',
    //   type: 'simpleBlockContent',
    // },
    {
      name: 'facilities',
      title: 'Facilities',
      type: 'simpleBlockContent',
    },
  ],
  preview: {
    select: {
      title: 'title',
      media: 'logo',
    },
  },
};
