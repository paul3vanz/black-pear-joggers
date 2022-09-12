import Document, {
    Head,
    Html,
    Main,
    NextScript
    } from 'next/document';
import { ReactElement } from 'react';
import { ServerStyleSheet } from 'styled-components';
/* eslint-disable react/display-name */

export default class CustomDocument extends Document<{
  styleTags: ReactElement[];
}> {
  static getInitialProps({ renderPage }) {
    const sheet = new ServerStyleSheet();

    const page = renderPage(
      (App) => (props) => sheet.collectStyles(<App {...props} />)
    );

    const styleTags = sheet.getStyleElement();

    return { ...page, styleTags };
  }

  render() {
    return (
      <Html>
        <Head>
          {this.props.styleTags}

          <link
            rel="preconnect"
            href="https://fonts.gstatic.com"
            crossOrigin="anonymous"
          />

          <link
            rel="stylesheet"
            href="https://fonts.googleapis.com/css2?family=Catamaran:wght@400;600;800&amp;display=swap"
          />

          <script
            async
            src="https://kit.fontawesome.com/97736414dd.js"
            crossOrigin="anonymous"
          ></script>
        </Head>
        <body>
          <Main />
          <NextScript />
        </body>
      </Html>
    );
  }
}
