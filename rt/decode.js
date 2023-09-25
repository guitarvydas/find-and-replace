#!/usr/bin/env node
//'use strict'

const fs = require ('fs');

function cleanup (inputString) {
    return decodeURIComponent(inputString);
}
      

var input = fs.readFileSync ('/dev/fd/0', 'UTF-8');
var output = cleanup (input);
console.log (output);
