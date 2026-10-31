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
test('byCertTopic places every cert lab exactly once, with no duplicates per cert', () => {
  for (const { cert, groups } of G.byCertTopic(labs)) {
    const seen = new Set();
    for (const g of groups) for (const l of g.labs) {
      assert.ok(!seen.has(l.id), `${l.id} appears twice under ${cert}`);
      seen.add(l.id);
    }
    for (const l of labs.filter(x => G.inCert(x, cert))) {
      assert.ok(seen.has(l.id), `${l.id} missing from ${cert} cert→topic view`);
    }
  }
});
test('CURRICULUM references only real lab ids, each listed once', () => {
  const ids = new Set(labs.map(l => l.id));
  const seen = new Set();
  for (const cert of Object.keys(G.CURRICULUM)) {
    for (const block of G.CURRICULUM[cert]) {
      for (const id of block.labs) {
        assert.ok(ids.has(id), `CURRICULUM.${cert} references unknown lab ${id}`);
        assert.ok(!seen.has(id), `${id} listed in CURRICULUM more than once`);
        seen.add(id);
      }
    }
  }
});
