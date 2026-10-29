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
  { key: 'networking', label: 'Networking' },
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
  { key: 'quotas', label: 'Quotas' }
];

const CERTS = ['CKAD', 'CKA', 'CKS'];

const TROUBLESHOOTING_KEY = 'troubleshooting';
const EXAMS_KEY = 'exams';
const OTHER_KEY = 'other';

module.exports = {
  TOPICS,
  CERTS,
  TROUBLESHOOTING_KEY,
  EXAMS_KEY,
  OTHER_KEY
};
