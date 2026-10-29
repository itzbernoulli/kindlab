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

test('inCert is array-aware and dual-cert labs join both', () => {
  const lab = { id: 'x', certs: ['CKA', 'CKAD'] };
  assert.ok(G.inCert(lab, 'CKA'));
  assert.ok(G.inCert(lab, 'CKAD'));
  assert.ok(!G.inCert(lab, 'CKS'));
  const grouped = G.byCert([lab]);
  assert.strictEqual(grouped.filter(g => g.labs.includes(lab)).length, 2);
});
test('certOf falls back to category then undefined', () => {
  assert.strictEqual(G.certOf({ certs: ['CKS'] }), 'CKS');
  assert.strictEqual(G.certOf({ category: 'CKA' }), 'CKA');
  assert.strictEqual(G.certOf({}), undefined);
});
test('troubleshooting lab is cross-listed on topic shelf AND troubleshooting shelf', () => {
  const lab = { id: 't', topics: ['storage'], certs: ['CKA'], troubleshooting: true };
  const shelves = G.byTopic([lab]);
  const storage = shelves.find(s => s.key === 'storage');
  const ts = shelves.find(s => s.key === G.TROUBLESHOOTING_KEY);
  assert.ok(storage && storage.labs.includes(lab));
  assert.ok(ts && ts.labs.includes(lab));
});
test('kept-whole lab (certs, no topics) lands on exams shelf', () => {
  const lab = { id: 'ckad-exam-1', certs: ['CKAD'], type: 'exam' };
  const shelves = G.byTopic([lab]);
  assert.ok(shelves.find(s => s.key === G.EXAMS_KEY).labs.includes(lab));
});
test('lab with no topics and no certs still appears under Other', () => {
  const lab = { id: 'orphan' };
  const shelves = G.byTopic([lab]);
  assert.ok(shelves.find(s => s.key === G.OTHER_KEY).labs.includes(lab));
});
test('unknown topic key falls through to Other, no crash', () => {
  const lab = { id: 'u', topics: ['not-a-real-topic'] };
  const shelves = G.byTopic([lab]);
  assert.ok(shelves.find(s => s.key === G.OTHER_KEY).labs.includes(lab));
});
test('a single-lab topic shelf collapses (no shelf-of-one among topics)', () => {
  const labs = [
    { id: 'a', topics: ['rbac'] },
    { id: 'b', topics: ['scheduling'] },
    { id: 'c', topics: ['scheduling'] },
  ];
  const shelves = G.byTopic(labs).filter(s => G.TOPICS.some(t => t.key === s.key));
  for (const s of shelves) assert.ok(s.labs.length !== 1, `shelf ${s.key} has one lab`);
});
