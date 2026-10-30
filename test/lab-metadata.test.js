const { test } = require('node:test');
const assert = require('node:assert');
const fs = require('fs'); const path = require('path');
const G = require('../lib/grouping');
const LABS = path.join(__dirname, '..', 'labs');
const labs = fs.readdirSync(LABS)
  .filter(d => fs.existsSync(path.join(LABS, d, 'lab.json')))
  .map(d => JSON.parse(fs.readFileSync(path.join(LABS, d, 'lab.json'), 'utf8')));

test('every lab declares at least one valid cert', () => {
  for (const l of labs) {
    assert.ok(Array.isArray(l.certs) && l.certs.length, `${l.id} has no certs`);
    for (const c of l.certs) assert.ok(G.CERTS.includes(c), `${l.id} bad cert ${c}`);
  }
});
test('every topic referenced by a lab exists in the canonical map', () => {
  const keys = new Set(G.TOPICS.map(t => t.key));
  for (const l of labs) for (const t of (l.topics || []))
    assert.ok(keys.has(t), `${l.id} references unknown topic ${t}`);
});
test('every lab lands on at least one shelf (nothing orphaned)', () => {
  const placed = new Set();
  for (const s of G.byTopic(labs)) for (const l of s.labs) placed.add(l.id);
  for (const l of labs) assert.ok(placed.has(l.id), `${l.id} unplaced`);
});
