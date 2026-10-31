// web/app.js — uses web/grouping.js (browser mirror of lib/grouping.js) for dual-axis browse.
// web/grouping.js must stay in sync with lib/grouping.js (it is the single source of truth).
const $ = (s, r = document) => r.querySelector(s);
const api = (p, opts) => fetch(p, opts).then(r => r.json());
const esc = (s) => String(s).replace(/[&<>"]/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));

let current = null;
let clusterInfo = {};
// Last fetched labs list (cached so re-renders don't refetch)
let cachedLabs = null;

// Click-to-copy: like the exam, clicking an inline `code` token (name,
// namespace, value) in the "Your turn" task box copies it for the terminal.
// Scoped to .task-prompt only — lessons, hints, and solutions don't copy.
document.addEventListener('click', (e) => {
  const c = e.target.closest('.task-prompt code');
  if (!c || c.closest('pre')) return;            // inline code only, not code blocks
  const text = c.textContent;
  if (!navigator.clipboard) return;
  navigator.clipboard.writeText(text).then(() => {
    c.classList.add('copied');
    setTimeout(() => c.classList.remove('copied'), 900);
  }).catch(() => {});
});

// Banner shown on every lab: KindLab has no built-in shell — you work in your own terminal.
function workbench() {
  const kc = clusterInfo.kubeconfig || 'kindlab/.state/kubeconfig';
  const cp = clusterInfo.controlPlane || 'kindlab-control-plane';
  const workers = (clusterInfo.nodes || []).filter(n => n !== cp);
  const w1 = workers[0] || 'kindlab-worker';
  const w2 = workers[1] || 'kindlab-worker2';
  return `<div class="workbench">
    <div class="wb-title">⌨ Work in your own terminal — KindLab checks the cluster, it doesn't host a shell.</div>
    <div class="wb-row">1 · connect once: <code>export KUBECONFIG=${esc(kc)}</code></div>
    <div class="wb-row">2 · node names (so <code>$CP</code>/<code>$W1</code>/<code>$W2</code> in tasks work): <code>export CP=${esc(cp)} W1=${esc(w1)} W2=${esc(w2)}</code></div>
    <div class="wb-row">3 · node shell: <code>docker exec -it ${esc(cp)} bash</code> (or <code>$W1</code>/<code>$W2</code>)</div>
    <div class="wb-row muted">Flow: <b>Start</b> seeds the cluster → do the task in your terminal → <b>Check / Grade</b> here.</div>
  </div>`;
}

// Node toolbox: a collapsed reference for node-level work — the paths and the
// tools (crictl, journalctl, systemctl, etcdctl) you reach for when kubectl
// isn't enough (apiserver down, kubelet won't start). Shown on every lab.
function nodeToolbox() {
  return `<details class="toolbox">
    <summary>🧰 Node toolbox — when <code>kubectl</code> isn't enough, go to the node (crictl · journalctl · systemctl · paths)</summary>
    <div class="tb-body">
      <div class="tb-sec"><div class="tb-h">Get on a node</div>
        <div class="tb-row"><code>docker exec -it $CP bash</code> — exam equivalent: <code>ssh &lt;node&gt;</code> then <code>sudo -i</code>. Nodes: <code>$CP</code> control-plane, <code>$W1</code>/<code>$W2</code> workers.</div>
        <div class="tb-row muted">No vi/nano on kind nodes — edit with <code>sed -i</code> (or <code>apt-get update &amp;&amp; apt-get install -y vim</code>).</div>
      </div>
      <div class="tb-sec"><div class="tb-h">Key paths (on the node)</div>
        <div class="tb-row">static-pod manifests <code>/etc/kubernetes/manifests/</code> · kubeconfigs <code>/etc/kubernetes/*.conf</code> · certs/PKI <code>/etc/kubernetes/pki/</code></div>
        <div class="tb-row">etcd data <code>/var/lib/etcd</code> · kubelet config <code>/var/lib/kubelet/config.yaml</code> · kubelet drop-ins <code>/etc/systemd/system/kubelet.service.d/</code></div>
        <div class="tb-row">CNI config <code>/etc/cni/net.d/</code> · CNI plugins <code>/opt/cni/bin</code> · pod logs <code>/var/log/pods</code> · containerd <code>/etc/containerd/config.toml</code></div>
      </div>
      <div class="tb-sec"><div class="tb-h">crictl — containers when the API / kubectl is down</div>
        <div class="tb-row"><code>crictl ps -a</code> every container (incl. exited) · <code>crictl logs &lt;id&gt;</code> · <code>crictl pods</code> · <code>crictl inspect &lt;id&gt;</code></div>
        <div class="tb-row muted">Endpoint is preconfigured on kind; otherwise <code>crictl --runtime-endpoint unix:///run/containerd/containerd.sock …</code></div>
      </div>
      <div class="tb-sec"><div class="tb-h">kubelet — systemd &amp; logs</div>
        <div class="tb-row"><code>systemctl status kubelet</code> is it running? · <code>journalctl -u kubelet -e --no-pager</code> why it won't start</div>
        <div class="tb-row">after editing its config or unit: <code>systemctl daemon-reload &amp;&amp; systemctl restart kubelet</code></div>
      </div>
      <div class="tb-sec"><div class="tb-h">etcd &amp; certs</div>
        <div class="tb-row"><code>ETCDCTL_API=3 etcdctl --endpoints=https://127.0.0.1:2379 --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/apiserver-etcd-client.crt --key=/etc/kubernetes/pki/apiserver-etcd-client.key member list</code></div>
        <div class="tb-row"><code>kubeadm certs check-expiration</code> · <code>openssl x509 -in &lt;crt&gt; -noout -text -dates</code> · <code>kubeadm token list</code> · <code>kubeadm upgrade plan</code></div>
      </div>
    </div>
  </details>`;
}

// ---- exam countdown ----
let examTick = null, examRemaining = 0, examLab = null;
const fmt = (s) => `${Math.floor(s / 60)}:${String(s % 60).padStart(2, '0')}`;
function renderTimer() {
  const el = $('#examTimer');
  if (examLab == null) { el.style.display = 'none'; return; }
  el.style.display = 'block';
  if (examRemaining <= 0) { el.className = 'exam-timer over'; el.textContent = "⏱ TIME'S UP"; }
  else { el.className = 'exam-timer' + (examRemaining < 300 ? ' warn' : ''); el.textContent = '⏱ ' + fmt(examRemaining); }
}
async function startExamPoll(id) {
  if (examTick) { clearInterval(examTick); examTick = null; }
  examLab = null; renderTimer();
  const resync = async () => {
    const e = await api('/api/exam/' + id);
    if (!e.timed) { examLab = null; if (examTick) { clearInterval(examTick); examTick = null; } renderTimer(); return false; }
    examLab = id; examRemaining = e.remainingSec; renderTimer(); return true;
  };
  if (!(await resync())) return;
  let n = 0;
  examTick = setInterval(async () => {
    examRemaining = Math.max(0, examRemaining - 1);
    renderTimer();
    if (++n % 20 === 0) await resync();           // re-sync with server every 20s
  }, 1000);
}

async function refreshStatus() {
  const s = await api('/api/status');
  clusterInfo = s;
  const el = $('#clusterStatus');
  if (s.up) { el.className = 'status up'; el.textContent = `cluster up · ${s.nodes.length} nodes`; }
  else { el.className = 'status down'; el.textContent = 'cluster down — run `kindlab up`'; }
  return s.up;
}

function renderLabList(labs) {
  if (!labs || labs.length === 0) {
    const list = $('#labList');
    list.innerHTML = '<div class="muted">No labs found.</div>';
    return;
  }
  const list = $('#labList');
  list.innerHTML = '';
  const mockBtn = document.createElement('div');
  mockBtn.className = 'mock-launch';
  mockBtn.innerHTML = '🎯 <span>Timed Mock Exam</span>';
  mockBtn.onclick = () => { document.querySelectorAll('.lab-card').forEach(c => c.classList.remove('active')); openMock(); };
  list.appendChild(mockBtn);
  const resetAll = document.createElement('button');
  resetAll.className = 'reset-all';
  resetAll.textContent = '⟲ Reset all progress';
  resetAll.onclick = async () => {
    if (!confirm('Clear ALL saved scores across every lab? (Your clusters are untouched — this only resets the ✓ marks and mastered badges.)')) return;
    const r = await api('/api/clear-all', { method: 'POST' });
    cachedLabs = null;
    await loadLabs();
    $('#panel').innerHTML = `<div class="muted" style="padding:40px 4px">Cleared ${r.cleared || 0} saved result${(r.cleared === 1) ? '' : 's'}. Pick a lab to begin.</div>`;
  };
  list.appendChild(resetAll);

  const makeCard = (l) => {
    const t = l.type === 'learn' ? 'learn' : 'exam';
    const card = document.createElement('div');
    card.className = `lab-card type-${t} cat-${l.category}`;
    card.id = 'card-' + l.id;
    const unit = t === 'learn' ? 'steps' : 'tasks';
    card.innerHTML = `<div class="name">${esc(l.name)}</div>
      <div class="meta"><span class="type-tag ${t}">${t === 'learn' ? 'Learn' : 'Exam'}</span> · ${l.tasks} ${unit}${l.requiresHost ? ' · <span class="host-tag">needs host</span>' : ''}</div>`;
    card.onclick = () => { document.querySelectorAll('.lab-card').forEach(c => c.classList.remove('active')); card.classList.add('active'); openLab(l.id); };
    return card;
  };

  // Collapsed-section state persists across refreshes, keyed per section id.
  const collapseKey = (id) => `kindlab.collapsed.${id}`;
  const isCollapsed = (id) => localStorage.getItem(collapseKey(id)) === '1';

  // Render one collapsible header into `parent`; returns its (empty) body so the
  // caller can fill it with cards or nested sub-sections.
  const makeCollapsible = (parent, id, headerCls, headerText, count) => {
    const collapsed = isCollapsed(id);
    const h = document.createElement('div');
    h.className = 'lab-section ' + headerCls + (collapsed ? ' collapsed' : '');
    h.innerHTML = `<span class="caret">▾</span><span class="sec-label">${esc(headerText)}</span><span class="sec-count">${count}</span>`;
    parent.appendChild(h);
    const body = document.createElement('div');
    body.className = 'lab-section-body';
    if (collapsed) body.style.display = 'none';
    parent.appendChild(body);
    h.onclick = () => {
      const nowCollapsed = !h.classList.contains('collapsed');
      h.classList.toggle('collapsed', nowCollapsed);
      body.style.display = nowCollapsed ? 'none' : '';
      localStorage.setItem(collapseKey(id), nowCollapsed ? '1' : '0');
    };
    return body;
  };

  // Single view: each cert is a top-level section; inside it, labs are grouped
  // by topic in curriculum (teaching) order. byCertTopic mirrors lib/grouping.js.
  // Dual-cert labs appear under each of their certs.
  for (const { cert, groups } of window.byCertTopic(labs)) {
    const total = groups.reduce((n, g) => n + g.labs.length, 0);
    const certBody = makeCollapsible(list, 'cert:' + cert, 'cert-head cert-' + cert, cert, total);
    for (const g of groups) {
      const topicBody = makeCollapsible(certBody, 'cert:' + cert + ':' + g.key, 'topic-sub topic-' + g.key, g.label || g.key, g.labs.length);
      // Preserve curriculum order — "-fix" labs are intentionally placed last.
      g.labs.forEach(l => topicBody.appendChild(makeCard(l)));
    }
  }

  // Mark already-mastered learn labs from saved results.
  for (const l of labs.filter(l => l.type === 'learn')) {
    api('/api/result/' + l.id).then(r => {
      if (r && r.results && r.results.length) {
        setCardMastered(l.id, r.results.every(q => q.score === q.possible));
      }
    }).catch(() => {});
  }
}

async function loadLabs() {
  if (!cachedLabs) {
    cachedLabs = await api('/api/labs');
  }
  const labs = cachedLabs;
  const list = $('#labList');
  if (!labs.length) { list.innerHTML = '<div class="muted">No labs found.</div>'; return; }
  renderLabList(labs);
}

async function openLab(id) {
  current = id;
  const lab = await api('/api/lab/' + id);
  if ((lab.type || 'exam') === 'learn') return renderLearn(lab);
  return renderExam(lab);
}

async function renderExam(lab) {
  const id = lab.id;
  const panel = $('#panel');
  panel.innerHTML = `
    <h2>${esc(lab.name)}</h2>
    <div class="muted">${esc(lab.category)} · ${lab.questions.length} tasks · ${lab.questions.reduce((s,q)=>s+(q.verification||[]).reduce((a,v)=>a+Number(v.weightage),0),0)} marks</div>
    ${lab.objective ? `<div class="objective cert-${esc(lab.category)}"><span class="obj-eyebrow">Objective</span>${esc(lab.objective)}</div>` : ''}
    ${workbench()}
    ${nodeToolbox()}
    <div class="toolbar">
      <button class="btn-start" id="bStart">▶ Start / Reset (practice)</button>
      <button class="btn-exam" id="bExam">⏱ Start timed exam</button>
      <button class="btn-grade" id="bGrade">✓ Grade</button>
      <button class="btn-answers" id="bAns">Answers</button>
      <button class="btn-answers" id="bClear">⟲ Clear score</button>
    </div>
    <div id="tasks"></div>
    <div id="result"></div>
    <div id="ans"></div>`;

  const tasks = $('#tasks');
  for (const q of lab.questions) {
    const marks = (q.verification || []).reduce((a, v) => a + Number(v.weightage), 0);
    const d = document.createElement('div');
    d.className = 'task';
    d.innerHTML = `<div class="task-head"><span>Task ${esc(q.id)}: ${esc(q.title)}</span><span class="task-score">${marks} marks</span></div>
      <div class="task-body">${marked.parse(q.prompt)}</div>`;
    tasks.appendChild(d);
  }

  $('#bStart').onclick = async (e) => {
    e.target.disabled = true; e.target.textContent = 'Preparing…';
    const r = await api('/api/start/' + id, { method: 'POST' });
    e.target.disabled = false; e.target.textContent = '▶ Start / Reset (practice)';
    if (r.error) alert(r.error); else { $('#result').innerHTML = '<div class="ready-note">✓ Cluster ready — do the tasks in your terminal, then Grade.</div>'; startExamPoll(id); }
  };
  $('#bExam').onclick = async (e) => {
    const m = prompt('Timed exam — minutes:', '120');
    if (!m || isNaN(Number(m))) return;
    e.target.disabled = true; e.target.textContent = 'Starting…';
    const r = await api('/api/start/' + id + '?minutes=' + Number(m), { method: 'POST' });
    e.target.disabled = false; e.target.textContent = '⏱ Start timed exam';
    if (r.error) alert(r.error); else { $('#result').innerHTML = '<div class="ready-note">⏱ Timed exam started — clock is running. Work in your terminal, then Grade before it hits 0.</div>'; startExamPoll(id); }
  };
  $('#bGrade').onclick = async (e) => {
    e.target.disabled = true; e.target.textContent = 'Grading…';
    const res = await api('/api/grade/' + id, { method: 'POST' });
    e.target.disabled = false; e.target.textContent = '✓ Grade';
    if (res.error) { alert(res.error); return; }
    renderResult(res);
  };
  $('#bAns').onclick = async () => {
    const a = await api('/api/answers/' + id);
    $('#ans').innerHTML = `<div class="answers">${marked.parse(a.markdown || '_No answers._')}</div>`;
  };
  $('#bClear').onclick = async () => {
    if (!confirm('Clear the saved score for this exam? (Your cluster work is untouched.)')) return;
    await api('/api/clear/' + id, { method: 'POST' });
    $('#result').innerHTML = '';
  };

  // show last result if any
  const prev = await api('/api/result/' + id);
  if (prev && prev.results) renderResult(prev);

  // resume any running exam timer for this lab
  startExamPoll(id);
}

let curLearnId = null;
// Flag a lab card in the sidebar as mastered (all steps passed).
function setCardMastered(labId, mastered) {
  const card = document.getElementById('card-' + labId);
  if (!card) return;
  card.classList.toggle('mastered', mastered);
  let badge = card.querySelector('.mastered-badge');
  if (mastered && !badge) {
    badge = document.createElement('span');
    badge.className = 'mastered-badge';
    badge.textContent = '✓ Mastered';
    (card.querySelector('.meta') || card).appendChild(badge);
  } else if (!mastered && badge) {
    badge.remove();
  }
}
// Toggle a hint/solution box open/closed from its trigger button.
window.tog = function (btn, showLabel, hideLabel) {
  const box = btn.nextElementSibling;
  if (!box) return;
  const open = box.classList.toggle('open');
  box.style.display = open ? 'block' : 'none';
  btn.textContent = open ? hideLabel : showLabel;
};
async function renderLearn(lab) {
  const id = lab.id;
  curLearnId = id;
  if (examTick) { clearInterval(examTick); examTick = null; } examLab = null; renderTimer();
  const panel = $('#panel');
  panel.innerHTML = `
    <h2>${esc(lab.name)} <span class="learn-badge">LEARN</span></h2>
    <div class="muted">${esc(lab.category)} · ${lab.questions.length} steps · self-paced</div>
    ${lab.objective ? `<div class="objective cert-${esc(lab.category)}"><span class="obj-eyebrow">Objective</span>${esc(lab.objective)}</div>` : ''}
    ${lab.requiresHost ? `<div class="host-warn">⚠ <b>Requires a Linux host</b> — this tool needs BTF/AppArmor, which your Docker Desktop kernel lacks. Learn it here, then run it on your real cluster (or run KindLab's kind under Colima/Linux).</div>` : ''}
    ${workbench()}
    ${nodeToolbox()}
    <div class="toolbar">
      <button class="btn-start" id="bStart">▶ Start / Reset lesson</button>
      <button class="btn-grade" id="bCheck">✓ Check progress</button>
      <button class="btn-answers" id="bClear">⟲ Clear progress</button>
    </div>
    <div class="progress"><div class="progress-fill" id="progFill"></div></div>
    <div class="progress-text muted" id="progText">Start the lesson, work a step, then Check.</div>
    <div id="steps"></div>
    <div class="learn-footerbar">
      <button class="btn-grade" id="bCheckBottom">✓ Check progress</button>
      <span class="progress-text muted" id="progTextBottom">Work a step, then Check — no need to scroll up.</span>
    </div>`;
  const steps = $('#steps');
  for (const q of lab.questions) {
    const d = document.createElement('div');
    d.className = 'task learn-step'; d.id = 'step-' + q.id;
    d.innerHTML = `
      <div class="task-head"><span><span class="step-dot" id="dot-${q.id}">○</span> Step ${esc(q.id)}: ${esc(q.title)}</span></div>
      <div class="task-body">
        ${q.teach ? `<div class="lesson">${marked.parse(q.teach)}</div>` : ''}
        <div class="task-prompt">${marked.parse('**▸ Your turn:** ' + q.prompt)}</div>
        <div class="learn-actions">
          ${q.hint ? `<button class="btn-answers mini" onclick="window.tog(this,'💡 Hint','🙈 Hide hint')">💡 Hint</button><div class="hint" style="display:none">${marked.parse(q.hint)}</div>` : ''}
          ${q.solution ? `<button class="btn-answers mini" onclick="window.tog(this,'Reveal solution','🙈 Hide solution')">Reveal solution</button><div class="solution" style="display:none">${marked.parse('```bash\n' + q.solution + '\n```')}</div>` : ''}
        </div>
        <div class="step-checks" id="checks-${q.id}"></div>
      </div>`;
    steps.appendChild(d);
  }
  $('#bStart').onclick = async (e) => {
    e.target.disabled = true; e.target.textContent = 'Preparing…';
    const r = await api('/api/start/' + id, { method: 'POST' });
    e.target.disabled = false; e.target.textContent = '▶ Start / Reset lesson';
    const pt = $('#progText');
    if (r.error) { alert(r.error); }
    else if (pt) { pt.textContent = '✓ Cluster ready — now do a step in your terminal, then Check.'; pt.className = 'progress-text ok'; }
  };
  const doCheck = async () => {
    const btns = [$('#bCheck'), $('#bCheckBottom')].filter(Boolean);
    btns.forEach(b => { b.disabled = true; b.textContent = 'Checking…'; });
    const res = await api('/api/grade/' + id, { method: 'POST' });
    btns.forEach(b => { b.disabled = false; b.textContent = '✓ Check progress'; });
    if (res.error) { alert(res.error); return; }
    updateLearnProgress(res);
  };
  $('#bCheck').onclick = doCheck;
  $('#bCheckBottom').onclick = doCheck;
  $('#bClear').onclick = async () => {
    if (!confirm('Clear your saved progress for this lesson? (Your cluster work is untouched — this only resets the ✓ marks.)')) return;
    await api('/api/clear/' + id, { method: 'POST' });
    setCardMastered(id, false);
    renderLearn(lab);
  };
  const prev = await api('/api/result/' + id);
  if (prev && prev.results) updateLearnProgress(prev);
}
function updateLearnProgress(res) {
  let done = 0;
  for (const q of res.results) {
    const ok = q.score === q.possible; if (ok) done++;
    const dot = document.getElementById('dot-' + q.id);
    if (dot) { dot.textContent = ok ? '✓' : '○'; dot.className = 'step-dot' + (ok ? ' ok' : ''); }
    const step = document.getElementById('step-' + q.id);
    if (step) step.classList.toggle('done', ok);
    const cc = document.getElementById('checks-' + q.id);
    if (cc && q.checks) {
      const head = q.checks.length > 1 ? `<div class="chk-score">${q.score}/${q.possible} marks — ${q.checks.filter(c => c.pass).length}/${q.checks.length} requirements met</div>` : '';
      cc.innerHTML = head + q.checks.map(c =>
        `<div class="chk ${c.pass ? 'ok' : 'bad'}"><span class="chk-mark">${c.pass ? '✓' : '✗'}</span><span class="chk-desc">${esc(c.description)}${!c.pass && c.reason ? `<div class="chk-reason">${esc(c.reason)}</div>` : ''}</span></div>`
      ).join('');
    }
  }
  const pct = Math.round(done / res.results.length * 100);
  const all = done === res.results.length;
  const label = `${done}/${res.results.length} steps mastered` + (all ? ' 🎉' : '');
  const fill = $('#progFill');
  if (fill) fill.style.width = pct + '%';
  for (const t of [$('#progText'), $('#progTextBottom')]) {
    if (t) { t.textContent = label; t.className = 'progress-text ' + (all ? 'ok' : 'muted'); }
  }
  if (curLearnId) setCardMastered(curLearnId, all);
}

// ---- timed mock exam ----
function stopMockTimer() { if (examTick) { clearInterval(examTick); examTick = null; } examLab = null; renderTimer(); }
async function startMockTimer() {
  if (examTick) { clearInterval(examTick); examTick = null; }
  const resync = async () => {
    const m = await api('/api/mock');
    if (!m || !m.active) { stopMockTimer(); return false; }
    examLab = 'mock'; examRemaining = m.remainingSec; renderTimer(); return true;
  };
  if (!(await resync())) return;
  let n = 0;
  examTick = setInterval(async () => { examRemaining = Math.max(0, examRemaining - 1); renderTimer(); if (++n % 20 === 0) await resync(); }, 1000);
}

async function openMock() {
  current = null;
  const m = await api('/api/mock');
  if (m && m.active) return renderActiveMock(m);
  renderMockChooser();
}

function renderMockChooser() {
  stopMockTimer();
  const panel = $('#panel');
  panel.innerHTML = `
    <h2>🎯 Timed Mock Exam</h2>
    <div class="muted">A full, shuffled, timed run — scored against the real pass mark. Your proof you're ready.</div>
    ${workbench()}
    <div class="mock-setup">
      <div class="mock-field"><label>Exam</label>
        <div class="seg" id="mockCert"><button data-c="CKAD" class="on">CKAD</button><button data-c="CKA">CKA</button><button data-c="CKS">CKS</button></div>
      </div>
      <div class="mock-field"><label>Minutes</label><input id="mockMin" type="number" value="120" min="10" max="240"></div>
      <button class="btn-exam" id="mockStart">⏱ Start mock</button>
    </div>
    <p class="muted mock-note">Pass bars — CKAD 66% · CKA 66% · CKS 67%. Tip: run <code>kindlab reset</code> first for a pristine cluster. Then work every task in your terminal and Submit before the clock hits 0.</p>`;
  let cert = 'CKAD';
  panel.querySelectorAll('#mockCert button').forEach(b => b.onclick = () => { panel.querySelectorAll('#mockCert button').forEach(x => x.classList.remove('on')); b.classList.add('on'); cert = b.dataset.c; });
  $('#mockStart').onclick = async (e) => {
    e.target.disabled = true; e.target.textContent = 'Seeding…';
    const min = Number($('#mockMin').value) || 120;
    const r = await api('/api/mock/start?cert=' + cert + '&minutes=' + min, { method: 'POST' });
    e.target.disabled = false; e.target.textContent = '⏱ Start mock';
    if (r.error) { alert(r.error); return; }
    renderActiveMock(r);
  };
}

function renderActiveMock(m) {
  current = null;
  const panel = $('#panel');
  panel.innerHTML = `
    <h2>🎯 ${esc(m.cert)} Mock <span class="timed-badge">TIMED</span></h2>
    <div class="muted">${m.tasks.length} tasks · ${m.minutes} min · pass ≥ ${m.passBar}%</div>
    ${workbench()}
    ${nodeToolbox()}
    <div class="toolbar"><button class="btn-grade" id="mockSubmit">✓ Submit exam</button><button class="btn-answers" id="mockAbort">Abort</button></div>
    <div id="mockTasks"></div>`;
  const t = $('#mockTasks');
  m.tasks.forEach(q => {
    const d = document.createElement('div'); d.className = 'task';
    d.innerHTML = `<div class="task-head"><span>Task ${q.n}: ${esc(q.title)}</span><span class="task-score">${q.weight} marks</span></div>
      <div class="task-body">${marked.parse(q.prompt)}</div>`;
    t.appendChild(d);
  });
  $('#mockSubmit').onclick = async (e) => {
    if (!confirm('Submit the mock for grading? This ends the attempt.')) return;
    e.target.disabled = true; e.target.textContent = 'Grading…';
    const r = await api('/api/mock/submit', { method: 'POST' });
    e.target.disabled = false; e.target.textContent = '✓ Submit exam';
    if (r.error) { alert(r.error); return; }
    stopMockTimer(); renderMockReport(r);
  };
  $('#mockAbort').onclick = async () => { if (!confirm('Abort this mock?')) return; await api('/api/mock/abort', { method: 'POST' }); stopMockTimer(); renderMockChooser(); };
  startMockTimer();
}

function renderMockReport(r) {
  const panel = $('#panel');
  let html = `
    <h2>🎯 ${esc(r.cert)} Mock — Report</h2>
    <div class="mock-verdict ${r.pass ? 'pass' : 'fail'}">
      <div class="mv-grade">${r.pass ? 'PASS' : 'FAIL'}</div>
      <div class="mv-score">${r.got}/${r.poss} · ${r.pct}%<span class="mv-bar">pass ≥ ${r.passBar}%</span></div>
      <div class="mv-time ${r.expired ? 'over' : ''}">⏱ ${fmt(r.elapsedSec)} used of ${fmt(r.minutes * 60)}${r.expired ? ' — OVER TIME' : ''}</div>
    </div>
    <div class="toolbar"><button class="btn-exam" id="mockNew">⏱ New mock</button></div>`;
  for (const t of r.tasks) {
    const cls = t.score === t.possible ? 'ok' : (t.score ? 'partial' : 'bad');
    const dot = t.score === t.possible ? '✓' : (t.score ? '◐' : '✗');
    html += `<div class="mock-task ${cls}"><span class="mt-dot">${dot}</span><span class="mt-name">Task ${t.n}: ${esc(t.title)}</span><span class="mt-score">${t.score}/${t.possible}</span></div>`;
  }
  panel.innerHTML = html;
  $('#mockNew').onclick = () => renderMockChooser();
}

function renderResult(res) {
  const wrap = $('#result');
  let html = '';
  for (const q of res.results) {
    html += `<div class="task"><div class="task-head"><span>Task ${esc(q.id)}: ${esc(q.title)}</span><span class="task-score">${q.score}/${q.possible}</span></div>`;
    for (const c of q.checks) {
      html += `<div class="check"><div class="desc">${esc(c.description)}${!c.pass && c.reason ? `<div class="reason">${esc(c.reason)}</div>` : ''}</div>
        <div class="mark ${c.pass ? 'ok' : 'bad'}">${c.pass ? '✓' : '✗'}</div></div>`;
    }
    html += '</div>';
  }
  html += `<div class="scorebar ${res.rank}">Score: ${res.got}/${res.total} (${res.pct}%) — ${res.rank.toUpperCase()}</div>`;
  wrap.innerHTML = html;
}

(async function init() {
  await refreshStatus();
  setInterval(refreshStatus, 10000);
  await loadLabs();
})();
