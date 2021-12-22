const fs = require('fs-extra');

console.log('Moving static sites');

const appsFolder = 'dist/apps';
const apps = fs.readdirSync(appsFolder);

apps.forEach((currentApp) => {
  const app = fs.readdirSync(appsFolder + '/' + currentApp);

  fs.removeSync(appsFolder + '/' + currentApp + '/.next');
  fs.removeSync(appsFolder + '/' + currentApp + '/public');

  try {
    fs.unlinkSync(appsFolder + '/' + currentApp + '/next.config.js');
    fs.unlinkSync(appsFolder + '/' + currentApp + '/package.json');
  } catch {}

  fs.copySync(
    appsFolder + '/' + currentApp + '/exported',
    appsFolder + '/' + currentApp
  );

  fs.removeSync(appsFolder + '/' + currentApp + '/exported');
});
