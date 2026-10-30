#!/usr/bin/env node
// scripts/slice-cks.js — materialize sliced CKS labs from the mega-labs.
// Same mechanics as slice-cka.js; cut table mirrors the spec's CKS split map.
// Usage: node scripts/slice-cks.js <sourceId>

const fs = require('fs');
const path = require('path');
const { sliceLab } = require('../lib/slice-lab');

const ROOT = path.join(__dirname, '..');
const LABS = path.join(ROOT, 'labs');

const CUTS = {
  'learn-cks-apparmor': [
    { id:'cks-apparmor-confine', name:'Confine a pod with AppArmor', topics:['hardening'], certs:['CKS'], exerciseIds:['1','2','3','4','5'] },
    { id:'cks-apparmor-stricter-fix', name:'A stricter AppArmor profile + fix a missing profile', topics:['hardening'], certs:['CKS'], troubleshooting:true, exerciseIds:['6','7','8'] },
  ],
  'learn-cks-falco': [
    { id:'cks-falco-deploy', name:'Deploy Falco as a DaemonSet', topics:['runtime-security'], certs:['CKS'], exerciseIds:['1','2'] },
    { id:'cks-falco-rules', name:'Write and tune a Falco rule', topics:['runtime-security'], certs:['CKS'], exerciseIds:['3','4','5','6','7'] },
    { id:'cks-falco-rule-fix', name:'Fix a broken Falco rule', topics:['runtime-security'], certs:['CKS'], troubleshooting:true, exerciseIds:['8'] },
  ],
  'learn-cks-hardening': [
    { id:'cks-hardening-controlplane', name:'Harden the control plane and kubelets', topics:['hardening'], certs:['CKS'], exerciseIds:['1','2','3','4','5'] },
    { id:'cks-hardening-rbac', name:'Least-privilege RBAC and token hardening', topics:['hardening','rbac'], certs:['CKS'], exerciseIds:['6','7'] },
    { id:'cks-hardening-rbac-fix', name:'Fix RBAC that grants the wrong access', topics:['rbac'], certs:['CKS'], troubleshooting:true, exerciseIds:['8'] },
  ],
  'learn-cks-ingress-tls': [
    { id:'cks-ingress-tls-terminate', name:'Terminate TLS at the Ingress', topics:['networking'], certs:['CKS'], exerciseIds:['1','2','3','4','5'] },
    { id:'cks-ingress-tls-rotate-fix', name:'Rotate and repair Ingress TLS', topics:['networking'], certs:['CKS'], troubleshooting:true, exerciseIds:['6','7'] },
  ],
  'learn-cks-kube-bench': [
    { id:'cks-kubebench-run', name:'Run kube-bench against node and master', topics:['hardening'], certs:['CKS'], exerciseIds:['1','2'] },
    { id:'cks-kubebench-remediate', name:'Remediate kube-bench findings', topics:['hardening'], certs:['CKS'], exerciseIds:['3','4','5','6'] },
    { id:'cks-kubebench-fix', name:'Fix a kube-bench kubelet-config FAIL', topics:['hardening'], certs:['CKS'], troubleshooting:true, exerciseIds:['7'] },
  ],
  'learn-cks-netpol': [
    { id:'cks-netpol-ingress', name:'NetworkPolicy: control ingress', topics:['network-policy'], certs:['CKS'], exerciseIds:['1','2','3','4','7'] },
    { id:'cks-netpol-egress', name:'NetworkPolicy: control egress', topics:['network-policy'], certs:['CKS'], exerciseIds:['5','6'] },
    { id:'cks-netpol-fix', name:'Fix a NetworkPolicy blocking the wrong traffic', topics:['network-policy'], certs:['CKS'], troubleshooting:true, exerciseIds:['8'] },
  ],
  'learn-cks-podsecurity': [
    { id:'cks-podsec-securitycontext', name:'Harden a pod with securityContext', topics:['pod-security'], certs:['CKS'], exerciseIds:['1','2','3','4','5'] },
    { id:'cks-podsec-restricted-psa', name:'Build a fully restricted pod + enforce PSA', topics:['pod-security'], certs:['CKS'], exerciseIds:['6','7'] },
    { id:'cks-podsec-fix', name:"Fix a pod that won't start under hardening", topics:['pod-security'], certs:['CKS'], troubleshooting:true, exerciseIds:['8'] },
  ],
  'learn-cks-runtimeclass': [
    { id:'cks-runtimeclass-create', name:'Create and run a RuntimeClass', topics:['runtime-security'], certs:['CKS'], exerciseIds:['1','2','3','4'] },
    { id:'cks-runtimeclass-workloads', name:'Use RuntimeClasses in workloads', topics:['runtime-security'], certs:['CKS'], exerciseIds:['5','6','7'] },
    { id:'cks-runtimeclass-fix', name:'Fix a pod wired to a missing RuntimeClass', topics:['runtime-security'], certs:['CKS'], troubleshooting:true, exerciseIds:['8'] },
  ],
  'learn-cks-supplychain': [
    { id:'cks-supplychain-scan', name:'Scan images and manifests', topics:['supply-chain'], certs:['CKS'], exerciseIds:['1','2'] },
    { id:'cks-supplychain-trust', name:'Pin and trust images', topics:['supply-chain'], certs:['CKS'], exerciseIds:['3','4','7'] },
    { id:'cks-supplychain-vap-fix', name:'Enforce image policy with VAP', topics:['supply-chain'], certs:['CKS'], troubleshooting:true, exerciseIds:['5','6','8'] },
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
  if (!sourceId) { console.error('usage: node scripts/slice-cks.js <sourceId>'); process.exit(1); }
  materialize(sourceId);
}

module.exports = { materialize, CUTS };
