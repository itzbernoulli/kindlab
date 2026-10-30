'use strict';
// Drift-detection test: asserts that web/grouping.js (browser mirror) stays in
// sync with lib/grouping.js (canonical CommonJS module) for TOPICS keys and CERTS.
const { test } = require('node:test');
const assert = require('node:assert/strict');
const path = require('node:path');

// Load the browser mirror once into a fake window global.
// We delete any cached version so require actually executes the file.
const webGroupingPath = path.resolve(__dirname, '../web/grouping.js');
delete require.cache[webGroupingPath];
const savedWindow = global.window;
global.window = {};
require(webGroupingPath);
const webGlobals = global.window;
global.window = savedWindow;

const G = require('../lib/grouping');

test('web/grouping.js TOPICS keys match lib/grouping.js', () => {
  const webTopicKeys = webGlobals.TOPICS.map(t => t.key);
  const libTopicKeys = G.TOPICS.map(t => t.key);
  assert.deepStrictEqual(
    webTopicKeys,
    libTopicKeys,
    'web/grouping.js TOPICS keys must match lib/grouping.js TOPICS keys in the same order'
  );
});

test('web/grouping.js CERTS match lib/grouping.js', () => {
  assert.deepStrictEqual(
    webGlobals.CERTS,
    G.CERTS,
    'web/grouping.js CERTS must match lib/grouping.js CERTS'
  );
});
