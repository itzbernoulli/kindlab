# KindLab 🧪

A **kind-based CKA / CKAD / CKS practice bench** with real node access, structured labs, and **grade-with-reasons** feedback — a self-hosted exam simulator you can run on any machine with Docker.

Why it exists: hosted simulators run a single managed cluster with **no node access**, so a large slice of CKA/CKS (etcd, control-plane repair, kubelet, static pods, kube-bench, audit…) can't be graded. KindLab runs a **multi-node `kind` cluster** and its setup/validation scripts `docker exec` into the nodes — so those tasks become real, gradable labs. It also has **learn** labs (step-by-step lessons) and **timed exam / mock** modes (scored, pass/fail).

- **📘 Learn labs** — each step has a lesson, a guided task, a hint, and a reveal-solution. Self-paced; progress is "steps mastered." Master a topic by repetition.
- **📝 Exam labs** — scored & timed, no hand-holding. Prove what you learned.
- **🎯 Timed mock** — a shuffled, timed run scored against the real pass mark.
- A **web dashboard** *and* a **CLI** — use either.

---

## Prerequisites

Install these once per machine:

| Tool | macOS (Homebrew) | Linux |
|------|------------------|-------|
| **Docker** | [Docker Desktop](https://www.docker.com/products/docker-desktop/) | Docker Engine |
| **kind** | `brew install kind` | [kind install](https://kind.sigs.k8s.io/docs/user/quick-start/#installation) |
| **kubectl** | `brew install kubectl` | [kubectl install](https://kubernetes.io/docs/tasks/tools/) |
| **Node.js ≥ 18** | `brew install node` | your distro / [nodejs.org](https://nodejs.org) |
| **openssl** | preinstalled | preinstalled |

> **Docker resources:** give Docker **at least 6 GB RAM / 4 CPUs** (Docker Desktop → Settings → Resources). A multi-node Kubernetes cluster is memory-hungry; 4 GB will thrash the apiserver. Don't run another local Kubernetes stack at the same time.

No `npm install` needed — the CLI has **zero npm dependencies** (pure Node stdlib).

---

## Setup

```bash
# 1. Clone
git clone https://github.com/<your-username>/kindlab.git
cd kindlab

# 2. Make the CLI easy to call (pick one)
alias kindlab="node $PWD/bin/kindlab.js"   # add to ~/.zshrc or ~/.bashrc to persist
#   — or —
npm link                                    # installs a global `kindlab` command

# 3. Make sure Docker is running (Docker Desktop started, `docker info` works),
#    then create the multi-node cluster (~1–2 min the first time)
kindlab up

# 4a. Launch the web dashboard …
kindlab serve        # → http://localhost:8080
#   — or 4b. use the CLI directly (see below)
```

`kindlab up` builds a 1 control-plane + 2 worker `kind` cluster; everything else is self-contained.

---

## Web dashboard

```bash
kindlab serve        # http://localhost:8080
```
- Pick a **📘 Learn** lab → **▶ Start / Reset lesson** seeds the cluster → do each step in your terminal → **✓ Check progress** (top or sticky bottom bar).
- **💡 Hint** and **Reveal solution** toggle open/closed per step; mastered labs get a **✓ Mastered** chip in the sidebar.
- **📝 Exam** labs have **⏱ Start timed exam** + **✓ Grade** (score, per-check reasons, pass/fail).
- **🎯 Timed Mock Exam** (top of sidebar) → pick cert + minutes → **Submit** for a PASS/FAIL report card.
- **⟲ Clear progress** per lab, or **⟲ Reset all progress** in the sidebar.

Work happens in **your own terminal** — the dashboard grades the cluster, it doesn't host a shell:
```bash
export KUBECONFIG="$PWD/.state/kubeconfig"   # the banner in each lab shows this
kubectl get nodes
docker exec -it kindlab-control-plane bash   # node-level tasks
```

---

## CLI

```bash
kindlab list                          # all labs, grouped: 📘 Learn + 📝 Exams

# LEARN a section
kindlab learn learn-cka-rbac          # lessons + guided tasks (seeds the cluster)
#   … do a step in your terminal …
kindlab check learn-cka-rbac          # ✓/○ per step; "N/M steps mastered"
kindlab solution learn-cka-rbac 4     # reveal a step's solution if stuck

# EXAM to prove it
kindlab exam cka-clusterops 60        # 60-min timed exam
kindlab status cka-clusterops         # time remaining
kindlab grade cka-clusterops          # ✓/✗ per check + reason + score + rank
kindlab answers cka-clusterops        # full answer key

# TIMED MOCK (scored vs the real pass mark: CKAD 66% · CKA 66% · CKS 67%)
kindlab reset                         # pristine cluster first
kindlab mock CKAD 120                 # shuffled CKAD mock, hard 120-min clock
kindlab mock-status
kindlab submit                        # PASS/FAIL report card

kindlab reset                         # wipe lab resources between labs
kindlab cluster2 up                   # second cluster for multi-cluster labs
kindlab down                          # delete the cluster(s)
```

---

## What's covered

Labs span all three certs, each as **Learn** (step-by-step) and/or **Exam** (scored):

- **CKAD** — config & secrets, pod design & probes, services & networking, workloads/jobs, **rollouts on existing deployments**, **modifying existing assets** (immutable selectors/pods, on-disk YAML, ConfigMap reloads), **building & pushing images**, quotas/limits, CRDs, Helm/Kustomize, observability.
- **CKA** — RBAC, scheduling, storage, CNI/networking, cluster ops (etcd backup, static pods, drain), **etcd restore**, kubeadm upgrades, multi-cluster contexts, Gateway API.
- **CKS** — network policies, Pod Security Admission, securityContext hardening, RuntimeClass, kube-bench, supply-chain, ingress TLS, cluster hardening. *(Falco & AppArmor labs are `needs host` — they require a real Linux kernel with BTF/AppArmor and won't fully run on Docker Desktop.)*

---

## Syncing across laptops

- **Get new/updated labs:** `git pull` on each laptop.
- **Your progress is local.** Per-lab results and the kubeconfig live in `.state/`, which is **git-ignored** — it never leaves the machine and won't conflict. Each laptop grades its own cluster.
- After pulling new labs, just refresh the dashboard (assets are served no-cache) — no restart needed for lab content changes.

---

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| `kubectl` hangs / `TLS handshake timeout` / apiserver flapping | The Docker VM is out of RAM. Give Docker 6–8 GB and don't run a second K8s stack. Recover: `docker restart kindlab-control-plane`. |
| Lab stuck on "Preparing…" | The cluster API is slow/recovering — wait ~30s and retry, or `kindlab reset`. |
| `ErrImagePull` on a locally-built image | Run `kind load docker-image <img> --name kindlab` (see the images lab). |
| Local registry port | macOS holds 5000 (AirPlay); the images lab uses **5001**. |
| Start fresh | `kindlab down && kindlab up` recreates the cluster. |

---

## Writing a lab

Each lab is a folder under `labs/`:
```
labs/<lab-id>/
  lab.json            # metadata + steps (prompt/teach/hint/solution) + weightages (sum to 100)
  setup/q0_setup.sh   # seeds cluster state at Start (runs on the host; kubectl + docker exec)
  validate/qN_s1.sh   # one script per check; exit 0 = pass, stdout = the reason shown on failure
```
Env available to scripts: `CP`, `W1`, `W2` (node names), `WORKERS`, `CTX`, `CTX2`, `KUBECONFIG`, `LAB_DIR`.

**Golden rule:** every Check re-runs **all** validators, so a lab is only sound if one final cluster state satisfies every step at once — never let a later step undo what an earlier step asserts. Grade transient actions (a rollout) on persistent evidence (ReplicaSet history), not the live value.

## License

MIT
