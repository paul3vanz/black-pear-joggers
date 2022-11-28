const baseUrl = 'https://bpj.org.uk';
const cloudflarePages = 'https://black-pear-joggers.pages.dev';
const netlifyCms = 'https://black-pear-joggers-cms.netlify.app';
const netlifyAngularApps = 'https://apps.bpj.org.uk';

const mappings = [
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

const blockedRegions = ['CN', 'KP', 'SY', 'PK', 'CU'];
const blockedIpAddresses = ['0.0.0.0', '10.0.0.0'];

addEventListener('fetch', (event) => {
    event.respondWith(fetchAndApply(event.request));
})

async function fetchAndApply(request) {
    const region = request.headers.get('cf-ipcountry');
    const IpAddress = request.headers.get('cf-connecting-ip');

    let response = null;
    let url = request.url;

    mappings.forEach((map) => {
        if (url.includes(map.request)) {
            url = url.replace(`${baseUrl}/${map.request}`, map.replace);
        }
    });

    if (request.url === url) {
        url = url.replace(baseUrl, netlifyCms);
    }

    if ([`${baseUrl}`, `${baseUrl}/`].includes(request.url)) {
        url = `${netlifyCms}/home`;
    }

    if (region && blockedRegions.includes(region.toUpperCase())) {
        response = new Response('Access denied: This page is not available in your region.', {
            status: 403
        });
    } else if (blockedIpAddresses.includes(IpAddress)) {
        response = new Response('Access denied: Your IP address is blocked.', {
            status: 403
        });
    } else {
        let method = request.method;
        let headers = request.headers;
        response = fetch(url, {
            method: method,
            headers: {
                ...headers,
                "x-bpj-url-requested": request.url,
                "x-bpj-url-fetched": url,
            }
        })
    }
    return response;
}