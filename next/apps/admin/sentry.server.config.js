import * as Sentry from '@sentry/nextjs';

Sentry.init({
  dsn: 'https://fbb9724e859fdd2ce495b44dfe8a27f1@o4504440090132480.ingest.sentry.io/4506588902588416',
  tracesSampleRate: 1.0,
});
