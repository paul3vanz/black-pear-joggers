const fs = require('fs-extra');

console.log('Moving static sites');

const appsFolder = 'dist/apps';
const destinationFolder = 'dist/exported';
const apps = fs.readdirSync(appsFolder);

console.log('Clearing ' + destinationFolder);
fs.removeSync(destinationFolder);

apps.forEach((currentApp) => {
  console.log('Processing ' + currentApp);

  const app = fs.readdirSync(appsFolder + '/' + currentApp);

  const appSourceFolder = appsFolder + '/' + currentApp + '/exported';
  const appDestinationFolder = destinationFolder + '/' + currentApp;
  console.log('Copying ' + appSourceFolder + ' to ' + appDestinationFolder);
  fs.copySync(appSourceFolder, appDestinationFolder);
});
