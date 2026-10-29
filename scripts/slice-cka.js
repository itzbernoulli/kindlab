#!/usr/bin/env node
// scripts/slice-cka.js — materialize sliced CKA labs from the mega-labs.
// Usage: node scripts/slice-cka.js <sourceId>
// Reads the cut table below, calls lib/slice-lab.sliceLab for each cut, writes
// the new lab folder (lab.json + copied validate/ + setup/ scripts).
// Pure slicing; reseed q0_setup.sh scripts are hand-edited after materializing.

const fs = require('fs');
const path = require('path');
const { sliceLab } = require('../lib/slice-lab');

const ROOT = path.join(__dirname, '..');
const LABS = path.join(ROOT, 'labs');

// The authoritative CKA cut table (mirrors the plan's split map).
const CUTS = {
  'learn-cka-clusterops': [
    { id:'cka-clusterops-staticpod-etcd', name:'Static pods & etcd backup', topics:['cluster-ops'], certs:['CKA'], exerciseIds:['1','3'] },
    { id:'cka-clusterops-node-maint', name:'Node maintenance: taint, drain, uncordon, label', topics:['cluster-ops'], certs:['CKA'], exerciseIds:['4','5','6','7'] },
    { id:'cka-clusterops-cp-repair', name:'Repair a control-plane component', topics:['cluster-ops'], certs:['CKA'], troubleshooting:true, exerciseIds:['2','8'] },
  ],
  'learn-cka-cni': [
    { id:'cka-cni-fundamentals', name:'How the CNI and CoreDNS work', topics:['networking','cni'], certs:['CKA'], exerciseIds:['1','2','4'] },
    { id:'cka-cni-expose', name:'Expose a Deployment: ClusterIP, headless, NodePort', topics:['services','networking'], certs:['CKA'], exerciseIds:['5','6','7','8'] },
    { id:'cka-cni-nodefix', name:'Fix a node with no CNI config', topics:['cni'], certs:['CKA'], troubleshooting:true, exerciseIds:['3'] },
  ],
  'learn-cka-etcd-restore': [
    { id:'cka-etcd-backup-restore', name:'Back up and restore etcd', topics:['etcd'], certs:['CKA'], exerciseIds:['1','2','3','4','8'] },
    { id:'cka-etcd-manifest-fix', name:"Read etcd's manifest + fix a bad backup", topics:['etcd'], certs:['CKA'], troubleshooting:true, exerciseIds:['5','6','7'] },
  ],
  'learn-cka-gateway-api': [
    { id:'cka-gw-standup', name:'Stand up a Gateway', topics:['gateway-api','networking'], certs:['CKA'], exerciseIds:['1','2','3'] },
    { id:'cka-gw-routing', name:'HTTPRoute matching, filters & traffic splitting', topics:['gateway-api','networking'], certs:['CKA'], exerciseIds:['4','5','6','7'] },
    { id:'cka-gw-vs-ingress-fix', name:'Gateway vs Ingress + fix a detached route', topics:['gateway-api'], certs:['CKA'], troubleshooting:true, exerciseIds:['8','9'] },
  ],
  'learn-cka-kubeadm': [
    { id:'cka-kubeadm-inspect', name:'Inspect a kubeadm cluster', topics:['kubeadm'], certs:['CKA'], exerciseIds:['1','2','3'] },
    { id:'cka-kubeadm-join-certs', name:'Join nodes & renew certificates', topics:['kubeadm'], certs:['CKA'], exerciseIds:['4','6'] },
    { id:'cka-kubeadm-upgrade-diag', name:'Upgrade plan, drain & schedule diagnosis', topics:['kubeadm'], certs:['CKA'], troubleshooting:true, exerciseIds:['5','7','8'] },
  ],
  'learn-cka-multicluster': [
    { id:'cka-multicluster-contexts', name:'Work across two clusters with contexts', topics:['multicluster'], certs:['CKA'], needsSecondCluster:true, exerciseIds:['1','2','3','4','5','6','8'] },
    { id:'cka-multicluster-wrongcluster-fix', name:'Fix a Deployment on the wrong cluster', topics:['multicluster'], certs:['CKA'], troubleshooting:true, needsSecondCluster:true, exerciseIds:['7'] },
  ],
  'learn-cka-rbac': [
    { id:'cka-rbac-basics', name:'Role & RoleBinding basics', topics:['rbac'], certs:['CKA'], exerciseIds:['1','2'] },
    { id:'cka-rbac-sa-leastpriv', name:'ServiceAccounts & least-privilege RBAC', topics:['rbac'], certs:['CKA'], exerciseIds:['3','4','5','6'] },
    { id:'cka-rbac-csr-binding-fix', name:'Approve a CSR + fix a broken binding', topics:['rbac'], certs:['CKA'], troubleshooting:true, exerciseIds:['7','8'] },
  ],
  'learn-cka-scheduling': [
    { id:'cka-sched-selectors-taints', name:'Steer pods with nodeSelector & taints', topics:['scheduling'], certs:['CKA'], exerciseIds:['1','2','5'] },
    { id:'cka-sched-affinity', name:'Node & pod affinity', topics:['scheduling'], certs:['CKA'], exerciseIds:['3','4','7'] },
    { id:'cka-sched-daemonset-fix', name:'DaemonSets + fix an unschedulable pod', topics:['scheduling'], certs:['CKA'], troubleshooting:true, exerciseIds:['6','8'] },
  ],
  'learn-cka-storage': [
    { id:'cka-storage-static', name:'Static PVs and PVCs', topics:['storage'], certs:['CKA'], exerciseIds:['2','3','4','5'] },
    { id:'cka-storage-dynamic', name:'StorageClasses & dynamic provisioning', topics:['storage'], certs:['CKA'], exerciseIds:['1','6','7'] },
    { id:'cka-storage-pvc-fix', name:'Fix a PVC stuck Pending', topics:['storage'], certs:['CKA'], troubleshooting:true, exerciseIds:['8'] },
  ],
};

function materialize(sourceId) {
  const cuts = CUTS[sourceId];
  if (!cuts) { console.error(`no cuts defined for ${sourceId}`); process.exit(1); }
  const srcDir = path.join(LABS, sourceId);
  const sourceLab = JSON.parse(fs.readFileSync(path.join(srcDir, 'lab.json'), 'utf8'));
  sourceLab._dir = srcDir;

  for (const cut of cuts) {
    const { labJson, fileCopies } = sliceLab(sourceLab, cut);
    const dir = path.join(LABS, cut.id);
    fs.mkdirSync(path.join(dir, 'validate'), { recursive: true });
    fs.mkdirSync(path.join(dir, 'setup'), { recursive: true });
    for (const f of fileCopies) {
      if (f.optional && !fs.existsSync(f.from)) continue;
      fs.copyFileSync(f.from, path.join(dir, f.to));
    }
    fs.writeFileSync(path.join(dir, 'lab.json'), JSON.stringify(labJson, null, 2) + '\n');
    console.log(`  ${cut.id}: ${labJson.questions.length} steps, ${fileCopies.length} files`);
  }
  console.log(`materialized ${cuts.length} labs from ${sourceId}`);
}

if (require.main === module) {
  const sourceId = process.argv[2];
  if (!sourceId) { console.error('usage: node scripts/slice-cka.js <sourceId>'); process.exit(1); }
  materialize(sourceId);
}

module.exports = { materialize, CUTS };
