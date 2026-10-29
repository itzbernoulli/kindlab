const { test } = require('node:test');
const assert = require('node:assert');
const { sliceLab } = require('../lib/slice-lab');

const SRC = {
  _dir: '/abs/labs/learn-cka-rbac',
  id: 'learn-cka-rbac', name: 'X', type: 'learn', objective: 'obj',
  questions: [
    { id:'1', title:'A', teach:'t', prompt:'p', hint:'h', solution:'s', setup:'setup/q0_setup.sh', verification:[{id:'1',description:'d',script:'validate/c1.sh',weightage:14}] },
    { id:'7', title:'G', teach:'t', prompt:'p', hint:'h', solution:'s', setup:'setup/q7_setup.sh', verification:[{id:'1',description:'d',script:'validate/c7.sh',weightage:12}] },
    { id:'8', title:'H', teach:'t', prompt:'p', hint:'h', solution:'s', setup:'setup/q8_setup.sh', verification:[{id:'1',description:'d',script:'validate/c8.sh',weightage:12}] },
  ],
};

test('renumbers picked exercises 1..n in order', () => {
  const { labJson } = sliceLab(SRC, { id:'cka-rbac-csr-binding-fix', name:'N', topics:['rbac'], certs:['CKA'], troubleshooting:true, exerciseIds:['7','8'] });
  assert.deepStrictEqual(labJson.questions.map(q=>q.id), ['1','2']);
  assert.strictEqual(labJson.questions[0].title, 'G');       // ex7 became #1
  assert.strictEqual(labJson.id, 'cka-rbac-csr-binding-fix');
  assert.deepStrictEqual(labJson.topics, ['rbac']);
  assert.deepStrictEqual(labJson.certs, ['CKA']);
  assert.strictEqual(labJson.troubleshooting, true);
  assert.strictEqual(labJson.type, 'learn');
});
test('repoints per-question setup field to copied basename', () => {
  const { labJson } = sliceLab(SRC, { id:'x', name:'N', topics:['rbac'], certs:['CKA'], exerciseIds:['7'] });
  assert.strictEqual(labJson.questions[0].setup, 'setup/q7_setup.sh');
});
test('fileCopies lists each validator + per-q setup + source q0 reseed base', () => {
  const { fileCopies } = sliceLab(SRC, { id:'x', name:'N', topics:['rbac'], certs:['CKA'], exerciseIds:['7','8'] });
  const tos = fileCopies.map(f=>f.to).sort();
  assert.ok(tos.includes('validate/c7.sh'));
  assert.ok(tos.includes('validate/c8.sh'));
  assert.ok(tos.includes('setup/q7_setup.sh'));
  assert.ok(tos.includes('setup/q8_setup.sh'));
  assert.ok(tos.includes('setup/q0_setup.sh'));   // reseed starting point
  const from = fileCopies.find(f=>f.to==='validate/c7.sh').from;
  assert.strictEqual(from, '/abs/labs/learn-cka-rbac/validate/c7.sh');
});
test('omits troubleshooting/needsSecondCluster when not set', () => {
  const { labJson } = sliceLab(SRC, { id:'x', name:'N', topics:['rbac'], certs:['CKA'], exerciseIds:['1'] });
  assert.ok(!('troubleshooting' in labJson));
  assert.ok(!('needsSecondCluster' in labJson));
});
test('marks the q0 reseed-base copy optional so a source without q0_setup.sh does not force it', () => {
  // Some labs (e.g. falco) have no global setup/q0_setup.sh — only per-question setups.
  // The q0 base copy must be flagged optional so the driver can skip it when absent.
  // Pick an exercise whose own setup is NOT q0 (ex7), so q0 is added only as the base.
  const { fileCopies } = sliceLab(SRC, { id:'x', name:'N', topics:['rbac'], certs:['CKA'], exerciseIds:['7'] });
  const q0 = fileCopies.find(f => f.to === 'setup/q0_setup.sh');
  assert.ok(q0, 'q0 base is still listed');
  assert.strictEqual(q0.optional, true, 'q0 base copy is marked optional');
});
