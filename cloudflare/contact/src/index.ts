import { handleOptions, handleRequest } from './handler';

addEventListener('fetch', (event: FetchEvent) => {
    const request = event.request;
    const url = new URL(request.url);

    if (request.method === 'OPTIONS') {
        event.respondWith(handleOptions(request));
    } else if (request.method === 'GET' || request.method === 'HEAD' || request.method === 'POST') {
        event.respondWith(handleRequest(request));
    } else {
        event.respondWith(
            new Response(null, {
                status: 405,
                statusText: 'Method Not Allowed',
            })
        );
    }
});
