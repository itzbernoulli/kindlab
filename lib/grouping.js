const TOPICS = [
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

const CERTS = ['CKAD', 'CKA', 'CKS'];

const TROUBLESHOOTING_KEY = 'troubleshooting';
const EXAMS_KEY = 'exams';
const OTHER_KEY = 'other';

/**
 * certOf(lab) -> string|undefined
 * Returns the primary display cert: first element of lab.certs, or lab.category, or undefined.
 */
function certOf(lab) {
  return lab.certs?.[0] ?? lab.category ?? undefined;
}

/**
 * inCert(lab, cert) -> boolean
 * True when lab belongs to the given cert.
 * Uses lab.certs if present; falls back to [lab.category] when only category is set.
 */
function inCert(lab, cert) {
  return (lab.certs ?? (lab.category ? [lab.category] : [])).includes(cert);
}

/**
 * byCert(labs) -> Array<{cert, labs}>
 * One entry per CERTS value (declaration order) containing labs for which inCert is true.
 * Empty certs are omitted. A lab with multiple certs appears in each matching entry.
 */
function byCert(labs) {
  const result = [];
  for (const cert of CERTS) {
    const matched = labs.filter(l => inCert(l, cert));
    if (matched.length > 0) {
      result.push({ cert, labs: matched });
    }
  }
  return result;
}

/**
 * byTopic(labs) -> Array<{key, label, labs}>
 *
 * Shelf construction order:
 *   1. One shelf per TOPICS entry (declaration order) — labs whose topics[] includes that key.
 *   2. TROUBLESHOOTING_KEY shelf — every lab with troubleshooting===true (cross-listed).
 *   3. EXAMS_KEY shelf — labs that have certs but no non-empty topics array.
 *   4. OTHER_KEY shelf — labs not matched by any prior shelf.
 *
 * Collapse rule (topic shelves only, not the trailing three):
 *   A topic shelf holding exactly one lab is removed; that lab is appended to the next
 *   non-empty topic shelf in declaration order. If no later topic shelf has labs, the lab
 *   moves to Other instead.
 *
 * Empty shelves are omitted from the result.
 */
function byTopic(labs) {
  // Build raw topic shelf map: key -> lab[]
  const topicMap = new Map();
  for (const t of TOPICS) {
    topicMap.set(t.key, []);
  }
  for (const lab of labs) {
    if (Array.isArray(lab.topics)) {
      for (const k of lab.topics) {
        if (topicMap.has(k)) {
          topicMap.get(k).push(lab);
        }
      }
    }
  }

  // Apply the single-lab collapse rule.
  // Work through TOPICS in declaration order.
  // Collect the topic keys in order for look-ahead.
  const topicKeys = TOPICS.map(t => t.key);
  // Extra labs that collapsed from single-lab shelves and found no next shelf go to Other.
  const collapsedToOther = [];

  for (let i = 0; i < topicKeys.length; i++) {
    const key = topicKeys[i];
    const shelf = topicMap.get(key);
    if (shelf.length === 1) {
      const orphan = shelf[0];
      // Do not collapse a troubleshooting-cross-listed lab — it must remain on its topic shelf.
      if (orphan.troubleshooting === true) continue;
      // Find the next non-empty topic shelf (after position i).
      let placed = false;
      for (let j = i + 1; j < topicKeys.length; j++) {
        const nextShelf = topicMap.get(topicKeys[j]);
        if (nextShelf.length > 0) {
          nextShelf.push(orphan);
          placed = true;
          break;
        }
      }
      if (!placed) {
        collapsedToOther.push(orphan);
      }
      // Clear the single-lab shelf so it is omitted.
      topicMap.set(key, []);
    }
  }

  // Track which labs are on at least one topic shelf (for Other determination).
  const onTopicShelf = new Set();
  for (const [, shelfLabs] of topicMap) {
    for (const lab of shelfLabs) onTopicShelf.add(lab);
  }

  // Troubleshooting shelf — all labs with troubleshooting===true (cross-listed).
  const troubleshootingLabs = labs.filter(l => l.troubleshooting === true);

  // Exams shelf — labs with certs but no non-empty topics.
  const examsLabs = labs.filter(l => {
    const hasCerts = Array.isArray(l.certs) && l.certs.length > 0;
    const hasTopics = Array.isArray(l.topics) && l.topics.length > 0;
    return hasCerts && !hasTopics;
  });

  // Other shelf — labs not on any topic shelf AND not on exams shelf,
  // plus labs collapsed from single-lab shelves that had no following topic shelf.
  const otherSet = new Set(collapsedToOther);
  for (const lab of labs) {
    if (!onTopicShelf.has(lab) && !examsLabs.includes(lab)) {
      otherSet.add(lab);
    }
  }
  const otherLabs = [...otherSet];

  // Assemble final shelf list.
  const result = [];

  // 1. Topic shelves in declaration order (omit empty).
  for (const t of TOPICS) {
    const shelfLabs = topicMap.get(t.key);
    if (shelfLabs.length > 0) {
      result.push({ key: t.key, label: t.label, labs: shelfLabs });
    }
  }

  // 2. Pinned trailing shelves.
  if (troubleshootingLabs.length > 0) {
    result.push({ key: TROUBLESHOOTING_KEY, label: 'Troubleshooting', labs: troubleshootingLabs });
  }
  if (examsLabs.length > 0) {
    result.push({ key: EXAMS_KEY, label: 'Exams', labs: examsLabs });
  }
  if (otherLabs.length > 0) {
    result.push({ key: OTHER_KEY, label: 'Other', labs: otherLabs });
  }

  return result;
}

/**
 * shelvesFor(labs, opts) -> Array<{key, label, labs}> | Array<{cert, labs}>
 * Returns byCert(labs) when opts.byCert is truthy, else byTopic(labs).
 */
function shelvesFor(labs, opts) {
  return (opts && opts.byCert) ? byCert(labs) : byTopic(labs);
}

/**
 * inMockPool(lab, cert) -> boolean
 * True when a lab should appear in the mock exam pool for the given cert.
 * The lab must belong to the cert (cert-aware, array-aware via inCert) and
 * must not be a learn lab (only exam labs feed the pool).
 */
const inMockPool = (lab, cert) => inCert(lab, cert) && lab.type !== 'learn';

module.exports = {
  TOPICS,
  CERTS,
  TROUBLESHOOTING_KEY,
  EXAMS_KEY,
  OTHER_KEY,
  certOf,
  inCert,
  inMockPool,
  byCert,
  byTopic,
  shelvesFor
};
