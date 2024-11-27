import { buildAwardClaimBody } from "./utils/build-award-claim-body";
import { buildContactFormBody } from "./utils/build-contact-form-body";

const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET,HEAD,POST,OPTIONS',
    'Access-Control-Max-Age': '86400',
};

export type RequestBody = {
    award: string;
    certificateId: string;
    email: string;
    firstName: string;
    message: string;
    name: string;
    reason: string;
}

export async function handleRequest(request: Request) {
    const url = new URL(request.url);
    const json = await request.json<RequestBody>();
    let body;

    if (json.reason) {
        body = buildContactFormBody(json.name, json.email, json.reason, json.message);
    }

    if (json.award) {
        body = buildAwardClaimBody(json.email, json.firstName, json.award, json.certificateId);
    }

    const send = await fetch('https://api.sendgrid.com/v3/mail/send', {
        method: 'POST',
        headers: {
            Authorization: `Bearer ${SENDGRID_API_KEY}`,
            'Content-Type': 'application/json',
        },
        body: JSON.stringify(body),
    });

    return new Response(JSON.stringify({ send: { ok: send.ok }, body: body }), {
        headers: {
            'Access-Control-Allow-Origin': '*',
            Vary: 'Origin',
        },
        status: send.status,
    });
}

export async function handleOptions(request) {
    let headers = request.headers;
    if (
        headers.get('Origin') !== null &&
        headers.get('Access-Control-Request-Method') !== null &&
        headers.get('Access-Control-Request-Headers') !== null
    ) {
        let respHeaders = {
            ...corsHeaders,
            'Access-Control-Allow-Headers': request.headers.get('Access-Control-Request-Headers'),
        };

        return new Response(null, {
            headers: respHeaders,
        });
    } else {
        return new Response(null, {
            headers: {
                Allow: 'GET, HEAD, POST, OPTIONS',
            },
        });
    }
}
