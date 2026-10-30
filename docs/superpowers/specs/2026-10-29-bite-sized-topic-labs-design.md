# Bite-sized, topic-organized labs — design

**Date:** 2026-10-29
**Status:** Approved design, ready to plan
**Author:** brainstormed with Claude

## Intent and the why

The kindlab labs don't stick. The owner did CKA/CKAD exam prep on O'Reilly's
interactive labs and remembered them well; the kindlab equivalents, covering the
same material, evaporate. The difference is not that O'Reilly hides answers (it
shows full solutions too, and the owner is fine seeing solutions). The
difference is **portion size and discreteness**:

- O'Reilly's unit is a single **named scenario** — e.g. "CKA Prep: Setting Up
  RBAC for a User" — that is 3 steps, ~15 minutes, with a clear beginning and a
  clear "done." You open it, finish it, close it. The specific story (johndoe /
  pod-reader / read-pods) *is* the memory hook.
- You browse a **shelf** ("Cluster Architecture, Installation, and
  Configuration") holding a handful of these small named labs. You never stare
  at the whole syllabus at once; you pick one small thing.
- kindlab's unit is a **mega-lab** of 7–9 exercises (some 15). You never reach a
  "done," the exercises blur together, and there is no distinct named thing to
  remember.

So the fix is to make the atomic unit a small named scenario, group those
scenarios into topic shelves, and give a browse view that shows shelves with a
few labs each. Retrieval/spacing systems (spaced repetition, quizzes) were
considered and **deliberately dropped** — they are not what made O'Reilly sticky
and the owner did not ask for them.

## Goals

1. **Bite-sized is the atomic unit.** Split the 31 mega-labs into ~78 small
   named scenarios of roughly 2–5 exercises, each independently launchable and
   completable in one sitting with its own "done."
2. **Topic-first organization, with cert as a second real axis.** Browse by
   Kubernetes topic (pods, services, storage, RBAC, networking…). Exam themes
   that have no topic home — chiefly **Troubleshooting** — are their own shelves
   alongside the topics. Separately, the CKA/CKAD/CKS cert framing survives as
   ordered **cert playlists** pointing at the same small labs. Neither axis is a
   tag *on* the other; both are first-class.
3. **A browse/menu view** (playlist feel) in both the web dashboard and the CLI,
   showing shelves with a handful of named labs under each, so the whole
   syllabus is never shown at once.

## Non-goals

- **No spaced-repetition / quiz / self-test system.** Explicitly out of scope.
- **No change to the exercise format itself** (teach / prompt / hint / solution
  / weighted verification stays exactly as is — it works).
- **Not slicing the exam-style and capstone labs** (see "Kept whole" below).
  Their value is breadth-under-pressure or interlocking complexity — the
  opposite of bite-sized.
- **No change to the `kindlab learn/check/solution/exam/mock/reset` command
  verbs** beyond what grouping requires.

## Anti-goals (what would make this a failure even if it "works")

- Shelves so fine-grained that browsing them *is* "seeing the whole syllabus"
  again. Topic shelves should be a readable handful, not 78 flat entries.
- Small labs that can't stand on their own — a lab whose exercises depend on
  state a *different* (now-separate) lab used to build. Every small lab must be
  self-seeding and self-contained (see "The golden-rule constraint").
- Losing the cert playlists. A learner prepping specifically for CKAD must still
  get an ordered CKAD path.

## Constraints

- **The golden-rule constraint (hard).** The framework re-runs *all* of a lab's
  validators on every `check`, so a lab is only sound if one final cluster state
  satisfies every exercise at once. When a split severs a chain where a later
  exercise consumed state an earlier one built, the new lab **must seed that
  state in its own `setup/q0_setup.sh`.** This is the main per-lab labor of the
  slice and must be verified lab-by-lab, not assumed.
- **Zero new runtime dependencies.** The project is a single-file Node CLI
  (`bin/kindlab.js`, ~31KB, no npm deps) plus a static web dashboard
  (`web/app.js`, `index.html`, `styles.css`). Keep it that way.
- **Backward-readable state.** Existing progress state under `.state/` keys on
  `labId`. Renaming/splitting lab ids will orphan old progress; acceptable
  (local, regenerable) but call it out to the user, don't silently wipe.

## Current state (what exists, grounded in the code)

- `labs/<lab-id>/` holds `lab.json` + `setup/q0_setup.sh` + `validate/qN_sM.sh`.
- `lab.json` top-level: `id`, `name`, **`category`** (a single string: `"CKA"` /
  `"CKAD"` / `"CKS"`), `type` (`"learn"` / `"exam"`), `objective`, `description`,
  `questions[]`.
- `bin/kindlab.js:124` loads every `labs/*/lab.json`. Grouping is hardcoded to
  the single `category` string: `labs.filter(l => l.category === cert)` appears
  at `bin/kindlab.js:228,391` and `web/app.js:103`, and the browse loop is a
  literal `for (const cert of ['CKAD','CKA','CKS','Other'])` at `web/app.js:102`.
  `web/styles.css` hardcodes `.cert-CKA/CKAD/CKS` color classes.
- So today **one lab belongs to exactly one cert and no topic.** That single-axis
  assumption is the thing this design replaces.

## The decided design

### 1. Metadata: add two axes, keep the format

Extend `lab.json` with two array fields and keep `category` for back-compat
(derive it from `certs[0]` if absent):

```jsonc
{
  "id": "rbac-user-role",              // new small-lab id (kebab, topic-ish)
  "name": "Set up RBAC for a user",    // O'Reilly-style named scenario
  "topics": ["rbac"],                  // topic shelves this lab sits on
  "certs":  ["CKA"],                   // cert playlists this lab belongs to
  "troubleshooting": false,            // true => also appears on the TS shelf
  "type": "learn",
  "objective": "...",
  "questions": [ /* unchanged schema */ ]
}
```

- **`topics`** drives the topic shelves. A lab may list more than one (e.g. a
  Service lab tagged `["services","networking"]`); its **first** topic is its
  "home" shelf, the rest are cross-listings.
- **`certs`** drives the cert playlists; a single small lab may appear in more
  than one cert (e.g. a Services lab relevant to both CKAD and CKA). A dual-cert
  lab appears in **every** listed cert's playlist *and* mock pool — see
  "`category` and mock-pool behavior" below.
- **`troubleshooting: true`** cross-lists a lab onto the Troubleshooting shelf
  *in addition to* its topic shelf. This is how "troubleshooting has no topic but
  is an exam theme" is expressed without inventing a fake topic.
- A canonical topic + cert list lives in one place (a small map at the top of
  `bin/kindlab.js`, mirrored in `web/app.js`) so shelf order and display names
  are defined once, not scattered. **Shelf and playlist order = declaration
  order in this canonical map** — there is no per-lab ordinal field.

#### Topic shelves (decided: medium grain, ~15 shelves)

Order below is the shelf display order. Each small lab's `topics[0]` is its home
shelf; a lab may cross-list onto others.

`cluster-ops · kubeadm · etcd · rbac · scheduling · workloads · storage ·
config · pod-design · services · networking · observability · network-policy ·
pod-security · supply-chain · hardening · runtime-security · gateway-api ·
multicluster · images · helm-kustomize · crd · quotas · troubleshooting ·
exams`

(That is the full set the split map implies; the builder collapses any that end
up with a single lab into the nearest neighbor so no shelf is a shelf-of-one.
The two pinned shelves are **Troubleshooting** — home of every `[TS]` lab's
cross-listing — and **Exams & Mocks** — home of the kept-whole exam/mock/capstone
labs. These two always render last.)

#### `category` and mock-pool behavior (decided: cert-aware, not `certs[0]`)

`category` is retained as a derived convenience (`= certs[0]` when absent) for
display/CSS only. The **mock pool and cert-playlist membership are made
cert-aware**: a lab belongs to a cert's mock pool if that cert is *in* its
`certs[]` array — not just if it is `certs[0]`. So a `certs: ["CKA","CKAD"]` lab
is eligible for both the CKA and CKAD mocks. This requires rewriting the
`category === cert` filters at `bin/kindlab.js:228,391` and `web/app.js:103` to
`certs.includes(cert)`. Grading-result files (`.state/<id>.result.json`) may
keep writing a single `category` (= `certs[0]`) — grading is per-lab and does not
need the array.

### 2. On-disk layout: flat folders, metadata-driven grouping

Lab folders stay **flat and grouping-neutral** under `labs/`, named by the small
lab's own id (not by cert or topic). Grouping is computed entirely from the
`topics`/`certs` metadata — never from the folder name or a directory tree. This
is what lets one lab live on a topic shelf *and* in two cert playlists without
duplication or symlinks.

The current `learn-<cert>-<topic>` folder names get replaced by scenario ids
(e.g. `rbac-user-role`, `rbac-sa-least-privilege`, `rbac-csr-fix`). Old split-lab
ids are retired; this orphans old `.state/` progress (acceptable, flagged to
user).

**Kept-whole labs keep their existing folder ids** (`cka-clusterops`,
`ckad-exam-1`, `cks-hardening`, etc.). They are not renamed, so their `.state/`
progress survives; only the *split* labs orphan state. Kept-whole labs get
`certs: [...]` but **no `topics`** — they live only on the Exams & Mocks shelf,
never on a topic shelf (they are not bite-sized, so a topic shelf would
misrepresent them).

#### How a split physically happens (the per-lab mechanics)

When mega-lab `M` (folder `labs/M/`) splits into labs `A`, `B`, `C`:

1. Create `labs/A/`, `labs/B/`, `labs/C/`, each a normal lab folder.
2. For each new lab, **copy** the subset of `validate/qN_sM.sh` scripts for the
   exercises it owns, then **renumber** that lab's `questions[]` to `1..n` and
   repath each `verification[].script` to match. Validators hardcode object
   names / namespaces / env vars (not question positions), so copy-and-repath is
   safe and mechanical — no logic edits unless a reseed changes an object name.
3. Author each new lab's `setup/q0_setup.sh`. Where the split severed a state
   chain (the "reseed" notes in the split map), this script must stand up the
   state the original earlier exercises used to build. This is the one step that
   is genuine authoring, not mechanical.
4. Preserve any per-question `setup` fields (some labs, e.g. `learn-cka-rbac`,
   carry extra `setup` on individual questions — carry these with their
   exercise).
5. Delete `labs/M/` once `A/B/C` each pass `kindlab check` in isolation on a
   fresh cluster.

**Revised effort note:** because every split lab touches validators +
`lab.json` renumbering + a reseed script (not just `q0`), the per-lab cost is
higher than a naive read of the split map suggests. Steps 1–2 and 4 are
scriptable; step 3 and the isolation check are hand work. Plan accordingly.

### 3. Browse view (CLI + web)

Both surfaces replace the hardcoded `['CKAD','CKA','CKS']` grouping with a
two-mode browse:

- **By topic (primary/default):** shelves = topics + the Troubleshooting shelf +
  an "Exams & Mocks" shelf. Each shelf lists its small labs by name. This is the
  playlist/menu feel; the full catalog is never dumped flat.
- **By cert:** shelves = CKA / CKAD / CKS, each an ordered playlist of the small
  labs that carry that cert, in a sensible learning order.

CLI: `kindlab list` defaults to by-topic; `kindlab list --cert` (or similar)
switches. Web: a topic/cert toggle at the top of the lab list. Exact command
flag and toggle affordance are left to the builder (minor).

### 4. The split map (the ~78 small labs)

Each source mega-lab splits as below. Exercise ids in brackets refer to the
current `questions[].id`. `[TS]` = carries `troubleshooting: true`. Where a split
severs a state chain, the **reseed** note flags that the new lab's
`q0_setup.sh` must stand up that state itself.

#### CKA — 9 mega → 25 small (2 exam labs kept whole)

- **clusterops (8) → 3:** Static pods & etcd backup `[1,3]` · Node maintenance:
  taint/drain/uncordon/label `[4,5,6,7]` · Repair a control-plane component
  `[2,8]` `[TS]`
- **cni (8) → 3:** How CNI & CoreDNS work `[1,2,4]` · Expose a Deployment:
  ClusterIP/headless/NodePort `[5,6,7,8]` · Node with no CNI config `[3]` `[TS]`
- **etcd-restore (8) → 2:** Back up & restore etcd `[1,2,3,4,8]` · Read etcd's
  manifest + fix a bad backup `[5,6,7]` `[TS]`
- **gateway-api (9) → 3:** Stand up a Gateway `[1,2,3]` · HTTPRoute
  matching/filters/splitting `[4,5,6,7]` · Gateway vs Ingress + fix detached
  route `[8,9]` `[TS]`
- **kubeadm (8) → 3:** Inspect a kubeadm cluster `[1,2,3]` · Join nodes & renew
  certs `[4,6]` · Upgrade/drain/schedule diagnosis `[5,7,8]` `[TS]`
- **multicluster (8) → 2:** Work across two clusters with contexts `[1-6,8]` ·
  Deployment on the wrong cluster `[7]` `[TS]`
- **rbac (8) → 3:** Role & RoleBinding basics `[1,2]` · ServiceAccounts &
  least-privilege `[3,4,5,6]` · Approve a CSR + fix a broken binding `[7,8]` `[TS]`
- **scheduling (8) → 3:** nodeSelector & taints `[1,2,5]` · Node & pod affinity
  `[3,4,7]` · DaemonSets + fix unschedulable pod `[6,8]` `[TS]`
- **storage (8) → 3:** Static PVs & PVCs `[2,3,4,5]` · StorageClasses & dynamic
  provisioning `[1,6,7]` · PVC stuck Pending `[8]` `[TS]`
- **KEEP WHOLE:** `cka-clusterops` (5), `cka-nodeops` (6) — exam-style
  interleaved drills.

#### CKAD — 14 mega → ~31 small (mock + capstone kept whole)

- **config (7) → 2:** env & envFrom `[1,2]` · Mount config:
  volumes/secrets/projection `[3-7]` (ex7 is this lab's capstone, `[TS]`)
- **crd (7) → 2:** Author & create a CRD `[1,2,4,6]` · Work with existing CRDs
  `[3,5,7]` (ex7 `[TS]`). *Reseed:* existing-CRD lab seeds Gizmo/Robot/Sprocket.
- **deploy-ops (8) → 2:** Roll out & roll back `[1,2,3]` · Edit a live Deployment
  in place `[4-8]`. *Also receives* `workloads` ex1 (see below).
- **helm-kustomize (9) → 2:** Package apps with Helm `[1-5]` · Customize with
  Kustomize `[6-9]` (ex9 `[TS]`)
- **images (7) → 2:** Build & modify images `[1,2,3]` · Package & distribute
  `[4-7]`. *Reseed:* distribute-lab must pre-build `myapp:2.0`.
- **labels (7) → 3:** Label & select pods `[1-4]` · Selectors in specs &
  annotations `[5,6]` · Selector that matches nothing `[7]` `[TS]`
- **observability (6) → 2 (both on Troubleshooting shelf):** Diagnose failing
  workloads `[1,2,3,5]` `[TS]` · Inspect a running pod `[4,6]`
- **pod-design (9) → 4:** Multi-container & init `[1,2,3]` · Probes/lifecycle
  `[4,5]` · securityContext/QoS/downward `[6,7,8]` · Won't go Ready `[9]` `[TS]`
- **quotas (8) → 3:** ResourceQuota `[1-4]` · LimitRange `[5,6,7]` · Pod rejected
  by quota `[8]` `[TS]`
- **services-net (8) → 3:** Service types `[1-4]` · Affinity/Ingress/manual
  endpoints `[5,6,7]` · Service with no endpoints `[8]` `[TS]`
- **workloads (8) → 2:** Jobs `[2,3,4,5]` · CronJobs + Job that never runs
  `[6,7,8]` `[TS]`. **ex1 (Deployment strategy/history) moves to the deploy-ops
  topic family** (settled call — it is a 1-step orphan and belongs with
  Deployment mutation).
- **KEEP WHOLE:** `autoscaling` (5), `canary` (5), `modify-assets` (5),
  `serviceaccount` (5) — tight single-scenario arcs already bite-sized.
  `harden-deploy` (1, interlocking capstone), `ckad-exam-1` (15, full mock —
  goes on the "Exams & Mocks" shelf).

#### CKS — 9 mega → 23 small (2 exam labs kept whole)

- **apparmor (8) → 2:** Confine a pod with AppArmor `[1-5]` · Stricter profile
  (deny network) + fix missing profile `[6,7,8]` `[TS]`
- **falco (8) → 3:** Deploy Falco as a DaemonSet `[1,2]` · Write & tune a rule
  `[3-7]` · Fix a broken rule `[8]` `[TS]`
- **hardening (8) → 3:** Harden control plane & kubelets `[1-5]` ·
  Least-privilege RBAC & tokens `[6,7]` · Fix wrong RBAC access `[8]` `[TS]`
- **ingress-tls (7) → 2:** Terminate TLS at the Ingress `[1-5]` · Rotate & repair
  Ingress TLS `[6,7]` `[TS]`
- **kube-bench (7) → 3:** Run kube-bench `[1,2]` · Remediate findings `[3,4,5,6]`
  · Fix a kubelet-config FAIL `[7]` `[TS]`
- **netpol (8) → 3:** Control ingress `[1,2,3,4,7]` · Control egress `[5,6]` ·
  Policy blocking wrong traffic `[8]` `[TS]`
- **podsecurity (8) → 3:** Harden a pod with securityContext `[1-5]` · Restricted
  pod + enforce PSA `[6,7]` · Pod won't start `[8]` `[TS]`
- **runtimeclass (8) → 3:** Create & run a RuntimeClass `[1-4]` · Use in
  workloads `[5,6,7]` · Missing RuntimeClass `[8]` `[TS]`
- **supplychain (8) → 3:** Scan images & manifests `[1,2]` · Pin & trust images
  `[3,4,7]` · Enforce image policy with VAP `[5,6,8]` `[TS]`
- **KEEP WHOLE:** `cks-hardening` (6), `cks-runtime-audit` (6) — scored
  multi-domain exam blocks.

### 5. Settled calls (made during brainstorming, flagged for review)

- **`workloads` ex1** → moved into the deploy-ops topic family rather than left
  as a 1-exercise lab.
- **Troubleshooting shelf membership:** every `[TS]` lab above is cross-listed on
  the Troubleshooting shelf *and* its topic shelf. The two
  `learn-ckad-observability` labs both live under Troubleshooting (one is pure
  break/fix, one is the inspection toolkit break/fix depends on).
- **Capstone/mock/exam labs** go on an "Exams & Mocks" shelf, not a topic shelf.

Resolved after a builder-check review:

- **Topic grain:** medium (~15 shelves, listed in §3) — your call.
- **Dual-cert mock behavior:** a lab appears in every cert's mock pool it lists;
  filters become `certs.includes(cert)` — your call.
- **Validator carry-across:** copy-and-repath + renumber per split lab (§2
  mechanics) — settled.
- **Kept-whole labs:** keep ids, get `certs` but no `topics`, Exams & Mocks shelf
  only — settled.
- **Ordering:** declaration order in the canonical map; no ordinal field —
  settled.

## What's left to the builder

- Exact CLI flag for the topic/cert toggle and the exact web toggle affordance
  (minor).
- Per-lab `q0_setup.sh` authoring for every severed-chain lab (the real labor;
  the reseed notes above say *which* labs need it, not the script contents).
- Writing each small lab's `name`/`objective` and assigning `topics`/`certs`
  values from the map above.
- A one-time migration/validation script that confirms every small lab passes
  its own `check` in isolation on a fresh cluster (enforces the golden-rule
  constraint lab-by-lab).
- Deciding whether to keep a thin compatibility shim so old `category`-based
  state/URLs degrade gracefully, or to document the reset.

## Implementation order (suggested)

1. Metadata + loader/CLI/web grouping change, with the *existing* mega-labs
   re-tagged `topics`/`certs` (no splitting yet) — proves the dual-axis browse
   end to end on real data.
2. Split one representative lab per domain (e.g. rbac, services-net, netpol),
   including reseed scripts + isolation check — proves the slice pattern.
3. Roll the split across the rest, domain by domain.
