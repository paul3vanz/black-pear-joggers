// First, we must import the schema creator
import createSchema from 'part:@sanity/base/schema-creator';

// Then import schema types from any plugins that might expose them
import schemaTypes from 'all:part:@sanity/base/schema-type';
import localeString from './objects/localeString';

// Kitchen sink document schemas
import navMenu from './documents/navMenu';
import author from './documents/author';
import category from './documents/category';
import post from './documents/post';
import page from './documents/page';
import siteSettings from './documents/siteSettings';
import route from './documents/route';

import experiment from './objects/experiment';
import simpleBlockContent from './objects/simpleBlockContent';

import * as plugs from './plugs';
import plugDefaultFields from './plugs/_plugDefaultFields';

// Kitchen sink object types
import { videoEmbed } from './objects/embeds';
import cta from './objects/cta';
import bodyPortableText from './objects/bodyPortableText';
import excerptPortableText from './objects/excerptPortableText';
import feature from './objects/feature';
import mainImage from './objects/mainImage';
import authorReference from './objects/authorReference';
import link from './objects/link';
import variation from './objects/variation';
import openGraph from './objects/openGraph';

// We import object and document schemas
import blockContent from './blockContent';

// Kit schemas
import vendor from './vendor';
import product from './product';
import productVariant from './productVariant';

// Vacancy schemas
import vacancy from './vacancy';

import localeText from './locale/Text';
import localeBlockContent from './locale/BlockContent';

const allPlugs = Object.values(plugs).map((plug) => {
  return { ...plug, fields: plugDefaultFields.concat(plug.fields) };
});

// Then we give our schema to the builder and provide the result to Sanity
export default createSchema({
  // We name our schema
  name: 'default',
  // Then proceed to concatenate our document type
  // to the ones provided by any plugins that are installed
  types: schemaTypes
    .concat([
      // The following are document types which will appear
      // in the studio.

      vendor,
      category,
      product,
      productVariant,

      vacancy,

      // When added to this list, object types can be used as
      // { type: 'typename' } in other document schemas
      blockContent,
      localeText,
      localeBlockContent,

      // Kitchen sink
      localeString,
      variation,
      openGraph,
      experiment,
      route,
      link,
      simpleBlockContent,
      cta,
      siteSettings,
      post,
      navMenu,
      page,
      //   category,
      author,
      mainImage,
      authorReference,
      //   instagram,
      videoEmbed,
      bodyPortableText,
      excerptPortableText,
      feature,
    ])
    .concat(allPlugs),
});
