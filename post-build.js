const fs = require('fs-extra');

console.log('Exporting root static assets');

fs.copySync('static', 'dist');
