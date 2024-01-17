// eslint-disable-next-line @typescript-eslint/no-var-requires
const { withNx } = require('@nrwl/next/plugins/with-nx');
const { withSentryConfig } = require('@sentry/nextjs');

/**
 * @type {import('@nrwl/next/plugins/with-nx').WithNxOptions}
 **/
const nextConfig = {
  basePath: '/admin',
  nx: {
    svgr: false,
  },
  images: {
    domains: ['bpj.org.uk'],
  },
  sentry: {
    hideSourceMaps: true,
  },
};

module.exports = withSentryConfig(withNx(nextConfig));