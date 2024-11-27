Cloudflare workers for various serverless functionality to aid the Black Pear Joggers website.

## Workers

### CMS

This worker allows you to rewrite the URL so pages appear on bpj.org.uk but are served from different servers, e.g. Cloudflare pages (the new Next.js pages like contact/kit), Netlify (the older Angular apps like club standards/magic-mile), the Sanity/Next.js CMS (like the home page/champions league) or the older Wordpress site. This is better for SEO, looks more consistent and allows a gradual migration away from Wordpress to the new CMS.

To run the worker locally for development purposes, run `npx wrangler dev cms/src/index`

You can then access the worker on `localhost` port `8787`, e.g:

http://127.0.0.1:8787/privacy-policy

The path appended is any of the routes from the array in the `wrangler.toml` file.

As new pages are created in the new CMS, add their path to the `wrangler.toml`, e.g:

```
routes = [
  "bpj.org.uk/page-to-affect*",
]
```

Then test it locally to ensure the right page displays:

http://127.0.0.1:8787/page-to-affect

If it's all good, to deploy changes to production, run `npx wrangler publish cms/src/index`

### Contact

This worker is for the contact form on the website to be able to send emails

To run the worker locally for development purposes, run `npx wrangler dev contact/src/index`

You can then access the worker on `localhost` port `8787`, e.g:

POST http://127.0.0.1:8787

Example body:

{
"reason": "Welfare",
"name": "Tester",
"email": "test@gmail.com",
"message": "Testing"
}

If it's all good, to deploy changes to production, run `npx wrangler publish contact/src/index`
