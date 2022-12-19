export default {
  type: 'object',
  name: 'illustration',
  title: 'Illustration',
  fields: [
    {
      title: 'Image',
      name: 'image',
      type: 'mainImage',
    },
    {
      type: 'array',
      name: 'images',
      of: [{ type: 'mainImage' }],
    },
  ],
  preview: {
    select: {
      image: 'image',
      images: 'images',
    },
    prepare({ image, images }) {
      const imageArray = images ? images : [image];
      let subtitle = imageArray
        .map(
          (image) => image.caption || image.alt || 'Missing capton or alt text'
        )
        .join(', ');
      let media = imageArray[0];

      if (!imageArray.length) {
        console.log('no image');
        return { title: 'Illustration with no image' };
      }
      return {
        title: `Illustration: ${imageArray.length} images`,
        subtitle,
        media,
      };
    },
  },
};
