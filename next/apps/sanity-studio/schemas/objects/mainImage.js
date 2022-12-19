export default {
  name: 'mainImage',
  type: 'image',
  title: 'Image',
  options: {
    hotspot: true,
  },
  fields: [
    {
      name: 'externalUrl',
      type: 'string',
      title: 'External URL',
      description: 'Allow the use of external image URLs',
      options: {
        isHighlighted: true,
      },
    },
    {
      name: 'caption',
      type: 'string',
      title: 'Caption',
      options: {
        isHighlighted: true,
      },
    },
    {
      name: 'alt',
      type: 'string',
      title: 'Alternative text',
      description: 'Important for SEO and accessibility.',
      validation: (Rule) =>
        Rule.error('You have to fill out the alternative text.').required(),
      options: {
        isHighlighted: true,
      },
    },
  ],
  preview: {
    select: {
      imageUrl: 'asset.url',
      externalUrl: 'externalUrl',
      caption: 'caption',
      alt: 'alt',
    },
    prepare({ imageUrl, caption, alt }) {
      return {
        title: caption || alt,
        imageUrl: imageUrl || externalUrl,
      };
    },
  },
};
