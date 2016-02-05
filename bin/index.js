#!/usr/bin/env node

process.title = 'pipemail-server';

try {
    require('coffee-script/register');
} catch(e) {}

require('./../lib/index');