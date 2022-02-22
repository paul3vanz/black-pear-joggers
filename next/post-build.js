const fs = require('fs-extra');

console.log('Moving static sites');

console.log(getFiles('dist'));

const appsFolder = 'dist/apps';
const apps = fs.readdirSync(appsFolder);

function getFiles(dir, files_) {
  files_ = files_ || [];
  var files = fs.readdirSync(dir);
  for (var i in files) {
    var name = dir + '/' + files[i];
    if (fs.statSync(name).isDirectory()) {
      getFiles(name, files_);
    } else {
      files_.push(name);
    }
  }
  return files_;
}

try {
  apps.forEach((currentApp) => {
    console.log('Processing ' + currentApp);

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
} catch {}

console.log(getFiles('dist'));
