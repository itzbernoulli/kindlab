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
    result.push({ key: EXAMS_KEY, label: 'Exams', labs: examsLabs });
  }
  if (otherSet.length > 0) {
    result.push({ key: OTHER_KEY, label: 'Other', labs: otherSet });
  }

  return result;
}

function shelvesFor(labs, opts) {
  return (opts && opts.byCert) ? byCert(labs) : byTopic(labs);
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
window.shelvesFor = shelvesFor;
