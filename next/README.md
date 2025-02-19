# Black Pear Joggers

## Apps

### Admin

The admin area of the website for committee and certain volunteers.

### Claim award

This is not finished. It will be a refresh of the form for members to submit a claim for a club standard certificate.

### CMS

The majority of content pages on the website. This aims to replace the old Wordpress website. This will load faster, allow others to easily update content on the site and allow better integration of dynamic data across the site such as results.

To run locally, run:

`npm run nx serve cms`

It will run on the following URL (change the path accordingly):

http://localhost:4200/home

### Contact

### Kit

### Register

### Vacancies

## Starting Sanity Studio

Go to `/next/apps/sanity-studio` and run `npm run sanity start`, then go to [localhost:3333](http://localhost:3333)

## Adding capabilities to your workspace

Nx supports many plugins which add capabilities for developing different types of applications and different tools.

These capabilities include generating applications, libraries, etc as well as the devtools to test, and build projects as well.

Below are our core plugins:

- [React](https://reactjs.org)
  - `npm install --save-dev @nrwl/react`
- Web (no framework frontends)
  - `npm install --save-dev @nrwl/web`
- [Angular](https://angular.io)
  - `npm install --save-dev @nrwl/angular`
- [Nest](https://nestjs.com)
  - `npm install --save-dev @nrwl/nest`
- [Express](https://expressjs.com)
  - `npm install --save-dev @nrwl/express`
- [Node](https://nodejs.org)
  - `npm install --save-dev @nrwl/node`

There are also many [community plugins](https://nx.dev/community) you could add.

## Generate a new Next.js application

Run `npx nx generate @nx/next:application app --e2eTestRunner=none` to generate an application (substitute app for your app name).

Manual steps to set up standard header, etc...

- Copy and paste a `_document.tsx` file from another app to this one
- Copy and paste a `_app.tsx` file from another app to this one
- Copy and paste a `styles.css` file from another app to this one
- Copy and paste a `next.config.js` file from another app to this one and change the app name in `basePath`

## Generate a library

Run `nx g @nrwl/react:lib my-lib` to generate a library.

> You can also use any of the plugins above to generate libraries as well.

Libraries are shareable across libraries and applications. They can be imported from `@black-pear-joggers/mylib`.

## Development server

Run `nx serve my-app` for a dev server. Navigate to http://localhost:4200/. The app will automatically reload if you change any of the source files.

## Code scaffolding

Run `nx g @nrwl/react:component my-component --project=my-app` to generate a new component.

## Build

Run `nx build my-app` to build the project. The build artifacts will be stored in the `dist/` directory. Use the `--prod` flag for a production build.

## Running unit tests

Run `nx test my-app` to execute the unit tests via [Jest](https://jestjs.io).

Run `nx affected:test` to execute the unit tests affected by a change.

## Running end-to-end tests

Run `ng e2e my-app` to execute the end-to-end tests via [Cypress](https://www.cypress.io).

Run `nx affected:e2e` to execute the end-to-end tests affected by a change.

## Understand your workspace

Run `nx dep-graph` to see a diagram of the dependencies of your projects.

## Further help

Visit the [Nx Documentation](https://nx.dev) to learn more.

## ☁ Nx Cloud

### Distributed Computation Caching & Distributed Task Execution

<p style="text-align: center;"><img src="https://raw.githubusercontent.com/nrwl/nx/master/images/nx-cloud-card.png"></p>

Nx Cloud pairs with Nx in order to enable you to build and test code more rapidly, by up to 10 times. Even teams that are new to Nx can connect to Nx Cloud and start saving time instantly.

Teams using Nx gain the advantage of building full-stack applications with their preferred framework alongside Nx’s advanced code generation and project dependency graph, plus a unified experience for both frontend and backend developers.

Visit [Nx Cloud](https://nx.app/) to learn more.
