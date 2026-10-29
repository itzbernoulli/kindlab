const { test } = require('node:test');
const assert = require('node:assert');
const G = require('../lib/grouping');

test('canonical certs are ordered CKAD, CKA, CKS', () => {
  assert.deepStrictEqual(G.CERTS, ['CKAD', 'CKA', 'CKS']);
});
test('topics include spec shelves in declaration order with rbac before scheduling', () => {
  const keys = G.TOPICS.map(t => t.key);
  assert.ok(keys.includes('rbac') && keys.includes('scheduling'));
  assert.ok(keys.indexOf('rbac') < keys.indexOf('scheduling'));
  assert.ok(keys.every(k => k !== G.TROUBLESHOOTING_KEY && k !== G.EXAMS_KEY));
});
test('every topic has a human label', () => {
  for (const t of G.TOPICS) assert.ok(t.label && typeof t.label === 'string');
});
