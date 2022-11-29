export const baseUrl = 'https://bpj.org.uk';
export const cloudflarePages = 'https://black-pear-joggers.pages.dev';
export const netlifyCms = 'https://black-pear-joggers-cms.netlify.app';
export const netlifyAngularApps = 'https://apps.bpj.org.uk';

export const mappings = [
  { request: 'club-standards', replace: netlifyAngularApps },
  { request: 'race-results', replace: netlifyAngularApps },
  { request: 'magic-mile', replace: netlifyAngularApps },
  { request: 'club-records', replace: netlifyAngularApps },

  { request: 'admin', replace: `${cloudflarePages}/admin` },
  { request: 'contact-the-club', replace: `${cloudflarePages}/contact` },
  { request: 'contact', replace: `${cloudflarePages}/contact` },
  { request: 'kit', replace: `${cloudflarePages}/kit` },
  { request: 'vacancies', replace: `${cloudflarePages}/vacancies` },
  { request: 'claim-award', replace: `${cloudflarePages}/claim-award` },
  { request: 'register', replace: `${cloudflarePages}/register` },

  { request: 'our-races/croome-race', replace: `${netlifyCms}/our-races/croome-capability-canter` },
  { request: 'our-races/wild-race', replace: `${netlifyCms}/our-races/the-wild-one` },
];

export const blockedRegions = ['CN', 'KP', 'SY', 'PK', 'CU'];
export const blockedIpAddresses = ['0.0.0.0', '10.0.0.0'];
