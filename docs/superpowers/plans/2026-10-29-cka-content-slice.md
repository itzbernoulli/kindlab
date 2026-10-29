# CKA Content Slice Implementation Plan (Pilot)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Split the 9 CKA mega-labs into ~22 small, independently-launchable named-scenario labs per the spec's split map, each passing `kindlab check` in isolation, proving the bite-sized format end-to-end before rolling CKAD/CKS.

**Architecture:** A pure, cluster-free Node helper (`lib/slice-lab.js`) does the mechanical work — given a source lab + a cut spec (new id, name, topics, certs, source exercise ids), it emits a new lab folder: a `lab.json` with questions renumbered `1..n` and `verification[].script`/`setup` paths repointed, plus the copied subset of validator and per-question setup scripts. The only hand-authored artifact per new lab is its `setup/q0_setup.sh` reseed (the state earlier-but-now-removed exercises used to build). Each new lab is verified live with `kindlab check` on the running 3-node cluster. Source mega-labs are deleted once their children all pass.

**Tech Stack:** Node.js (zero deps), Node `node:test`, bash validator/setup scripts, a live `kind` cluster for verification.

**Spec:** `docs/superpowers/specs/2026-10-29-bite-sized-topic-labs-design.md` (§2 "How a split physically happens", and the CKA split map)

**Depends on:** the dual-axis grouping engine (already merged to this branch) — small labs carry `topics`/`certs`/`troubleshooting` and surface on the shelves it built.

## Global Constraints

- **Zero new dependencies.** Helper + tests use Node built-ins only. (Spec.)
- **Exercise format unchanged.** Each question keeps `id,title,teach,prompt,hint,solution,setup?,verification`. Only `id` renumbers and script paths repoint. (Spec non-goal: no format change.)
- **Golden rule (hard):** every `check` re-runs ALL of a lab's validators, so each new small lab must be satisfiable by one final cluster state. A new lab's `setup/q0_setup.sh` must seed everything its exercises assume — including state the removed earlier exercises used to build. (Spec constraint.)
- **Validator path is authoritative.** Validator filenames are inconsistent across labs (`q<N>_s<M>.sh` vs `c<N>.sh`). Always read the real path from `verification[].script`; never guess the filename. (Grounded in the lab inventory.)
- **Per-question `setup` travels with its exercise.** When an exercise with a `setup` field moves to a new lab, its setup script is copied and the field repointed.
- **New small-lab ids are topic-prefixed kebab** (e.g. `cka-rbac-basics`, `cka-rbac-sa-leastpriv`, `cka-rbac-csr-fix`). Source mega-lab ids (`learn-cka-*`) are retired.
- **Metadata per new lab:** `certs: ["CKA"]`; `topics` + `troubleshooting` per the split map below. `category` omitted (derived).
- **needsSecondCluster** is preserved: only `learn-cka-multicluster`'s children keep `needsSecondCluster: true`.
- Verification uses `KUBECONFIG=/Users/ayodeji/Workspace/kindlab/.state/kubeconfig` against the live cluster; `kindlab reset` between labs where a lab mutates control-plane/node state.

## The CKA split map (authoritative for this plan)

Exercise ids reference the current `learn-cka-*` `questions[].id`. `[TS]` → `troubleshooting: true`.

| New lab id | name | from | exercises | topics | TS |
|---|---|---|---|---|---|
| `cka-clusterops-staticpod-etcd` | Static pods & etcd backup | clusterops | 1,3 | cluster-ops | |
| `cka-clusterops-node-maint` | Node maintenance: taint, drain, uncordon, label | clusterops | 4,5,6,7 | cluster-ops | |
| `cka-clusterops-cp-repair` | Repair a control-plane component | clusterops | 2,8 | cluster-ops | [TS] |
| `cka-cni-fundamentals` | How the CNI and CoreDNS work | cni | 1,2,4 | networking,cni | |
| `cka-cni-expose` | Expose a Deployment: ClusterIP, headless, NodePort | cni | 5,6,7,8 | services,networking | |
| `cka-cni-nodefix` | Fix a node with no CNI config | cni | 3 | cni | [TS] |
| `cka-etcd-backup-restore` | Back up and restore etcd | etcd-restore | 1,2,3,4,8 | etcd | |
| `cka-etcd-manifest-fix` | Read etcd's manifest + fix a bad backup | etcd-restore | 5,6,7 | etcd | [TS] |
| `cka-gw-standup` | Stand up a Gateway | gateway-api | 1,2,3 | gateway-api,networking | |
| `cka-gw-routing` | HTTPRoute matching, filters & traffic splitting | gateway-api | 4,5,6,7 | gateway-api,networking | |
| `cka-gw-vs-ingress-fix` | Gateway vs Ingress + fix a detached route | gateway-api | 8,9 | gateway-api | [TS] |
| `cka-kubeadm-inspect` | Inspect a kubeadm cluster | kubeadm | 1,2,3 | kubeadm | |
| `cka-kubeadm-join-certs` | Join nodes & renew certificates | kubeadm | 4,6 | kubeadm | |
| `cka-kubeadm-upgrade-diag` | Upgrade plan, drain & schedule diagnosis | kubeadm | 5,7,8 | kubeadm | [TS] |
| `cka-multicluster-contexts` | Work across two clusters with contexts | multicluster | 1,2,3,4,5,6,8 | multicluster | |
| `cka-multicluster-wrongcluster-fix` | Fix a Deployment on the wrong cluster | multicluster | 7 | multicluster | [TS] |
| `cka-rbac-basics` | Role & RoleBinding basics | rbac | 1,2 | rbac | |
| `cka-rbac-sa-leastpriv` | ServiceAccounts & least-privilege RBAC | rbac | 3,4,5,6 | rbac | |
| `cka-rbac-csr-binding-fix` | Approve a CSR + fix a broken binding | rbac | 7,8 | rbac | [TS] |
| `cka-sched-selectors-taints` | Steer pods with nodeSelector & taints | scheduling | 1,2,5 | scheduling | |
| `cka-sched-affinity` | Node & pod affinity | scheduling | 3,4,7 | scheduling | |
| `cka-sched-daemonset-fix` | DaemonSets + fix an unschedulable pod | scheduling | 6,8 | scheduling | [TS] |
| `cka-storage-static` | Static PVs and PVCs | storage | 2,3,4,5 | storage | |
| `cka-storage-dynamic` | StorageClasses & dynamic provisioning | storage | 1,6,7 | storage | |
| `cka-storage-pvc-fix` | Fix a PVC stuck Pending | storage | 8 | storage | [TS] |

25 new labs from 9 mega-labs. `cka-clusterops` and `cka-nodeops` (the exam-style labs) are NOT split — untouched.

## File structure

- `lib/slice-lab.js` (new) — pure slicing helper (see Task 1 interface).
- `test/slice-lab.test.js` (new) — unit tests for the helper.
- `labs/cka-*/` (new, 25 folders) — the sliced labs.
- `labs/learn-cka-*/` (9 folders) — DELETED after their children pass.
- `scripts/slice-cka.js` (new, throwaway) — a thin driver that feeds the map above into `lib/slice-lab.js` for one source lab. Committed so the pattern is reusable for CKAD/CKS.

## Review Focus

- **A validator script referenced by two sibling new labs** (same `c<N>.sh` reused) must be copied into BOTH folders, not left dangling in the deleted source. Owned by Task 1 (helper copies per-lab) + each slice task's `kindlab check`.
- **A new lab whose exercises assumed state built by a removed earlier exercise** — e.g. `cka-rbac-csr-binding-fix` (ex 7,8) no longer has ex1's `rbac-learn` namespace/roles — must seed it in `q0_setup.sh` or `check` fails. Owned by every slice task's reseed step + live `check`.
- **A per-question `setup` field pointing at a path that no longer exists** after renumber (e.g. ex8→new ex2 but `setup: setup/q8_setup.sh`) — helper must repoint to the copied/renamed script. Owned by Task 1 + its test.
- **A lab needing the second cluster** (`cka-multicluster-*`) must keep `needsSecondCluster: true` or its context steps error. Owned by the multicluster slice task.
- **Weightages that no longer sum to 100** within a new lab after slicing — the spec's weightage-per-check is a display/scoring value; a sliced lab's checks will sum to <100. Decide: renormalize or leave. (Ruling in Task 1.)

---

### Task 1: The slicing helper

**Files:**
- Create: `lib/slice-lab.js`
- Create: `test/slice-lab.test.js`

**Interfaces:**
- Produces: `sliceLab(sourceLab, cut) -> { labJson, fileCopies }` where
  - `sourceLab` = parsed source `lab.json` (with `_dir` absolute path).
  - `cut` = `{ id, name, topics, certs, troubleshooting?, needsSecondCluster?, exerciseIds: string[] }`.
  - `labJson` = the new lab object: `{ id, name, type:'learn', objective, certs, topics, troubleshooting?, needsSecondCluster?, questions }`. `questions` = the picked source questions in `exerciseIds` order, each deep-cloned with `id` renumbered to its 1-based position, each `verification[].script` repointed from `validate/<orig>` to `validate/<orig-basename>` (unchanged basename — scripts keep their original filenames to avoid rewriting script bodies), and `setup` (if present) repointed to `setup/<orig-basename>`.
  - `fileCopies` = `Array<{from: absPath, to: relPath}>` listing every validator script (from each picked question's `verification[].script`) and every per-question `setup` script to copy into the new lab folder, PLUS always the source `setup/q0_setup.sh` copied to the new lab's `setup/q0_setup.sh` as the reseed STARTING POINT (the slice task then hand-edits it).
  - Pure: reads nothing, writes nothing; returns data. The driver (Task 2) does fs.

**Ruling (weightage):** leave per-check `weightage` values as-authored; do NOT renormalize to 100. A learn lab's score is informational and the dashboard shows mastery as all-checks-pass, not a percentage threshold. Renormalizing would mean rewriting every weightage and gains nothing. (If a reviewer flags it, this is the recorded decision.)

- [ ] **Step 1: Write the failing test**

```js
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `node --test test/slice-lab.test.js`
Expected: FAIL — cannot find `../lib/slice-lab`.

- [ ] **Step 3: Implement `sliceLab(sourceLab, cut)` in `lib/slice-lab.js`**

Per the Interfaces + test. Deep-clone picked questions (JSON round-trip), renumber `id` to 1-based position, keep `verification[].script` and `setup` basenames (repoint is a no-op on basename but normalize to `validate/<base>` / `setup/<base>`). Build `fileCopies` from each picked question's validator scripts + its `setup` + the source `setup/q0_setup.sh`→`setup/q0_setup.sh`. Carry `objective` from source. Only include `troubleshooting`/`needsSecondCluster` keys when truthy in `cut`.

- [ ] **Step 4: Run test to verify it passes**

Run: `node --test test/slice-lab.test.js`
Expected: PASS (4 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/slice-lab.js test/slice-lab.test.js
git commit -m "feat(slice): pure lab-slicing helper"
```

---

### Task 2: The slice driver + materialize one lab group (rbac)

**Files:**
- Create: `scripts/slice-cka.js`
- Create: `labs/cka-rbac-basics/`, `labs/cka-rbac-sa-leastpriv/`, `labs/cka-rbac-csr-binding-fix/`
- Delete: `labs/learn-cka-rbac/` (only after all three pass)

**Interfaces:**
- Consumes: `sliceLab` from Task 1.
- Produces: `scripts/slice-cka.js` exporting/running `materialize(sourceId, cuts)` that for each cut calls `sliceLab`, makes the new `labs/<cut.id>/{setup,validate}/` dirs, writes `lab.json` (2-space JSON), and copies every `fileCopies` entry. CLI: `node scripts/slice-cka.js <sourceId>` materializes all cuts for that source (cuts table embedded in the script, matching the plan's split map).

- [ ] **Step 1: Materialize the three rbac labs**

Run: `node scripts/slice-cka.js learn-cka-rbac`
Verify: `labs/cka-rbac-basics`, `labs/cka-rbac-sa-leastpriv`, `labs/cka-rbac-csr-binding-fix` each exist with `lab.json` + copied `validate/*.sh` + `setup/q0_setup.sh`.

- [ ] **Step 2: Hand-author each reseed `q0_setup.sh`**

For each new rbac lab, edit `setup/q0_setup.sh` so the lab stands alone. The source `learn-cka-rbac/setup/q0_setup.sh` created namespace `rbac-learn`; `q7_setup.sh` submitted the pending CSR `learn-dev`; `q8_setup.sh` created the broken `auditor` binding. So:
- `cka-rbac-basics` (ex1,2): needs `rbac-learn` ns. Reuse source q0 as-is.
- `cka-rbac-sa-leastpriv` (ex3,4,5,6): needs `rbac-learn` ns + the two ConfigMaps `app-config`/`other-config` that ex5 asserts on (originally seeded by source q0). Confirm source q0 seeds them; if yes reuse, else add.
- `cka-rbac-csr-binding-fix` (ex7,8): needs `rbac-learn` ns + the CSR (from q7_setup) + the broken binding (from q8_setup). Its q0 must run what q7_setup and q8_setup did. The per-question `setup` fields on the new ex1/ex2 still fire too — avoid double-seeding conflicts (idempotent or move seeding entirely to q0 and drop the per-q setup).

- [ ] **Step 3: Verify each new lab passes in isolation (live)**

For each new lab: `kindlab reset` (clean cluster), then run the lab's solutions and `kindlab check <id>`, OR use the existing solutions to drive it. Minimum bar: `node bin/kindlab.js check <id>` after applying each exercise's `solution` produces all-checks-pass. Record the check output.

Run (per lab): `export KUBECONFIG=/Users/ayodeji/Workspace/kindlab/.state/kubeconfig && node bin/kindlab.js check cka-rbac-basics`
Expected: every check ✅ (after solutions applied).

- [ ] **Step 4: Confirm grouping still green + delete the source**

Run: `node --test` (lab-metadata + web-mirror tests must still pass — the 3 new labs are tagged, the source is gone).
Then: `git rm -r labs/learn-cka-rbac`.
Run: `node bin/kindlab.js list` → the three rbac scenarios appear under the RBAC shelf; `learn-cka-rbac` is gone.

- [ ] **Step 5: Commit**

```bash
git add scripts/slice-cka.js labs/cka-rbac-basics labs/cka-rbac-sa-leastpriv labs/cka-rbac-csr-binding-fix
git rm -r labs/learn-cka-rbac
git commit -m "feat(labs): slice CKA rbac into 3 bite-sized scenarios"
```

---

### Tasks 3–10: Slice the remaining CKA labs (one task per source mega-lab)

Each task follows **exactly the Task 2 shape** — materialize via `node scripts/slice-cka.js <sourceId>`, hand-author each child's reseed `q0_setup.sh`, verify each child passes `kindlab check` live, confirm `node --test` green, `git rm` the source, commit. The per-lab reseed specifics differ; each task's reseed step names them.

- [ ] **Task 3: `learn-cka-clusterops` → 3** (`-staticpod-etcd` 1,3 · `-node-maint` 4,5,6,7 · `-cp-repair` 2,8 [TS]).
  Reseed notes: ex2 & ex8 each have their own `q<N>_setup.sh` (break a control-plane component) — carry them. `-node-maint` (4,5,6,7: taint/drain/uncordon/label) — ex6 uncordon needs the node cordoned first; source q6_setup did that — fold into q0. **This lab mutates nodes: `kindlab reset` before verify.**
- [ ] **Task 4: `learn-cka-cni` → 3** (`-fundamentals` 1,2,4 · `-expose` 5,6,7,8 · `-nodefix` 3 [TS]).
  Reseed: `-expose` (5,6,7,8) assumes Deployment `web` (3 replicas, `app=web`) in `cni-learn` that source q0 seeded — carry into q0. `-nodefix` (ex3) has its own `q3_setup.sh` (breaks CNI on a node) — carry; **node mutation, reset before verify.**
- [ ] **Task 5: `learn-cka-etcd-restore` → 2** (`-backup-restore` 1,2,3,4,8 · `-manifest-fix` 5,6,7 [TS]).
  Reseed: both operate on live etcd. `-backup-restore` ex1 has source q0 (seeds a key to prove snapshot). `-manifest-fix` (5,6,7) is read-only inspection + a bad-backup fix — ex7 needs the `/opt/snap-bad.db` artifact; find where source seeded it and reproduce in q0. **Control-plane sensitive: reset before verify.**
- [ ] **Task 6: `learn-cka-gateway-api` → 3** (`-standup` 1,2,3 · `-routing` 4,5,6,7 · `-vs-ingress-fix` 8,9 [TS]).
  Reseed: ex1 installs the CRDs (source q0 stages the manifest at `/tmp/gateway-api`). `-routing` (4,5,6,7) assumes CRDs+GatewayClass+Gateway from 1,2,3 exist → q0 must install CRDs and create class `kindlab-gc` + Gateway `web-gw` + backend. `-vs-ingress-fix` ex9 has `q9_setup.sh` (broken route) — carry; also needs the Gateway to attach to.
- [ ] **Task 7: `learn-cka-kubeadm` → 3** (`-inspect` 1,2,3 · `-join-certs` 4,6 · `-upgrade-diag` 5,7,8 [TS]).
  Reseed: ex4/5/6/8 each have their own `q<N>_setup.sh` — carry each to its child. `-join-certs` (4,6): ex4 join-command gen, ex6 cert renewal — both self-contained via their setups. **Cert/node mutation: reset before verify.**
- [ ] **Task 8: `learn-cka-multicluster` → 2** (`-contexts` 1,2,3,4,5,6,8 · `-wrongcluster-fix` 7 [TS]).
  **Both children set `needsSecondCluster: true`.** `-wrongcluster-fix` (ex7) needs the stray `cache` Deployment on the wrong cluster — source seeded it (check q0 or a per-q setup); reproduce in q0. Verify with `kindlab cluster2 up` first.
- [ ] **Task 9: `learn-cka-scheduling` → 3** (`-selectors-taints` 1,2,5 · `-affinity` 3,4,7 · `-daemonset-fix` 6,8 [TS]).
  Reseed: source q0 seeds ns `sched-learn` + node labels (`tier=gold` for ex3). Each child's q0 must set the node labels its exercises reference (ex1 labels `disktype=ssd`; ex3 needs `tier=gold` pre-set). `-daemonset-fix` ex8 (unschedulable pod) — reproduce its broken Deployment in q0. **Node-label mutation: reset/clean labels before verify.**
- [ ] **Task 10: `learn-cka-storage` → 3** (`-static` 2,3,4,5 · `-dynamic` 1,6,7 · `-pvc-fix` 8 [TS]).
  Reseed: ns `storage-learn`. `-static` (2,3,4,5) builds PV→PVC→pod→subPath chain — self-contained once ns exists. `-dynamic` (1,6,7): ex1 creates SC `fast-local`, ex6 marks it default, ex7 dynamic-provisions — ex6/7 assume the SC from ex1, which IS in this lab (ids 1,6,7 together) so fine. `-pvc-fix` (ex8) needs the broken `broken-pvc` — reproduce in q0.

Each of Tasks 3–10 ends with the Task 2 five-step cycle and a commit `feat(labs): slice CKA <topic> into N bite-sized scenarios`.

---

### Task 11: Final CKA sweep

**Files:** none new — verification + cleanup.

- [ ] **Step 1: Confirm all 9 source mega-labs are gone and 25 new labs exist**

Run: `ls labs | grep '^learn-cka-'` → empty. `ls labs | grep '^cka-' | grep -v 'clusterops$\|nodeops$'` → 25 new labs (+ the 2 untouched exam labs).

- [ ] **Step 2: Full suite + metadata integrity**

Run: `node --test` → all pass (metadata test confirms every new lab has valid certs + canonical topics + lands on a shelf; web-mirror test green).

- [ ] **Step 3: Browse check**

Run: `node bin/kindlab.js list` → every CKA topic shelf (RBAC, Scheduling, Storage, Cluster Operations, CNI, Networking, Services, ETCD, Gateway API, Kubeadm, Multicluster) shows its small named scenarios; Troubleshooting shelf holds the 9 `[TS]` fix labs; no `learn-cka-*` remains.

- [ ] **Step 4: Live smoke on 3 representative labs**

Run `kindlab check` (after solutions) on one simple (`cka-rbac-basics`), one chained (`cka-storage-static`), one troubleshooting (`cka-rbac-csr-binding-fix`) — all green. Record output.

- [ ] **Step 5: Commit any sweep fixes**

```bash
git add -A && git commit -m "chore(labs): CKA slice sweep — all mega-labs retired"
```

---

## Notes for the follow-on (out of scope here)

CKAD (14 mega → ~31) and CKS (9 mega → ~23) use the SAME `lib/slice-lab.js` helper and the SAME per-lab cycle; only the cut tables (in the spec split map) and reseed specifics differ. They are separate plans dispatched after this pilot proves the pattern. `scripts/slice-cka.js` is the template for `slice-ckad.js`/`slice-cks.js`.
