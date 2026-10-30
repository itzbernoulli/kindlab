# Dual-Axis Grouping Engine Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make kindlab browse and mock-pool labs by two independent axes — Kubernetes topic and cert — driven by new `topics[]`/`certs[]` lab metadata, proven end-to-end on the existing 40 labs before any content is sliced.

**Architecture:** Extract the grouping/filtering decisions out of the CLI and web renderers into a shared pure module (`lib/grouping.js`, zero-dependency, `node:test`-testable without a cluster), add `topics`/`certs`/`troubleshooting` to a canonical map and to each existing `lab.json`, then rewire `cmdList`, `buildMockPool`, `/api/labs`, and `web/app.js` to consume the pure functions. `category` stays as a derived display-only field; membership checks become array-aware (`certs.includes(cert)`).

**Tech Stack:** Node.js (zero runtime deps), Node built-in `node:test` + `node:assert` for tests, vanilla JS web dashboard.

**Spec:** `docs/superpowers/specs/2026-10-29-bite-sized-topic-labs-design.md`

This plan implements **only the grouping engine** (the spec's implementation-order step 1). The content slicing (steps 2–3, ~78 labs) is a separate follow-on plan that depends on this one shipping; it is out of scope here.

## Global Constraints

- **Zero new runtime dependencies.** No npm installs for shipped code. Tests use only Node built-ins (`node:test`, `node:assert`). (Spec: "The project is a single-file Node CLI … no npm deps. Keep it that way.")
- **Format unchanged.** Do not alter the `questions[]` exercise schema (teach/prompt/hint/solution/weighted verification). (Spec non-goal.)
- **`category` is derived, display-only.** When absent, `category = certs[0]`. Never filter membership on `category` for mocks/playlists. (Spec: "`category` and mock-pool behavior".)
- **Cert-aware membership.** A lab is in cert C's playlist/mock iff `C ∈ certs[]` — not `certs[0]`. (Spec: dual-cert decision.)
- **Order = declaration order in the canonical map.** No per-lab ordinal field. (Spec: "Shelf and playlist order = declaration order".)
- **Canonical topic/cert map defined once**, in `lib/grouping.js`, consumed by both CLI and web. (Spec §3.)
- **Kept-whole labs:** `certs` only, no `topics`; they surface on the Exams & Mocks shelf. Keep their existing ids. (Spec.)
- Valid cert values: `CKA`, `CKAD`, `CKS`. Topic shelf set and order per spec §3.

## Review Focus

- **A lab with no `topics` and no `certs`** → it must still appear somewhere (an "Other"/uncategorized shelf), never silently vanish from browse. Owned by Task 2.
- **A lab whose `topics[0]` names a topic not in the canonical map** → must not crash grouping; fall through to "Other". Owned by Task 2.
- **A dual-cert lab (`certs: ["CKA","CKAD"]`)** → appears in both cert playlists and both mock pools exactly once each, not duplicated within one. Owned by Task 2 (grouping) and Task 5 (mock).
- **A `troubleshooting: true` lab** → appears on BOTH its topic shelf and the Troubleshooting shelf (cross-listed, not moved). Owned by Task 2.
- **A topic shelf that ends up with exactly one lab** → collapses into its nearest declared neighbor so no shelf-of-one renders. Owned by Task 2.

---

### Task 1: Canonical map + `node:test` harness

**Files:**
- Create: `lib/grouping.js`
- Create: `test/grouping.test.js`
- Modify: `package.json` (add `"test": "node --test"` to `scripts`)

**Interfaces:**
- Produces: `TOPICS` (ordered `Array<{key, label}>`), `CERTS` (ordered `Array<string>` = `['CKAD','CKA','CKS']`), `TROUBLESHOOTING_KEY = 'troubleshooting'`, `EXAMS_KEY = 'exams'`, `OTHER_KEY = 'other'`, all exported from `lib/grouping.js` via `module.exports`.

- [ ] **Step 1: Write the failing test**

```js
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `node --test test/grouping.test.js`
Expected: FAIL — cannot find module `../lib/grouping`.

- [ ] **Step 3: Create `lib/grouping.js` exporting the canonical constants**

Populate `TOPICS` with the ~15 topic keys from spec §3 in the spec's declaration order (`cluster-ops, kubeadm, etcd, rbac, scheduling, workloads, storage, config, pod-design, services, networking, observability, network-policy, pod-security, supply-chain, hardening, runtime-security, gateway-api, multicluster, images, helm-kustomize, crd, quotas`), each `{key, label}` with a readable label. Exclude `troubleshooting` and `exams` from `TOPICS` (they are the two pinned trailing shelves, exported as their own key constants). Export `CERTS = ['CKAD','CKA','CKS']`.

- [ ] **Step 4: Run test to verify it passes**

Run: `node --test test/grouping.test.js`
Expected: PASS (3 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/grouping.js test/grouping.test.js package.json
git commit -m "feat(grouping): canonical topic/cert map + node:test harness"
```

---

### Task 2: Pure grouping functions

**Files:**
- Modify: `lib/grouping.js`
- Modify: `test/grouping.test.js`

**Interfaces:**
- Consumes: `TOPICS`, `CERTS`, key constants from Task 1.
- Produces, all pure (take a `labs` array of plain lab objects `{id, name, type, topics?, certs?, troubleshooting?, category?}`, return grouped data, never touch fs):
  - `certOf(lab) -> string` — `lab.certs?.[0] ?? lab.category ?? undefined` (the derived display cert).
  - `inCert(lab, cert) -> boolean` — `(lab.certs ?? (lab.category ? [lab.category] : [])).includes(cert)`.
  - `byCert(labs) -> Array<{cert, labs}>` — one entry per `CERTS` value (declaration order) whose `labs` are those with `inCert` true, each inner list keeping input order; omit empty certs.
  - `byTopic(labs) -> Array<{key, label, labs}>` — one entry per `TOPICS` key (declaration order) holding labs whose `topics` includes that key; then a `TROUBLESHOOTING_KEY` shelf holding every lab with `troubleshooting === true` (cross-listed, not removed from its topic shelf); then an `EXAMS_KEY` shelf holding labs that have `certs` but no non-empty `topics`; then an `OTHER_KEY` shelf for labs matched by no prior shelf. Collapse any **topic** shelf (not the pinned trailing three) holding exactly one lab into the next non-empty topic shelf. Omit empty shelves.

- [ ] **Step 1: Write the failing tests**

```js
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
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `node --test test/grouping.test.js`
Expected: FAIL — `G.inCert`/`G.byCert`/`G.byTopic`/`G.certOf` not functions.

- [ ] **Step 3: Implement `certOf`, `inCert`, `byCert`, `byTopic` in `lib/grouping.js`**

Per the Interfaces signatures. `byTopic` builds topic shelves first (declaration order), then appends the Troubleshooting, Exams, and Other shelves in that order; applies the single-lab collapse to topic shelves only; omits empties. Collapse rule: a topic shelf with exactly one lab moves that lab into the next non-empty topic shelf in declaration order (if none follows, into Other).

- [ ] **Step 4: Run tests to verify they pass**

Run: `node --test test/grouping.test.js`
Expected: PASS (all).

- [ ] **Step 5: Commit**

```bash
git add lib/grouping.js test/grouping.test.js
git commit -m "feat(grouping): pure byCert/byTopic/inCert/certOf functions"
```

---

### Task 3: Tag all 40 existing labs with `topics`/`certs`

**Files:**
- Modify: every `labs/*/lab.json` (add fields; `questions[]` untouched)
- Create: `test/lab-metadata.test.js`

**Interfaces:**
- Consumes: `CERTS`, `TOPICS` keys from Task 1; `inCert`/`byTopic` from Task 2.
- Produces: each `lab.json` gains `certs: [...]` (from its current `category`), and — for non-kept-whole labs — `topics: [...]`; kept-whole exam/capstone labs get `certs` only. Add `troubleshooting: true` to the labs the spec marks `[TS]`. This task tags the *current* mega-labs (no splitting) per the spec's step 1 — a mega-lab's `topics` is the union of its eventual slices' topics.

- [ ] **Step 1: Write the failing test**

```js
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `node --test test/lab-metadata.test.js`
Expected: FAIL — existing labs have no `certs` field yet.

- [ ] **Step 3: Add `certs`/`topics`/`troubleshooting` to each `lab.json`**

For each lab: set `certs` to `[<current category>]`. For learn mega-labs, set `topics` to the union of the topic tags its slices carry in the spec split map (e.g. `learn-cka-rbac` → `["rbac"]`; `learn-ckad-services-net` → `["services","networking"]`). Set `troubleshooting: true` on labs whose split map entry contains a `[TS]` slice (every learn mega-lab with a diagnose exercise, plus `learn-ckad-observability`). Kept-whole labs (`cka-clusterops`, `cka-nodeops`, `ckad-exam-1`, `learn-ckad-harden-deploy`, `cks-hardening`, `cks-runtime-audit`, and the four kept CKAD arcs) — of these, the exam/capstone ones get `certs` only (no `topics`); the four kept CKAD *learn* arcs (`autoscaling`, `canary`, `modify-assets`, `serviceaccount`) keep a topic. Leave `category` in place.

- [ ] **Step 4: Run test to verify it passes**

Run: `node --test test/lab-metadata.test.js`
Expected: PASS (3 tests).

- [ ] **Step 5: Commit**

```bash
git add labs test/lab-metadata.test.js
git commit -m "feat(labs): tag all labs with topics/certs/troubleshooting"
```

---

### Task 4: Rewire CLI `cmdList` to dual-axis browse

**Files:**
- Modify: `bin/kindlab.js` (`loadLabs` ~122, `cmdList` ~223–235, dispatch ~630)
- Modify: `test/grouping.test.js` (add a cmdList-formatting unit if logic is extracted)

**Interfaces:**
- Consumes: `byTopic`, `byCert`, `certOf`, `TOPICS` from `lib/grouping.js`.
- Produces: `kindlab list` groups by topic (default); `kindlab list --cert` groups by cert. `cmdList(opts)` where `opts = { byCert: boolean }`.

- [ ] **Step 1: Write the failing test**

Extract the shelf-selection into a testable pure helper and assert on it (not on console output):

```js
test('cmdList uses byTopic by default and byCert with --cert', () => {
  const labs = [{ id: 'a', topics: ['rbac'], certs: ['CKA'] }, { id: 'b', topics: ['rbac'], certs: ['CKA'] }];
  assert.strictEqual(G.shelvesFor(labs, { byCert: false })[0].key, 'rbac');
  assert.strictEqual(G.shelvesFor(labs, { byCert: true })[0].cert, 'CKA');
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `node --test test/grouping.test.js`
Expected: FAIL — `G.shelvesFor` not a function.

- [ ] **Step 3: Add `shelvesFor(labs, opts)` to `lib/grouping.js` and rewire `cmdList`**

`shelvesFor` returns `byCert(labs)` when `opts.byCert`, else `byTopic(labs)`. In `bin/kindlab.js`: `require('../lib/grouping')`, replace the hardcoded `for (const cert of ['CKAD','CKA','CKS','Other'])` loop and `l.category === cert` filter in `cmdList` with iteration over `shelvesFor(loadLabs(), opts)`, rendering each shelf's `label`/`cert` header then its labs (learn before exam, as today). Parse `--cert` from argv in the `case 'list'` dispatch (line ~630) and pass `{ byCert }`.

- [ ] **Step 4: Run tests + eyeball the command**

Run: `node --test test/grouping.test.js` → PASS.
Run: `node bin/kindlab.js list` and `node bin/kindlab.js list --cert` → topic shelves vs cert shelves render, every lab present.

- [ ] **Step 5: Commit**

```bash
git add bin/kindlab.js lib/grouping.js test/grouping.test.js
git commit -m "feat(cli): dual-axis `list` (topic default, --cert)"
```

---

### Task 5: Make mock pool cert-aware

**Files:**
- Modify: `bin/kindlab.js` (`buildMockPool` ~389–398)
- Modify: `test/grouping.test.js` or new `test/mock.test.js`

**Interfaces:**
- Consumes: `inCert` from `lib/grouping.js`.
- Produces: `buildMockPool(cert)` includes a lab's tasks iff `inCert(lab, cert) && labType(lab) === 'exam'` — so a dual-cert exam lab feeds both pools.

- [ ] **Step 1: Write the failing test**

Extract the pool-membership predicate so it is testable without a cluster:

```js
test('mock pool membership is cert-aware (dual-cert exam feeds both)', () => {
  const lab = { id: 'm', certs: ['CKA', 'CKAD'], type: 'exam' };
  assert.ok(G.inMockPool(lab, 'CKA'));
  assert.ok(G.inMockPool(lab, 'CKAD'));
  assert.ok(!G.inMockPool({ id: 'n', certs: ['CKS'], type: 'exam' }, 'CKA'));
  assert.ok(!G.inMockPool({ id: 'o', certs: ['CKA'], type: 'learn' }, 'CKA'));
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `node --test test/grouping.test.js`
Expected: FAIL — `G.inMockPool` not a function.

- [ ] **Step 3: Add `inMockPool(lab, cert)` to `lib/grouping.js` and use it in `buildMockPool`**

`inMockPool = (lab, cert) => inCert(lab, cert) && (lab.type === 'learn' ? false : true)`. In `buildMockPool`, replace `l.category === cert && labType(l) === 'exam'` with `inMockPool(l, cert)`.

- [ ] **Step 4: Run tests to verify they pass**

Run: `node --test` (whole suite)
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add bin/kindlab.js lib/grouping.js test/grouping.test.js
git commit -m "feat(mock): cert-aware mock pool membership"
```

---

### Task 6: Serialize new fields + rewire web browse

**Files:**
- Modify: `bin/kindlab.js` (`/api/labs` ~506 — add `topics`, `certs`, `troubleshooting` to the serialized lab)
- Modify: `web/app.js` (grouping loop ~102–109; `certOf` usage at ~94,132,133)
- Modify: `web/index.html`, `web/styles.css` (topic/cert toggle control + shelf styles)

**Interfaces:**
- Consumes: the `/api/labs` payload now carrying `topics`/`certs`/`troubleshooting`.
- Produces: the web lab list renders topic shelves by default with a toggle to cert shelves; dual-cert labs appear under each of their certs.

Note: `web/app.js` cannot `require` the Node module. Mirror the small canonical map + `byTopic`/`byCert` into a browser-friendly form — either a `web/grouping.js` ES-module copy loaded by `index.html`, or inline. Keep it a literal mirror of `lib/grouping.js`; the Task 1 test's canonical values are the source of truth to copy from.

- [ ] **Step 1: Write the failing test**

```js
// test/api.test.js — assert the serializer includes the new fields
test('/api/labs serializer carries topics/certs/troubleshooting', () => {
  const serialize = require('../lib/serialize-lab'); // extracted in step 3
  const out = serialize({ id: 'x', name: 'X', type: 'learn', certs: ['CKA'], topics: ['rbac'], troubleshooting: true, questions: [] });
  assert.deepStrictEqual(out.certs, ['CKA']);
  assert.deepStrictEqual(out.topics, ['rbac']);
  assert.strictEqual(out.troubleshooting, true);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `node --test test/api.test.js`
Expected: FAIL — `../lib/serialize-lab` missing.

- [ ] **Step 3: Extract `serialize-lab.js`, use it in `/api/labs`, mirror grouping to web**

Create `lib/serialize-lab.js` exporting `module.exports = (l) => ({ id, name, category: certOf(l), certs: l.certs||[], topics: l.topics||[], troubleshooting: !!l.troubleshooting, type: labType(l), requiresHost: !!l.requiresHost, tasks: (l.questions||[]).length })`. Use it in the `/api/labs` handler. In `web/app.js`, replace the hardcoded `for (const cert of ['CKAD','CKA','CKS','Other'])` block with a render over mirrored `byTopic(labs)` (default) / `byCert(labs)` (toggle), and replace `l.category` reads at lines ~94/132/133 with the served `category`. Add a topic/cert toggle to `index.html` and shelf styling to `styles.css` (reuse existing `.lab-section` / `.cert-*` classes; add topic-shelf styling as needed).

- [ ] **Step 4: Verify**

Run: `node --test` → PASS. Run: `node bin/kindlab.js serve`, open the dashboard, confirm topic shelves render, the toggle switches to cert shelves, and a known dual-cert lab shows under both certs.

- [ ] **Step 5: Commit**

```bash
git add bin/kindlab.js web lib/serialize-lab.js test/api.test.js
git commit -m "feat(web): dual-axis browse + serialize topics/certs"
```

---

### Task 7: Update README to the dual-axis model

**Files:**
- Modify: `README.md` (the "Writing a lab" / lab-format section, and any CKA/CKS-only framing)

**Interfaces:**
- Consumes: the final field set from Tasks 1–6.

- [ ] **Step 1: Document the schema + browse**

Add `topics[]`, `certs[]`, `troubleshooting` to the lab-format docs (with the canonical topic list and the "topics[0] = home shelf / certs drive playlists & mocks / troubleshooting cross-lists" rules), and document `kindlab list [--cert]`. Note `category` is now derived/display-only.

- [ ] **Step 2: Commit**

```bash
git add README.md
git commit -m "docs: dual-axis topic/cert lab model"
```

---

## Notes for the follow-on (out of scope here)

The ~78-lab content slice is a separate plan. It depends on this engine shipping and on the spec's §2 split mechanics (copy-and-repath validators, renumber questions, author reseed `q0_setup.sh`, isolation `check`). Do not start it from this plan.
