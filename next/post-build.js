const fs = require('fs-extra');

console.log('Moving static sites');

const appsFolder = 'dist/apps';
const destinationFolder = 'dist/exported';
const apps = fs.readdirSync(appsFolder);

console.log('Contents of apps folder:');
console.log(apps);

console.log('Clearing ' + destinationFolder);
fs.removeSync(destinationFolder);

apps.forEach((currentApp) => {
  console.log('Processing ' + currentApp);

  console.log('Contents of app folder:');
  const app = fs.readdirSync(appsFolder + '/' + currentApp);

  console.log(app);

  const appSourceFolder = appsFolder + '/' + currentApp + '/exported';
  const appDestinationFolder = destinationFolder + '/' + currentApp;
  console.log('Copying ' + appSourceFolder + ' to ' + appDestinationFolder);
  fs.copySync(appSourceFolder, appDestinationFolder);
});
