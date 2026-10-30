#!/usr/bin/env node
// scripts/slice-ckad.js — materialize sliced CKAD labs from the mega-labs.
// Same mechanics as slice-cka.js / slice-cks.js; cut table mirrors the spec's CKAD split map.
// Usage: node scripts/slice-ckad.js <sourceId>

const fs = require('fs');
const path = require('path');
const { sliceLab } = require('../lib/slice-lab');

const ROOT = path.join(__dirname, '..');
const LABS = path.join(ROOT, 'labs');

const CUTS = {
  'learn-ckad-config': [
    { id:'ckad-config-env', name:'Feed config into a pod (env & envFrom)', topics:['config'], certs:['CKAD'], exerciseIds:['1','2'] },
    { id:'ckad-config-volumes-fix', name:'Mount config: volumes, secrets & projection', topics:['config'], certs:['CKAD'], troubleshooting:true, exerciseIds:['3','4','5','6','7'] },
  ],
  'learn-ckad-crd': [
    { id:'ckad-crd-author', name:'Author and create a CRD', topics:['crd'], certs:['CKAD'], exerciseIds:['1','2','4','6'] },
    { id:'ckad-crd-existing-fix', name:'Work with existing CRDs (discover & validate)', topics:['crd'], certs:['CKAD'], troubleshooting:true, exerciseIds:['3','5','7'] },
  ],
  'learn-ckad-deploy-ops': [
    { id:'ckad-deploy-rollout', name:'Roll out and roll back a Deployment', topics:['workloads'], certs:['CKAD'], exerciseIds:['1','2','3'] },
    { id:'ckad-deploy-inplace', name:'Edit a live Deployment in place', topics:['workloads'], certs:['CKAD'], exerciseIds:['4','5','6','7','8'] },
  ],
  'learn-ckad-helm-kustomize': [
    { id:'ckad-helm', name:'Package apps with Helm', topics:['helm-kustomize'], certs:['CKAD'], exerciseIds:['1','2','3','4','5'] },
    { id:'ckad-kustomize-fix', name:'Customize manifests with Kustomize', topics:['helm-kustomize'], certs:['CKAD'], troubleshooting:true, exerciseIds:['6','7','8','9'] },
  ],
  'learn-ckad-images': [
    { id:'ckad-images-build', name:'Build and modify container images', topics:['images'], certs:['CKAD'], exerciseIds:['1','2','3'] },
    { id:'ckad-images-distribute', name:'Package and distribute images', topics:['images'], certs:['CKAD'], exerciseIds:['4','5','6','7'] },
  ],
  'learn-ckad-labels': [
    { id:'ckad-labels-select', name:'Label and select pods', topics:['labels'], certs:['CKAD'], exerciseIds:['1','2','3','4'] },
    { id:'ckad-labels-annotations', name:'Selectors in specs & annotations', topics:['labels'], certs:['CKAD'], exerciseIds:['5','6'] },
    { id:'ckad-labels-fix', name:'Fix a selector that matches nothing', topics:['labels'], certs:['CKAD'], troubleshooting:true, exerciseIds:['7'] },
  ],
  'learn-ckad-observability': [
    { id:'ckad-observability-diagnose', name:'Diagnose failing workloads', topics:['observability'], certs:['CKAD'], troubleshooting:true, exerciseIds:['1','2','3','5'] },
    { id:'ckad-observability-inspect', name:'Inspect a running pod', topics:['observability'], certs:['CKAD'], exerciseIds:['4','6'] },
  ],
  'learn-ckad-pod-design': [
    { id:'ckad-poddesign-multicontainer', name:'Multi-container & init patterns', topics:['pod-design'], certs:['CKAD'], exerciseIds:['1','2','3'] },
    { id:'ckad-poddesign-probes', name:'Probes, lifecycle & graceful shutdown', topics:['pod-design','observability'], certs:['CKAD'], exerciseIds:['4','5'] },
    { id:'ckad-poddesign-security', name:'SecurityContext, QoS & downward API', topics:['pod-design','pod-security'], certs:['CKAD'], exerciseIds:['6','7','8'] },
    { id:'ckad-poddesign-fix', name:"Fix a Deployment that won't go Ready", topics:['pod-design'], certs:['CKAD'], troubleshooting:true, exerciseIds:['9'] },
  ],
  'learn-ckad-quotas': [
    { id:'ckad-quotas-resourcequota', name:'ResourceQuota: compute & objects', topics:['quotas'], certs:['CKAD'], exerciseIds:['1','2','3','4'] },
    { id:'ckad-quotas-limitrange', name:'LimitRange: defaults & bounds', topics:['quotas'], certs:['CKAD'], exerciseIds:['5','6','7'] },
    { id:'ckad-quotas-fix', name:'Fix a pod rejected by a quota', topics:['quotas'], certs:['CKAD'], troubleshooting:true, exerciseIds:['8'] },
  ],
  'learn-ckad-services-net': [
    { id:'ckad-svc-types', name:'Service types: ClusterIP, NodePort, Headless, ExternalName', topics:['services','networking'], certs:['CKAD'], exerciseIds:['1','2','3','4'] },
    { id:'ckad-svc-ingress-endpoints', name:'Session affinity, Ingress & manual endpoints', topics:['services','networking'], certs:['CKAD'], exerciseIds:['5','6','7'] },
    { id:'ckad-svc-fix', name:'Fix a Service with no endpoints', topics:['services','networking'], certs:['CKAD'], troubleshooting:true, exerciseIds:['8'] },
  ],
  'learn-ckad-workloads': [
    { id:'ckad-workloads-jobs', name:'Jobs: completions, retries & indexed', topics:['workloads'], certs:['CKAD'], exerciseIds:['2','3','4','5'] },
    { id:'ckad-workloads-cronjobs-fix', name:'CronJobs & a Job that never runs', topics:['workloads'], certs:['CKAD'], troubleshooting:true, exerciseIds:['6','7','8'] },
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
  if (!sourceId) { console.error('usage: node scripts/slice-ckad.js <sourceId>'); process.exit(1); }
  materialize(sourceId);
}

module.exports = { materialize, CUTS };
