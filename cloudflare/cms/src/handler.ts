import { baseUrl, blockedIpAddresses, blockedRegions, mappings, netlifyCms } from './config';

export async function handleRequest(request: Request) {
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
      status: 403,
    });
  } else if (blockedIpAddresses.includes(IpAddress)) {
    response = new Response('Access denied: Your IP address is blocked.', {
      status: 403,
    });
  } else {
    let method = request.method;
    let headers = request.headers;
    response = fetch(url, {
      method: method,
      headers: {
        ...headers,
        'x-bpj-url-requested': request.url,
        'x-bpj-url-fetched': url,
      },
    });
  }
  return response;
}
