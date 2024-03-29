import S from '@sanity/desk-tool/structure-builder';
import { MdMenu } from 'react-icons/md';
import {
  GoBrowser as PageIcon,
  GoHome,
  GoPerson,
  GoSettings,
} from 'react-icons/go';
import blog from './src/structure/blog';
import landingPages from './src/structure/landingPages';
import PreviewIFrame from './src/components/previewIFrame';
// import ConfigPreview from './ConfigPreview';

// export default () =>
//   S.document()
//     .schemaType('config')
//     .documentId('globalConfig')
//     .views([S.view.form(), S.view.component(ConfigPreview)]);

const hiddenDocTypes = (listItem) =>
  ![
    'route',
    'navigationMenu',
    'post',
    'page',
    'siteSettings',
    'author',
    'category',
    'person',
  ].includes(listItem.getId());

export default () =>
  S.list()
    .title('Content')
    .items([
      S.documentListItem()
        .schemaType('siteSettings')
        .title('Site settings')
        .icon(GoSettings)
        .child(
          S.document()
            .schemaType('siteSettings')
            .documentId('siteSettings')
            .views([S.view.form(), PreviewIFrame()])
        ),
      S.documentListItem()
        .title('Frontpage')
        .schemaType('page')
        .icon(GoPerson)
        .child(
          S.document()
            .schemaType('page')
            .documentId('frontpage')
            .views([S.view.form(), PreviewIFrame()])
        ),
      blog,
      landingPages,
      S.documentTypeListItem('person').title('All people').icon(GoPerson),
      // This returns an array of all the document types
      // defined in schema.js. We filter out those that we have
      // defined the structure above
      ...S.documentTypeListItems().filter(hiddenDocTypes),
    ]);
