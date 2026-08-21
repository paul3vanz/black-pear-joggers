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
  // package-lock.json there too. Next 14 did not do this.
  outputFileTracingRoot: path.join(__dirname, '../..'),
  // Keep the build toolchain out of the lambda.
  //
  // next.config.js requires @nx/next, so Next traces the config's own
  // dependencies into the standalone output and the whole Nx build chain goes
  // with it. None of it runs at request time, and without this the bundle is
  // 189 MB and Netlify rejects the deploy outright.
  //
  // Be precise about what goes. @swc/core* is the 51 MB compiler binary and is
  // build-only, but @swc/helpers is 920 KB and next/dist/shared/lib/constants.js
  // requires it on startup, so excluding the whole @swc scope gets the lambda
  // under the size limit and then kills it on every request with
  // "Cannot find module '@swc/helpers/_/_interop_require_default'".
  //
  // Likewise scope every pattern to node_modules: a bare '**/typescript/**'
  // also matches next/dist/lib/typescript, which Next needs to boot.
  outputFileTracingExcludes: {
    '*': [
      '**/node_modules/@swc/core*/**',
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
