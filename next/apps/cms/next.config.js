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
  // Keep the build toolchain out of the lambda.
  //
  // next.config.js requires @nx/next, so Next traces the config's own
  // dependencies into the standalone output and the whole Nx build chain goes
  // with it. None of it runs at request time, and it is most of the weight:
  // @swc 51 MB, @rspack 46 MB, typescript 8.7 MB, webpack 6.1 MB, sass 6.9 MB.
  //
  // Every pattern is scoped to node_modules on purpose. A bare '**/typescript/**'
  // also matches next/dist/lib/typescript, which Next requires on startup, and
  // the server then dies with MODULE_NOT_FOUND before serving anything.
  //
  // Measured locally: standalone goes from 189 MB to 60 MB, and every route
  // still returns 200 when the trimmed bundle is booted with node server.js.
  outputFileTracingExcludes: {
    '*': [
      '**/node_modules/@swc/**',
      '**/node_modules/@rspack/**',
      '**/node_modules/typescript/**',
      '**/node_modules/webpack/**',
      '**/node_modules/terser/**',
      '**/node_modules/sass/**',
      '**/node_modules/sass-embedded/**',
      '**/node_modules/sass-embedded-*/**',
      '**/node_modules/@bufbuild/**',
      '**/node_modules/csso/**',
      '**/node_modules/css-tree/**',
      '**/node_modules/svgo/**',
      '**/node_modules/@webassemblyjs/**',
      '**/node_modules/uglify-js/**',
      '**/node_modules/esbuild/**',
      '**/node_modules/@esbuild/**',
    ],
  },
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
