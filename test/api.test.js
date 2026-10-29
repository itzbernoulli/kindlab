'use strict';
const { test } = require('node:test');
const assert = require('node:assert/strict');

test('/api/labs serializer carries topics/certs/troubleshooting', () => {
  const serialize = require('../lib/serialize-lab'); // extracted in step 3
  const out = serialize({ id: 'x', name: 'X', type: 'learn', certs: ['CKA'], topics: ['rbac'], troubleshooting: true, questions: [] }, (l) => l.type === 'learn' ? 'learn' : 'exam');
  assert.deepStrictEqual(out.certs, ['CKA']);
  assert.deepStrictEqual(out.topics, ['rbac']);
  assert.strictEqual(out.troubleshooting, true);
});
