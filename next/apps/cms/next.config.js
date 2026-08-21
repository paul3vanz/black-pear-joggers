//@ts-check

// eslint-disable-next-line @typescript-eslint/no-var-requires
const { composePlugins, withNx } = require('@nx/next');
// eslint-disable-next-line @typescript-eslint/no-var-requires
const path = require('path');

/**
 * @type {import('@nx/next/plugins/with-nx').WithNxOptions}
 **/
const nextConfig = {
  basePath: '',
  // Pin file tracing to the next/ workspace.
  //
  // cms is the only app that deploys as a real server, and Netlify bundles it
  // into a lambda with a hard 250 MB limit. Left to itself Next 15 walks up
  // from apps/cms looking for a lockfile and does not stop at next/, it
  // carries on to the repo root, because the Angular workspace has a
  // package-lock.json there too. Tracing from that far out drags in far more
  // than the app needs (next/node_modules alone is 1.3 GB) and the deploy is
  // rejected with "The function exceeds the maximum size of 250 MB".
  //
  // Next 14 did not do this, which is why this only appeared on the upgrade.
  outputFileTracingRoot: path.join(__dirname, '../..'),
  nx: {
    // Set this to true if you would like to use SVGR
    // See: https://github.com/gregberge/svgr
    svgr: false,
  },
  async redirects() {
    return [
      {
        source: '/',
        destination: '/home',
        permanent: false,
      },
    ];
  },
};

const plugins = [
  // Add more Next.js plugins to this list if needed.
  withNx,
];

module.exports = composePlugins(...plugins)(nextConfig);
