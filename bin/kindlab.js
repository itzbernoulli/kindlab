#!/usr/bin/env node
/*
 * KindLab — a kind-based CKA/CKS practice bench.
 *
 * Unlike CK-X (single k3d cluster, no node access), KindLab runs a real
 * multi-node kind cluster. Setup and validation scripts can `docker exec`
 * into nodes, so node-level tasks (etcd, static pods, kubelet, audit,
 * kube-bench, seccomp) become gradable.
 *
 * Zero dependencies — only Node built-ins. Run: node bin/kindlab.js <cmd>
 */
'use strict';
const { execSync, spawnSync } = require('child_process');
const fs = require('fs');
const path = require('path');
const http = require('http');

const ROOT = path.resolve(__dirname, '..');
const LABS_DIR = path.join(ROOT, 'labs');
const WEB_DIR = path.join(ROOT, 'web');
const STATE_DIR = path.join(ROOT, '.state');
const KIND_CFG = path.join(ROOT, 'kind', 'cluster.yaml');
const CLUSTER = 'kindlab';
const CTX = `kind-${CLUSTER}`;
const KUBECONFIG = path.join(STATE_DIR, 'kubeconfig');
const SECOND = 'kindlab2';
const CTX2 = `kind-${SECOND}`;
const KIND_CFG2 = path.join(ROOT, 'kind', 'cluster2.yaml');

const C = {
  reset: '\x1b[0m', bold: '\x1b[1m', dim: '\x1b[2m',
  red: '\x1b[31m', green: '\x1b[32m', yellow: '\x1b[33m',
  blue: '\x1b[34m', cyan: '\x1b[36m', gray: '\x1b[90m',
};
const paint = (s, c) => `${C[c]}${s}${C.reset}`;

function ensureState() { fs.mkdirSync(STATE_DIR, { recursive: true }); }

// ---- exam timer ----
function examFile(id) { return path.join(STATE_DIR, `${id}.exam.json`); }
function startExam(id, minutes) {
  ensureState();
  fs.writeFileSync(examFile(id), JSON.stringify({ startedAt: Date.now(), durationSec: Math.round(minutes * 60) }));
}
function clearExam(id) { try { if (fs.existsSync(examFile(id))) fs.unlinkSync(examFile(id)); } catch (e) {} }
function examInfo(id) {
  const f = examFile(id);
  if (!fs.existsSync(f)) return { timed: false };
  const e = JSON.parse(fs.readFileSync(f, 'utf8'));
  const elapsedSec = Math.floor((Date.now() - e.startedAt) / 1000);
  const remainingSec = Math.max(0, e.durationSec - elapsedSec);
  return { timed: true, durationSec: e.durationSec, elapsedSec, remainingSec, expired: remainingSec <= 0 };
}
function fmtDur(sec) { const m = Math.floor(sec / 60), s = sec % 60; return `${m}:${String(s).padStart(2, '0')}`; }

function sh(cmd, opts = {}) {
  // Run a shell command, inheriting stdio by default.
  return execSync(cmd, { stdio: 'inherit', ...opts });
}
function cap(cmd, timeoutMs = 20000) {
  // Run and capture, never throw. Bounded so a wedged kubectl/kind call can't
  // hang the (single-threaded) server forever — on timeout we return code 124.
  try { return { code: 0, out: execSync(cmd, { encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'], timeout: timeoutMs }).trim() }; }
  catch (e) { return { code: e.signal ? 124 : (e.status || 1), out: ((e.stdout || '') + (e.stderr || '')).toString().trim() }; }
}

// Fast, bounded check that the active cluster's API server is actually answering.
// Prevents a recovering/slow apiserver from freezing start/grade for minutes.
function apiHealthy() {
  const r = cap(`KUBECONFIG=${KUBECONFIG} kubectl get --raw=/readyz --request-timeout=5s 2>/dev/null`, 8000);
  return r.code === 0 && /ok/i.test(r.out);
}

function clusterExists() {
  const r = cap('kind get clusters 2>/dev/null');
  return r.out.split('\n').map(s => s.trim()).includes(CLUSTER);
}
function nodeNames() {
  const r = cap(`kind get nodes --name ${CLUSTER} 2>/dev/null`);
  return r.out ? r.out.split('\n').map(s => s.trim()).filter(Boolean) : [];
}
function nodeEnv() {
  const nodes = nodeNames();
  const cp = nodes.find(n => n.endsWith('control-plane')) || `${CLUSTER}-control-plane`;
  const workers = nodes.filter(n => !n.endsWith('control-plane'));
  return {
    LAB_DIR: '', CTX, CTX2, CLUSTER, KUBECONFIG,
    CP: cp, CP2: `${SECOND}-control-plane`, WORKERS: workers.join(' '),
    W1: workers[0] || '', W2: workers[1] || '',
    PATH: process.env.PATH,
  };
}

// ---- second cluster (multi-cluster labs) ----
function secondExists() { return cap('kind get clusters 2>/dev/null').out.split('\n').map(s => s.trim()).includes(SECOND); }
function mergeKube() {
  // Write a merged kubeconfig containing every kind cluster's context.
  // Build to a temp file and only replace the live one if it has a context —
  // so a mid-operation hiccup can never leave an EMPTY kubeconfig behind.
  const clusters = cap('kind get clusters 2>/dev/null').out.split('\n').map(s => s.trim()).filter(Boolean);
  if (!clusters.length) return;
  const files = [];
  for (const c of clusters) { const f = path.join(STATE_DIR, `kc_${c}`); cap(`kind get kubeconfig --name ${c} > ${f}`); files.push(f); }
  const tmp = path.join(STATE_DIR, 'kubeconfig.tmp');
  cap(`KUBECONFIG=${files.join(':')} kubectl config view --flatten > ${tmp}`);
  const hasCtx = cap(`KUBECONFIG=${tmp} kubectl config get-contexts -o name 2>/dev/null`).out.trim();
  if (hasCtx) {
    // preserve the current context if the live file already has a valid one
    const cur = fs.existsSync(KUBECONFIG) ? cap(`KUBECONFIG=${KUBECONFIG} kubectl config current-context 2>/dev/null`).out.trim() : '';
    cap(`mv ${tmp} ${KUBECONFIG}`);
    if (cur && hasCtx.split('\n').includes(cur)) cap(`KUBECONFIG=${KUBECONFIG} kubectl config use-context ${cur} >/dev/null 2>&1`);
    else cap(`KUBECONFIG=${KUBECONFIG} kubectl config use-context ${CTX} >/dev/null 2>&1`);
  }
  for (const f of files) cap(`rm -f ${f}`);
  cap(`rm -f ${tmp}`);
}
function ensureSecond() {
  if (!secondExists()) { console.log(paint(`Creating second cluster '${SECOND}' (for multi-cluster practice)...`, 'cyan')); sh(`kind create cluster --name ${SECOND} --config ${KIND_CFG2}`); }
  mergeKube();
}

function loadLabs() {
  if (!fs.existsSync(LABS_DIR)) return [];
  return fs.readdirSync(LABS_DIR)
    .filter(d => fs.existsSync(path.join(LABS_DIR, d, 'lab.json')))
    .map(d => {
      const lab = JSON.parse(fs.readFileSync(path.join(LABS_DIR, d, 'lab.json'), 'utf8'));
      lab._dir = path.join(LABS_DIR, d);
      return lab;
    })
    .sort((a, b) => (a.id > b.id ? 1 : -1));
}
function getLab(id) {
  const lab = loadLabs().find(l => l.id === id);
  if (!lab) { console.error(paint(`Lab '${id}' not found.`, 'red')); process.exit(1); }
  return lab;
}

function requireCluster() {
  if (!clusterExists()) {
    console.error(paint(`No kind cluster '${CLUSTER}'. Run:  kindlab up`, 'red'));
    process.exit(1);
  }
  // Pin a merged kubeconfig (all kind clusters' contexts) for everything downstream.
  mergeKube();
}

function runScript(lab, rel, extraEnv = {}) {
  const file = path.join(lab._dir, rel);
  if (!fs.existsSync(file)) return { code: 0, out: '', skipped: true };
  const env = { ...process.env, ...nodeEnv(), LAB_DIR: lab._dir, ...extraEnv };
  const r = spawnSync('bash', [file], { encoding: 'utf8', env, timeout: 120000 });
  return { code: r.status == null ? 1 : r.status, out: ((r.stdout || '') + (r.stderr || '')).trim() };
}

// ---------------- commands ----------------

// Stop the CK-X Simulator stack if it's running. Two Kubernetes stacks on Docker
// Desktop starve each other's etcd (I/O thrash), so KindLab takes the machine when
// it starts. Matches the ckx-* compose containers plus CK-X's own `kind-cluster`.
function stopConflicting() {
  const ids = cap(`docker ps -q --filter name=ckx- --filter name=kind-cluster`).out
    .split('\n').map(s => s.trim()).filter(Boolean);
  if (!ids.length) return;
  console.log(paint(`Stopping CK-X Simulator (${ids.length} container(s)) so KindLab has the resources...`, 'yellow'));
  cap(`docker stop ${ids.join(' ')}`, 120000);
}

function dockerRunning() {
  return cap('docker info --format "{{.ServerVersion}}" 2>/dev/null', 20000).code === 0;
}

// Remove bogus flags a half-finished cluster-ops lab injected into the control-plane
// static-pod manifests — they crash-loop the scheduler/controller-manager and block
// pod creation cluster-wide (every lab shares one cluster). Returns the repaired files.
function healControlPlane() {
  const cp = `${CLUSTER}-control-plane`;
  const fixed = [];
  if (!clusterExists()) return fixed;
  for (const m of ['kube-scheduler.yaml', 'kube-controller-manager.yaml', 'kube-apiserver.yaml']) {
    const p = `/etc/kubernetes/manifests/${m}`;
    if (cap(`docker exec ${cp} grep -q bogus ${p} 2>/dev/null`, 10000).code === 0) {
      cap(`docker exec ${cp} sed -i '/--bogus-flag=true/d' ${p}`, 10000);
      fixed.push(m);
    }
  }
  return fixed;
}

function cmdUp() {
  ensureState();
  if (!dockerRunning()) {
    console.log(paint("\n  Docker isn't running — start it, then retry `kindlab up`.", 'yellow'));
    console.log(paint('    macOS:  open -a Docker    (wait until `docker info` succeeds)', 'dim'));
    console.log(paint('    Linux:  sudo systemctl start docker\n', 'dim'));
    process.exit(1);
  }
  stopConflicting();
  if (clusterExists()) { console.log(paint(`Cluster '${CLUSTER}' already up.`, 'green')); }
  else {
    console.log(paint(`Creating kind cluster '${CLUSTER}' (1 control-plane + 2 workers)...`, 'cyan'));
    sh(`kind create cluster --name ${CLUSTER} --config ${KIND_CFG}`);
  }
  mergeKube();
  console.log(paint(`\nReady. Nodes:`, 'green'));
  sh(`KUBECONFIG=${KUBECONFIG} kubectl get nodes`);
  console.log(paint(`\nNode shell:  docker exec -it ${CLUSTER}-control-plane bash`, 'dim'));
  console.log(paint(`Kubeconfig:  export KUBECONFIG=${KUBECONFIG}   (or: kubectl --context ${CTX})`, 'dim'));
  console.log(paint(`Multi-cluster labs:  kindlab cluster2 up   (adds context ${CTX2})`, 'dim'));
}

function cmdDown() {
  let any = false;
  if (clusterExists()) { sh(`kind delete cluster --name ${CLUSTER}`); any = true; }
  if (secondExists()) { sh(`kind delete cluster --name ${SECOND}`); any = true; }
  if (!any) console.log('Nothing to delete.');
}

function cmdCluster2(action) {
  if (action === 'down') {
    if (secondExists()) { sh(`kind delete cluster --name ${SECOND}`); mergeKube(); console.log(paint(`Second cluster '${SECOND}' deleted.`, 'green')); }
    else console.log('No second cluster to delete.');
    return;
  }
  ensureSecond();
  console.log(paint(`\nSecond cluster ready. Contexts available:`, 'green'));
  sh(`KUBECONFIG=${KUBECONFIG} kubectl config get-contexts -o name`);
}

function cmdReset() {
  console.log(paint('Recreating a clean cluster...', 'cyan'));
  if (clusterExists()) sh(`kind delete cluster --name ${CLUSTER}`);
  sh(`kind create cluster --name ${CLUSTER} --config ${KIND_CFG}`);
  cap(`kind get kubeconfig --name ${CLUSTER} > ${KUBECONFIG}`);
  console.log(paint('Clean cluster ready.', 'green'));
}

const labType = (l) => (l.type === 'learn' ? 'learn' : 'exam');

function cmdList() {
  const labs = loadLabs();
  if (!labs.length) { console.log('No labs found.'); return; }
  const row = (l) => `    ${labType(l) === 'learn' ? '📘' : '📝'} ${paint(l.id.padEnd(22), 'cyan')} ${l.name}  ${paint(`(${(l.questions || []).length} ${labType(l) === 'learn' ? 'steps' : 'tasks'})`, 'dim')}`;
  for (const cert of ['CKAD', 'CKA', 'CKS', 'Other']) {
    const inCert = labs.filter(l => l.category === cert);
    if (!inCert.length) continue;
    console.log(paint(`\n  ══ ${cert} ══`, 'bold'));
    inCert.filter(l => labType(l) === 'learn').forEach(l => console.log(row(l)));
    inCert.filter(l => labType(l) === 'exam').forEach(l => console.log(row(l)));
  }
  console.log(paint('\n  📘 learn <id> → check <id>      📝 exam <id> [min] → grade <id>\n', 'dim'));
}

function cmdTasks(id) {
  const lab = getLab(id);
  console.log(paint(`\n  ${lab.name}  ${paint(`[${lab.category}]`, 'gray')}`, 'bold'));
  if (lab.objective) console.log(paint(`  🎯 ${lab.objective}`, 'cyan'));
  console.log('');
  for (const q of lab.questions) {
    const marks = (q.verification || []).reduce((s, v) => s + Number(v.weightage), 0);
    console.log(paint(`  ─ Task ${q.id}: ${q.title}  (${marks} marks)`, 'yellow'));
    console.log(q.prompt.split('\n').map(l => '    ' + l).join('\n'));
    console.log('');
  }
}

function cmdStart(id, minutes) {
  requireCluster();
  const lab = getLab(id);
  if (lab.needsSecondCluster) ensureSecond();
  if (lab.id !== 'learn-cka-clusterops') healControlPlane();   // undo a leftover cluster-ops break
  console.log(paint(`\nPreparing '${lab.name}'...`, 'cyan'));
  // run q0 (optional global setup) then each question's setup
  const setups = ['setup/q0_setup.sh', ...lab.questions.map(q => q.setup).filter(Boolean)];
  for (const s of setups) {
    const r = runScript(lab, s);
    if (r.skipped) continue;
    if (r.code !== 0) console.log(paint(`  setup ${s} warning: ${r.out.split('\n')[0]}`, 'yellow'));
  }
  console.log(paint('Environment ready.\n', 'green'));
  clearExam(id);
  if (minutes && minutes > 0) {
    startExam(id, minutes);
    console.log(paint(`  ⏱  EXAM MODE: ${minutes} minutes — grade before time runs out.  (kindlab status ${id})\n`, 'yellow'));
  }
  cmdTasks(id);
  console.log(paint(`  Grade when done:  kindlab grade ${id}`, 'dim'));
}

function cmdStatus(id) {
  getLab(id);
  const ex = examInfo(id);
  if (!ex.timed) { console.log(paint(`No timed exam active for ${id}. Start one:  kindlab start ${id} <minutes>`, 'dim')); return; }
  if (ex.expired) console.log(paint(`⏱  ${id}: TIME EXPIRED (used ${fmtDur(ex.elapsedSec)})`, 'red'));
  else console.log(paint(`⏱  ${id}: ${fmtDur(ex.remainingSec)} remaining  (of ${fmtDur(ex.durationSec)})`, ex.remainingSec < 300 ? 'yellow' : 'cyan'));
}

function cmdDoctor() {
  requireCluster();
  console.log(paint('\n  KindLab doctor — checking the cluster...', 'cyan'));
  console.log(apiHealthy() ? paint('  ✓ API server healthy', 'green')
                           : paint('  ⚠ API server slow/unresponsive — may be recovering; retry in ~30s', 'yellow'));
  const fixed = healControlPlane();
  console.log(fixed.length
    ? paint(`  ✓ removed injected bogus flags from: ${fixed.join(', ')} — control plane recovers in ~15-30s`, 'green')
    : paint('  ✓ no stray bogus flags in control-plane manifests', 'green'));
  const cp = `${CLUSTER}-control-plane`;
  for (const comp of ['kube-apiserver', 'kube-scheduler', 'kube-controller-manager', 'etcd']) {
    const ready = cap(`KUBECONFIG=${KUBECONFIG} kubectl -n kube-system get pod ${comp}-${cp} -o jsonpath='{.status.containerStatuses[0].ready}' 2>/dev/null`).out.trim();
    console.log(`    ${ready === 'true' ? paint('✓', 'green') : paint('…', 'yellow')} ${comp}: ${ready === 'true' ? 'Ready' : (ready || 'starting')}`);
  }
  const cordon = cap(`KUBECONFIG=${KUBECONFIG} kubectl get node ${cp} -o jsonpath='{.spec.unschedulable}' 2>/dev/null`).out.trim();
  if (cordon === 'true') console.log(paint(`  ℹ ${cp} is cordoned — if that's not a lab step: kubectl uncordon ${cp}`, 'dim'));
  console.log('');
}

// ---------------- learn mode ----------------

function cmdLearn(id) {
  requireCluster();
  const lab = getLab(id);
  if (lab.needsSecondCluster) ensureSecond();
  if (lab.id !== 'learn-cka-clusterops') healControlPlane();   // undo a leftover cluster-ops break
  console.log(paint(`\nPreparing lesson '${lab.name}'...`, 'cyan'));
  ['setup/q0_setup.sh', ...lab.questions.map(q => q.setup).filter(Boolean)].forEach(s => runScript(lab, s));
  console.log(paint(`\n  📘 LEARN: ${lab.name}  ${paint(`[${lab.category}]`, 'gray')}`, 'bold'));
  if (lab.objective) console.log(paint(`  🎯 ${lab.objective}`, 'cyan'));
  console.log('');
  for (const q of lab.questions) {
    console.log(paint(`  ─────── Step ${q.id}: ${q.title} ───────`, 'cyan'));
    if (q.teach) console.log('\n' + q.teach.split('\n').map(l => '   ' + l).join('\n'));
    console.log(paint('\n   ▸ Your turn:', 'yellow'));
    console.log(q.prompt.split('\n').map(l => '   ' + l).join('\n') + '\n');
  }
  console.log(paint(`  Check progress:  kindlab check ${id}`, 'dim'));
  console.log(paint(`  Stuck on a step: kindlab solution ${id} <step>\n`, 'dim'));
}

function cmdCheck(id) {
  const lab = getLab(id);
  console.log(paint(`\nChecking '${lab.name}'...`, 'cyan'));
  const res = gradeLab(lab);
  let done = 0;
  for (const q of res.results) {
    const ok = q.score === q.possible;
    if (ok) done++;
    console.log(`  ${ok ? paint('✓', 'green') : paint('○', 'yellow')} Step ${q.id}: ${q.title}`);
    if (!ok) {
      const first = q.checks.find(c => !c.pass);
      if (first && first.reason) console.log(paint(`      · ${first.reason.split('\n')[0]}`, 'red'));
      const qq = lab.questions.find(x => x.id === q.id);
      if (qq && qq.hint) console.log(paint(`      💡 ${qq.hint}`, 'cyan'));
    }
  }
  const color = done === res.results.length ? 'green' : 'yellow';
  console.log(paint(`\n  Progress: ${done}/${res.results.length} steps mastered${done === res.results.length ? '  🎉' : ''}\n`, color));
  if (done !== res.results.length) console.log(paint(`  Reveal a step:  kindlab solution ${id} <step>\n`, 'dim'));
}

function cmdSolution(id, step) {
  const lab = getLab(id);
  const qs = step ? lab.questions.filter(q => q.id === String(step)) : lab.questions;
  if (!qs.length) { console.log(`No step '${step}' in ${id}.`); return; }
  for (const q of qs) {
    console.log(paint(`\n  ── Solution — Step ${q.id}: ${q.title} ──`, 'bold'));
    console.log((q.solution || '(see answers.md)') + '\n');
  }
}

function gradeLab(lab) {
  requireCluster();
  let total = 0, got = 0;
  const results = [];
  for (const q of lab.questions) {
    const qr = { id: q.id, title: q.title, checks: [], score: 0, possible: 0 };
    for (const v of q.verification) {
      const w = Number(v.weightage);
      qr.possible += w; total += w;
      const r = runScript(lab, v.script);
      const pass = r.code === 0;
      const score = pass ? w : 0;
      got += score; qr.score += score;
      qr.checks.push({ description: v.description, pass, weightage: w, reason: pass ? '' : (r.out || 'check failed').slice(0, 600) });
    }
    results.push(qr);
  }
  const pct = total ? Math.round((got / total) * 100) : 0;
  const rank = pct >= 90 ? 'high' : pct >= 70 ? 'medium' : pct >= 50 ? 'low' : 'fail';
  const out = { labId: lab.id, name: lab.name, category: lab.category, got, total, pct, rank, results, at: new Date().toISOString() };
  ensureState();
  fs.writeFileSync(path.join(STATE_DIR, `${lab.id}.result.json`), JSON.stringify(out, null, 2));
  return out;
}

function cmdGrade(id) {
  const lab = getLab(id);
  console.log(paint(`\nGrading '${lab.name}'...`, 'cyan'));
  const res = gradeLab(lab);
  for (const q of res.results) {
    console.log(paint(`\n  Task ${q.id}: ${q.title}  —  ${q.score}/${q.possible}`, 'bold'));
    for (const c of q.checks) {
      const mark = c.pass ? paint('✓', 'green') : paint('✗', 'red');
      console.log(`    ${mark} ${c.description}`);
      if (!c.pass && c.reason) {
        console.log(c.reason.split('\n').map(l => paint('        ' + l, 'red')).join('\n'));
      }
    }
  }
  const color = res.pct >= 70 ? 'green' : res.pct >= 50 ? 'yellow' : 'red';
  console.log(paint(`\n  ═══ Score: ${res.got}/${res.total}  (${res.pct}%)  —  ${res.rank.toUpperCase()} ═══\n`, color));
  const ex = examInfo(id);
  if (ex.timed) {
    const msg = ex.expired
      ? `⏱  TIME EXPIRED — submitted ${fmtDur(ex.elapsedSec)} in (limit ${fmtDur(ex.durationSec)})`
      : `⏱  Time used ${fmtDur(ex.elapsedSec)} / ${fmtDur(ex.durationSec)}  (${fmtDur(ex.remainingSec)} left)`;
    console.log(paint(`  ${msg}\n`, ex.expired ? 'red' : 'cyan'));
  }
  console.log(paint(`  See solutions:  kindlab answers ${id}\n`, 'dim'));
}

// ---------------- timed full mock ----------------
const MOCK_FILE = path.join(STATE_DIR, 'mock.json');
const PASS_BAR = { CKAD: 66, CKA: 66, CKS: 67 }; // approximate official pass marks
function shuffle(a) { const r = a.slice(); for (let i = r.length - 1; i > 0; i--) { const j = Math.floor(Math.random() * (i + 1)); [r[i], r[j]] = [r[j], r[i]]; } return r; }
function clearMock() { try { if (fs.existsSync(MOCK_FILE)) fs.unlinkSync(MOCK_FILE); } catch (e) {} }

function buildMockPool(cert) {
  const pool = [];
  for (const l of loadLabs().filter(l => l.category === cert && labType(l) === 'exam')) {
    for (const q of l.questions) {
      const w = (q.verification || []).reduce((s, v) => s + Number(v.weightage), 0);
      pool.push({ lab: l.id, qid: q.id, title: q.title, prompt: q.prompt, weight: w });
    }
  }
  return pool;
}

function startMock(cert, minutes) {
  cert = (cert || '').toUpperCase();
  if (!PASS_BAR[cert]) return { error: 'cert must be CKAD, CKA, or CKS' };
  let pool = buildMockPool(cert);
  if (!pool.length) return { error: `no exam tasks found for ${cert}` };
  pool = shuffle(pool);
  const mins = minutes && minutes > 0 ? minutes : 120;
  const cache = {}, seeded = new Set();
  for (const t of pool) {
    const lab = cache[t.lab] || (cache[t.lab] = getLab(t.lab));
    if (!seeded.has(t.lab)) { runScript(lab, 'setup/q0_setup.sh'); seeded.add(t.lab); }
    const q = lab.questions.find(x => x.id === t.qid);
    if (q && q.setup) runScript(lab, q.setup);
  }
  const mock = { cert, minutes: mins, startedAt: Date.now(), passBar: PASS_BAR[cert],
    tasks: pool.map((t, i) => ({ n: i + 1, lab: t.lab, qid: t.qid, title: t.title, prompt: t.prompt, weight: t.weight })) };
  ensureState(); fs.writeFileSync(MOCK_FILE, JSON.stringify(mock, null, 2));
  return mock;
}

function mockInfo() {
  if (!fs.existsSync(MOCK_FILE)) return null;
  const m = JSON.parse(fs.readFileSync(MOCK_FILE, 'utf8'));
  const elapsed = Math.floor((Date.now() - m.startedAt) / 1000);
  return { ...m, active: true, elapsedSec: elapsed, remainingSec: Math.max(0, m.minutes * 60 - elapsed), expired: elapsed >= m.minutes * 60 };
}

function gradeMock(m) {
  const cache = {}; let got = 0, poss = 0; const tasks = [];
  for (const t of m.tasks) {
    const lab = cache[t.lab] || (cache[t.lab] = getLab(t.lab));
    const q = lab.questions.find(x => x.id === t.qid);
    let sc = 0, ps = 0;
    for (const v of (q ? q.verification : [])) { const w = Number(v.weightage); ps += w; if (runScript(lab, v.script).code === 0) sc += w; }
    got += sc; poss += ps; tasks.push({ n: t.n, title: t.title, score: sc, possible: ps });
  }
  const pct = poss ? Math.round(got / poss * 100) : 0;
  return { cert: m.cert, got, poss, pct, pass: pct >= m.passBar, passBar: m.passBar, tasks, elapsedSec: m.elapsedSec, minutes: m.minutes, expired: m.expired };
}

function cmdMock(cert, minutes) {
  requireCluster();
  const m = startMock(cert, minutes);
  if (m.error) { console.error(paint('  ' + m.error + '\n  Usage: kindlab mock <CKAD|CKA|CKS> [minutes]', 'red')); process.exit(1); }
  console.log(paint(`\n  🎯 ${m.cert} TIMED MOCK — ${m.tasks.length} tasks · ${m.minutes} min · pass ≥ ${m.passBar}%\n`, 'bold'));
  for (const t of m.tasks) {
    console.log(paint(`  ─ Task ${t.n}: ${t.title}`, 'yellow'));
    console.log(t.prompt.split('\n').map(l => '    ' + l).join('\n') + '\n');
  }
  console.log(paint('  Clock is running. Work in your terminal across all tasks.', 'dim'));
  console.log(paint('  Time check:  kindlab mock-status      Submit:  kindlab submit\n', 'dim'));
}

function cmdMockStatus() {
  const m = mockInfo();
  if (!m) { console.log(paint('No active mock. Start one: kindlab mock <CKAD|CKA|CKS> [min]', 'dim')); return; }
  const body = m.expired ? paint(`TIME EXPIRED (used ${fmtDur(m.elapsedSec)})`, 'red')
    : paint(`${fmtDur(m.remainingSec)} remaining (of ${fmtDur(m.minutes * 60)})`, m.remainingSec < 600 ? 'yellow' : 'cyan');
  console.log(paint(`  🎯 ${m.cert} mock — `, 'bold') + body);
}

function cmdSubmit() {
  const m = mockInfo();
  if (!m) { console.log(paint('No active mock to submit. Start one: kindlab mock <cert> [min]', 'dim')); return; }
  console.log(paint(`\nGrading your ${m.cert} mock...`, 'cyan'));
  const r = gradeMock(m);
  fs.writeFileSync(path.join(STATE_DIR, 'mock.result.json'), JSON.stringify(r, null, 2));
  for (const t of r.tasks) {
    const icon = t.score === t.possible ? paint('✓', 'green') : (t.score ? paint('◐', 'yellow') : paint('✗', 'red'));
    console.log(`  ${icon} Task ${t.n}: ${t.title}  ${paint(`${t.score}/${t.possible}`, 'dim')}`);
  }
  const verdict = r.pass ? paint(`PASS ✅  ${r.pct}% ≥ ${r.passBar}%`, 'green') : paint(`FAIL ❌  ${r.pct}% < ${r.passBar}%`, 'red');
  console.log(paint(`\n  ═══ ${r.cert} MOCK:  ${r.got}/${r.poss} = ${r.pct}%  —  `, 'bold') + verdict + paint('  ═══', 'bold'));
  console.log((r.expired ? paint(`  ⏱ OVER TIME — ${fmtDur(r.elapsedSec)} used (limit ${fmtDur(r.minutes * 60)})`, 'red') : paint(`  ⏱ ${fmtDur(r.elapsedSec)} used of ${fmtDur(r.minutes * 60)}`, 'cyan')) + '\n');
  clearMock();
}

function cmdAnswers(id) {
  const lab = getLab(id);
  const f = path.join(lab._dir, 'answers.md');
  if (!fs.existsSync(f)) { console.log('No answers file.'); return; }
  console.log('\n' + fs.readFileSync(f, 'utf8') + '\n');
}

// ---------------- web dashboard ----------------

function sendJSON(res, obj, code = 200) {
  res.writeHead(code, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify(obj));
}
function serveStatic(res, file) {
  const types = { '.html': 'text/html', '.css': 'text/css', '.js': 'application/javascript' };
  if (!fs.existsSync(file)) { res.writeHead(404); res.end('not found'); return; }
  res.writeHead(200, { 'Content-Type': types[path.extname(file)] || 'text/plain', 'Cache-Control': 'no-cache, no-store, must-revalidate' });
  res.end(fs.readFileSync(file));
}

function cmdServe(port = 8080) {
  stopConflicting();
  const server = http.createServer((req, res) => {
    const url = new URL(req.url, `http://localhost:${port}`);
    const p = url.pathname;
    try {
      if (p === '/' ) return serveStatic(res, path.join(WEB_DIR, 'index.html'));
      if (p === '/app.js' || p === '/styles.css') return serveStatic(res, path.join(WEB_DIR, p.slice(1)));
      if (p === '/api/status') return sendJSON(res, { up: clusterExists(), cluster: CLUSTER, nodes: nodeNames(), kubeconfig: KUBECONFIG, context: CTX, controlPlane: `${CLUSTER}-control-plane` });
      if (p === '/api/labs') return sendJSON(res, loadLabs().map(l => ({ id: l.id, name: l.name, category: l.category, type: labType(l), requiresHost: !!l.requiresHost, tasks: (l.questions || []).length })));
      if (p.startsWith('/api/lab/')) {
        const lab = loadLabs().find(l => l.id === p.split('/')[3]);
        if (!lab) return sendJSON(res, { error: 'not found' }, 404);
        return sendJSON(res, lab);
      }
      if (p.startsWith('/api/answers/')) {
        const lab = loadLabs().find(l => l.id === p.split('/')[3]);
        const f = lab && path.join(lab._dir, 'answers.md');
        return sendJSON(res, { markdown: f && fs.existsSync(f) ? fs.readFileSync(f, 'utf8') : '' });
      }
      if (p.startsWith('/api/result/')) {
        const f = path.join(STATE_DIR, `${p.split('/')[3]}.result.json`);
        return sendJSON(res, fs.existsSync(f) ? JSON.parse(fs.readFileSync(f, 'utf8')) : {});
      }
      if (p.startsWith('/api/exam/')) return sendJSON(res, examInfo(p.split('/')[3]));
      if (p === '/api/mock') return sendJSON(res, mockInfo() || { active: false });
      if (req.method === 'POST' && p === '/api/mock/start') {
        if (!clusterExists()) return sendJSON(res, { error: 'cluster down — run `kindlab up`' }, 409);
        cap(`kind get kubeconfig --name ${CLUSTER} > ${KUBECONFIG}`);
        const m = startMock(url.searchParams.get('cert'), Number(url.searchParams.get('minutes') || 0));
        return sendJSON(res, m, m.error ? 400 : 200);
      }
      if (req.method === 'POST' && p === '/api/mock/submit') {
        const m = mockInfo(); if (!m) return sendJSON(res, { error: 'no active mock' }, 404);
        if (!clusterExists()) return sendJSON(res, { error: 'cluster down' }, 409);
        const r = gradeMock(m); fs.writeFileSync(path.join(STATE_DIR, 'mock.result.json'), JSON.stringify(r, null, 2));
        clearMock();
        return sendJSON(res, r);
      }
      if (req.method === 'POST' && p === '/api/mock/abort') { clearMock(); return sendJSON(res, { ok: true }); }
      if (req.method === 'POST' && p.startsWith('/api/start/')) {
        const lab = loadLabs().find(l => l.id === p.split('/')[3]);
        if (!lab) return sendJSON(res, { error: 'not found' }, 404);
        if (!clusterExists()) return sendJSON(res, { error: 'cluster down — run `kindlab up`' }, 409);
        if (lab.needsSecondCluster) ensureSecond(); else mergeKube();
        if (!apiHealthy()) return sendJSON(res, { error: 'Cluster API is not responding yet — it may be recovering from load. Wait ~30s and press Start again.' }, 503);
        if (lab.id !== 'learn-cka-clusterops') healControlPlane();   // undo a leftover cluster-ops break so pods can schedule
        ['setup/q0_setup.sh', ...lab.questions.map(q => q.setup).filter(Boolean)].forEach(s => runScript(lab, s));
        const minutes = Number(url.searchParams.get('minutes') || 0);
        clearExam(lab.id);
        if (minutes > 0) startExam(lab.id, minutes);
        return sendJSON(res, { ok: true, timed: minutes > 0, minutes });
      }
      if (req.method === 'POST' && p.startsWith('/api/grade/')) {
        const lab = loadLabs().find(l => l.id === p.split('/')[3]);
        if (!lab) return sendJSON(res, { error: 'not found' }, 404);
        if (!clusterExists()) return sendJSON(res, { error: 'cluster down — run `kindlab up`' }, 409);
        mergeKube();
        if (!apiHealthy()) return sendJSON(res, { error: 'Cluster API is not responding yet — try again in a moment.' }, 503);
        return sendJSON(res, gradeLab(lab));
      }
      if (req.method === 'POST' && p.startsWith('/api/clear/')) {
        const id = p.split('/')[3].replace(/[^a-z0-9-]/gi, '');
        const f = path.join(STATE_DIR, `${id}.result.json`);
        if (id && fs.existsSync(f)) fs.unlinkSync(f);
        return sendJSON(res, { ok: true });
      }
      if (req.method === 'POST' && p === '/api/clear-all') {
        let n = 0;
        for (const f of fs.readdirSync(STATE_DIR)) {
          if (f.endsWith('.result.json')) { fs.unlinkSync(path.join(STATE_DIR, f)); n++; }
        }
        return sendJSON(res, { ok: true, cleared: n });
      }
      res.writeHead(404); res.end('not found');
    } catch (e) { sendJSON(res, { error: String(e) }, 500); }
  });
  server.on('error', (err) => {
    if (err.code === 'EADDRINUSE') {
      console.log(paint(`\n  Port ${port} is already in use — the dashboard is probably already running.`, 'yellow'));
      console.log(paint(`  Open it:        http://localhost:${port}`, 'dim'));
      console.log(paint(`  Or free it:     lsof -ti tcp:${port} | xargs kill`, 'dim'));
      console.log(paint(`  Or use a port:  kindlab serve ${Number(port) + 1}\n`, 'dim'));
      process.exit(1);
    }
    throw err;
  });
  server.listen(port, () => {
    console.log(paint(`\n  KindLab dashboard → http://localhost:${port}\n`, 'green'));
    console.log(paint(`  (Ctrl+C to stop)\n`, 'dim'));
  });
}

// ---------------- dispatch ----------------

const [cmd, arg] = process.argv.slice(2);
const help = `
${C.bold}KindLab${C.reset} — kind-based CKA/CKS practice bench

  kindlab up                 create the multi-node kind cluster
  kindlab down               delete the cluster
  kindlab reset              recreate a clean cluster (between labs)
  kindlab list               list labs
  kindlab tasks <id>         show a lab's tasks
  ${C.bold}Learn${C.reset} (self-paced, lessons + hints):
  kindlab learn <id>         start a learn lab (teaches the section)
  kindlab check <id>         check progress (✓/○ per step + hints)
  kindlab solution <id> <n>  reveal the solution for a step

  ${C.bold}Exam${C.reset} (scored & timed):
  kindlab start <id> [min]   prepare a lab; pass minutes for TIMED EXAM MODE
  kindlab exam <id> [min]    start a timed exam (default 120 min)
  kindlab status <id>        time remaining on a timed exam
  kindlab grade <id>         grade your work (✓/✗ + reasons + score)
  kindlab answers <id>       show model solutions

  ${C.bold}Mock exam${C.reset} (timed, shuffled, pass/fail vs the real bar):
  kindlab mock <cert> [min]  start a full mock — CKAD | CKA | CKS (default 120)
  kindlab mock-status        time remaining
  kindlab submit             submit + PASS/FAIL report card

  ${C.bold}Cluster / UI${C.reset}:
  kindlab up | down | reset  manage the kind cluster
  kindlab cluster2 up|down    add/remove a 2nd cluster (multi-cluster labs)
  kindlab list               list learn labs + exams
  kindlab tasks <id>         show a lab's tasks
  kindlab serve [port]       launch the web dashboard (default 8080)
`;
const arg2 = process.argv[4];
switch (cmd) {
  case 'up': cmdUp(); break;
  case 'down': cmdDown(); break;
  case 'cluster2': cmdCluster2(arg); break;
  case 'reset': cmdReset(); break;
  case 'doctor': case 'heal': cmdDoctor(); break;
  case 'list': cmdList(); break;
  case 'tasks': cmdTasks(arg); break;
  case 'start': cmdStart(arg, arg2 ? Number(arg2) : 0); break;
  case 'exam': cmdStart(arg, arg2 ? Number(arg2) : 120); break;
  case 'status': cmdStatus(arg); break;
  case 'grade': cmdGrade(arg); break;
  case 'answers': cmdAnswers(arg); break;
  case 'learn': cmdLearn(arg); break;
  case 'check': cmdCheck(arg); break;
  case 'solution': cmdSolution(arg, arg2); break;
  case 'mock': cmdMock(arg, arg2 ? Number(arg2) : 0); break;
  case 'mock-status': case 'mockstatus': cmdMockStatus(); break;
  case 'submit': cmdSubmit(); break;
  case 'serve': cmdServe(arg ? Number(arg) : 8080); break;
  default: console.log(help);
}
