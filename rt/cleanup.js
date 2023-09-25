#!/usr/bin/env node
//'use strict'

const fs = require ('fs');

function cleanup (inputString) {
    var r = inputString
	.replace(/❲/g,'')
	.replace(/❳/g,'')
    return decodeURIComponent(r);
}
      

var input = fs.readFileSync ('/dev/fd/0', 'UTF-8');
var output = cleanup (input);
console.log (output);
