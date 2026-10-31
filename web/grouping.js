// web/grouping.js — browser mirror of lib/grouping.js (CommonJS).
// IMPORTANT: This file must stay in sync with lib/grouping.js.
// Copy TOPICS, CERTS, key constants, and grouping functions verbatim from there.
// It does NOT use require(); values are exposed as window globals so app.js can call them.
/* global window */
'use strict';

// --- TOPICS / CERTS / key constants (verbatim from lib/grouping.js) ---
var TOPICS = [
  { key: 'cluster-ops', label: 'Cluster Operations' },
  { key: 'kubeadm', label: 'Kubeadm' },
  { key: 'etcd', label: 'ETCD' },
  { key: 'rbac', label: 'RBAC' },
  { key: 'scheduling', label: 'Scheduling' },
  { key: 'workloads', label: 'Workloads' },
  { key: 'storage', label: 'Storage' },
  { key: 'config', label: 'Configuration' },
  { key: 'pod-design', label: 'Pod Design' },
  { key: 'services', label: 'Services' },
  { key: 'canary', label: 'Canary Deployments' },
  { key: 'networking', label: 'Networking' },
  { key: 'cni', label: 'CNI' },
  { key: 'observability', label: 'Observability' },
  { key: 'network-policy', label: 'Network Policy' },
  { key: 'pod-security', label: 'Pod Security' },
  { key: 'supply-chain', label: 'Supply Chain' },
  { key: 'hardening', label: 'Hardening' },
  { key: 'runtime-security', label: 'Runtime Security' },
  { key: 'gateway-api', label: 'Gateway API' },
  { key: 'multicluster', label: 'Multicluster' },
  { key: 'images', label: 'Images' },
  { key: 'helm-kustomize', label: 'Helm & Kustomize' },
  { key: 'crd', label: 'CRD' },
  { key: 'quotas', label: 'Quotas' },
  { key: 'labels', label: 'Labels & Selectors' }
];

var CERTS = ['CKAD', 'CKA', 'CKS'];

var TROUBLESHOOTING_KEY = 'troubleshooting';
var EXAMS_KEY = 'exams';
var OTHER_KEY = 'other';

// --- helper functions (verbatim logic from lib/grouping.js) ---

function certOf(lab) {
  return (lab.certs && lab.certs[0] != null) ? lab.certs[0] : (lab.category != null ? lab.category : undefined);
}

function inCert(lab, cert) {
  return (lab.certs ? lab.certs : (lab.category ? [lab.category] : [])).indexOf(cert) !== -1;
}

function byCert(labs) {
  var result = [];
  for (var i = 0; i < CERTS.length; i++) {
    var cert = CERTS[i];
    var matched = labs.filter(function(l) { return inCert(l, cert); });
    if (matched.length > 0) {
      result.push({ cert: cert, labs: matched });
    }
  }
  return result;
}

function byTopic(labs) {
  // Build raw topic shelf map
  var topicMap = {};
  for (var i = 0; i < TOPICS.length; i++) {
    topicMap[TOPICS[i].key] = [];
  }
  for (var j = 0; j < labs.length; j++) {
    var lab = labs[j];
    if (Array.isArray(lab.topics)) {
      for (var k = 0; k < lab.topics.length; k++) {
        var tk = lab.topics[k];
        if (topicMap[tk] !== undefined) {
          topicMap[tk].push(lab);
        }
      }
    }
  }

  // Single-lab collapse rule
  var topicKeys = TOPICS.map(function(t) { return t.key; });
  var collapsedToOther = [];

  for (var ti = 0; ti < topicKeys.length; ti++) {
    var key = topicKeys[ti];
    var shelf = topicMap[key];
    if (shelf.length === 1) {
      var orphan = shelf[0];
      if (orphan.troubleshooting === true) continue;
      var placed = false;
      for (var tj = ti + 1; tj < topicKeys.length; tj++) {
        var nextShelf = topicMap[topicKeys[tj]];
        if (nextShelf.length > 0) {
          nextShelf.push(orphan);
          placed = true;
          break;
        }
      }
      if (!placed) {
        collapsedToOther.push(orphan);
      }
      topicMap[key] = [];
    }
  }

  // Track labs on topic shelves
  var onTopicShelf = [];
  for (var m = 0; m < topicKeys.length; m++) {
    var sl = topicMap[topicKeys[m]];
    for (var n = 0; n < sl.length; n++) {
      if (onTopicShelf.indexOf(sl[n]) === -1) onTopicShelf.push(sl[n]);
    }
  }

  // Troubleshooting shelf
  var troubleshootingLabs = labs.filter(function(l) { return l.troubleshooting === true; });

  // Exams shelf
  var examsLabs = labs.filter(function(l) {
    var hasCerts = Array.isArray(l.certs) && l.certs.length > 0;
    var hasTopics = Array.isArray(l.topics) && l.topics.length > 0;
    return hasCerts && !hasTopics;
  });

  // Other shelf
  var otherSet = collapsedToOther.slice();
  for (var oi = 0; oi < labs.length; oi++) {
    var ol = labs[oi];
    if (onTopicShelf.indexOf(ol) === -1 && examsLabs.indexOf(ol) === -1) {
      if (otherSet.indexOf(ol) === -1) otherSet.push(ol);
    }
  }

  var result = [];

  // 1. Topic shelves in declaration order (omit empty)
  for (var ri = 0; ri < TOPICS.length; ri++) {
    var t = TOPICS[ri];
    var shelfLabs = topicMap[t.key];
    if (shelfLabs.length > 0) {
      result.push({ key: t.key, label: t.label, labs: shelfLabs });
    }
  }

  // 2. Pinned trailing shelves
  if (troubleshootingLabs.length > 0) {
    result.push({ key: TROUBLESHOOTING_KEY, label: 'Troubleshooting', labs: troubleshootingLabs });
  }
  if (examsLabs.length > 0) {
    result.push({ key: EXAMS_KEY, label: 'Exams & Mocks', labs: examsLabs });
  }
  if (otherSet.length > 0) {
    result.push({ key: OTHER_KEY, label: 'Other', labs: otherSet });
  }

  return result;
}

function shelvesFor(labs, opts) {
  return (opts && opts.byCert) ? byCert(labs) : byTopic(labs);
}

// CURRICULUM — the learning path. For each cert, an ordered list of topic
// blocks; each block lists its lab IDs in teaching order (foundational labs
// first, the matching troubleshooting/"-fix" lab last). Single source of truth
// for sequence. A lab lives under exactly one block (no cross-listing). `label`
// is optional (falls back to the TOPICS label). Cert labs not listed here fall
// into a trailing "Exams & Mocks" / "Other" group automatically.
const CURRICULUM = {
  CKAD: [
    { topic: 'workloads', labs: ['ckad-deploy-rollout', 'ckad-deploy-inplace', 'ckad-workloads-jobs', 'learn-ckad-modify-assets', 'learn-ckad-autoscaling', 'ckad-workloads-cronjobs-fix'] },
    { topic: 'config', labs: ['ckad-config-env', 'ckad-config-volumes-fix'] },
    { topic: 'pod-design', labs: ['ckad-poddesign-multicontainer', 'ckad-poddesign-probes', 'ckad-poddesign-security', 'learn-ckad-harden-deploy', 'ckad-poddesign-fix'] },
    { topic: 'observability', labs: ['ckad-observability-inspect', 'ckad-observability-diagnose'] },
    { topic: 'services', label: 'Services & Networking', labs: ['ckad-svc-types', 'ckad-svc-ingress-endpoints', 'ckad-svc-fix'] },
    { topic: 'labels', labs: ['ckad-labels-annotations', 'ckad-labels-select', 'ckad-labels-fix'] },
    { topic: 'quotas', labs: ['ckad-quotas-resourcequota', 'ckad-quotas-limitrange', 'ckad-quotas-fix'] },
    { topic: 'canary', labs: ['learn-ckad-canary'] },
    { topic: 'rbac', label: 'ServiceAccounts & RBAC', labs: ['learn-ckad-serviceaccount'] },
    { topic: 'crd', labs: ['ckad-crd-author', 'ckad-crd-existing-fix'] },
    { topic: 'helm-kustomize', labs: ['ckad-helm', 'ckad-kustomize-fix'] },
    { topic: 'images', labs: ['ckad-images-build', 'ckad-images-distribute'] }
  ],
  CKA: [
    { topic: 'cluster-ops', labs: ['cka-clusterops-staticpod-etcd', 'cka-clusterops-node-maint', 'cka-clusterops-cp-repair', 'cka-clusterops-kubelet-fix'] },
    { topic: 'kubeadm', labs: ['cka-kubeadm-inspect', 'cka-kubeadm-join-certs', 'cka-kubeadm-upgrade-diag'] },
    { topic: 'etcd', labs: ['cka-etcd-backup-restore', 'cka-etcd-manifest-fix'] },
    { topic: 'rbac', labs: ['cka-rbac-basics', 'cka-rbac-sa-leastpriv', 'cka-rbac-csr-binding-fix'] },
    { topic: 'scheduling', labs: ['cka-sched-selectors-taints', 'cka-sched-affinity', 'cka-sched-daemonset-fix'] },
    { topic: 'storage', labs: ['cka-storage-static', 'cka-storage-dynamic', 'cka-storage-pvc-fix'] },
    { topic: 'services', label: 'Services & Networking', labs: ['cka-cni-expose', 'cka-cni-fundamentals', 'cka-cni-nodefix'] },
    { topic: 'gateway-api', labs: ['cka-gw-standup', 'cka-gw-routing', 'cka-gw-vs-ingress-fix'] },
    { topic: 'multicluster', labs: ['cka-multicluster-contexts', 'cka-multicluster-wrongcluster-fix'] }
  ],
  CKS: [
    { topic: 'hardening', labs: ['cks-kubebench-run', 'cks-kubebench-remediate', 'cks-kubebench-fix', 'cks-hardening-controlplane', 'cks-hardening-rbac', 'cks-hardening-rbac-fix', 'cks-apparmor-confine', 'cks-apparmor-stricter-fix', 'cks-ingress-tls-terminate', 'cks-ingress-tls-rotate-fix'] },
    { topic: 'pod-security', labs: ['cks-podsec-securitycontext', 'cks-podsec-restricted-psa', 'cks-podsec-fix'] },
    { topic: 'network-policy', labs: ['cks-netpol-ingress', 'cks-netpol-egress', 'cks-netpol-fix'] },
    { topic: 'supply-chain', labs: ['cks-supplychain-scan', 'cks-supplychain-trust', 'cks-supplychain-vap-fix'] },
    { topic: 'runtime-security', labs: ['cks-falco-rules', 'cks-falco-deploy', 'cks-falco-rule-fix', 'cks-runtimeclass-create', 'cks-runtimeclass-workloads', 'cks-runtimeclass-fix'] }
  ]
};

const TOPIC_LABELS = new Map(TOPICS.map(t => [t.key, t.label]));

// byCertTopic(labs) -> [{cert, groups: [{key, label, labs}]}] — see lib/grouping.js.
function byCertTopic(labs) {
  const byId = new Map(labs.map(l => [l.id, l]));
  const result = [];
  for (const cert of CERTS) {
    const certLabs = labs.filter(l => inCert(l, cert));
    if (certLabs.length === 0) continue;
    const placed = new Set();
    const groups = [];
    for (const block of (CURRICULUM[cert] || [])) {
      const blockLabs = [];
      for (const id of block.labs) {
        const lab = byId.get(id);
        if (lab && inCert(lab, cert) && !placed.has(id)) {
          placed.add(id);
          blockLabs.push(lab);
        }
      }
      if (blockLabs.length > 0) {
        groups.push({ key: block.topic, label: block.label || TOPIC_LABELS.get(block.topic) || block.topic, labs: blockLabs });
      }
    }
    // Leftover = cert labs not placed by CURRICULUM. Split using the canonical
    // labType rule (anything not 'learn' is an exam — see bin/kindlab.js).
    const leftover = certLabs.filter(l => !placed.has(l.id));
    const others = leftover.filter(l => l.type === 'learn');
    const exams = leftover.filter(l => l.type !== 'learn');
    if (exams.length > 0) groups.push({ key: EXAMS_KEY, label: 'Exams & Mocks', labs: exams });
    if (others.length > 0) groups.push({ key: OTHER_KEY, label: 'Other', labs: others });
    result.push({ cert, groups });
  }
  return result;
}

// Expose as browser globals
window.TOPICS = TOPICS;
window.CERTS = CERTS;
window.TROUBLESHOOTING_KEY = TROUBLESHOOTING_KEY;
window.EXAMS_KEY = EXAMS_KEY;
window.OTHER_KEY = OTHER_KEY;
window.certOf = certOf;
window.inCert = inCert;
window.byCert = byCert;
window.byTopic = byTopic;
window.byCertTopic = byCertTopic;
window.shelvesFor = shelvesFor;
