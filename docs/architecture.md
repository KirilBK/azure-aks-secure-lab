# Architecture

```
                         Internet
                            │
                            ▼
              ┌──────────────────────────┐
              │  NGINX Ingress (AKS LB)   │
              └─────────────┬────────────┘
                            │  (NetworkPolicy: only ingress-nginx → app1:8080)
                            ▼
   ┌─────────────────────────────────────────────┐
   │  AKS  (1 node, Azure CNI, network policy on)  │
   │   ns: app1                                    │
   │   ├─ Deployment app1 (2 replicas, non-root)   │
   │   │    securityContext: RO rootfs, drop ALL   │
   │   ├─ ServiceAccount app1-sa  ──workload id──┐ │
   │   └─ CSI volume ← Key Vault (sql-conn)      │ │
   └──────────────────────────────────────────┐ │ │
                                               │ │ │
   app4 ── Azure Container Instance (no DB)    │ │ │
   app2 ── App Service (PHP)  ──MI──┐          │ │ │
   app3 ── App Service (PHP)  ──MI──┤          │ │ │
   Func ── Function App (Python) ─MI┤          │ │ │
                                    ▼          ▼ ▼ ▼
                          ┌───────────────┐  ┌──────────────┐
                          │   Key Vault   │  │  Azure SQL    │
                          │ sql-conn (1)  │  │ examdb        │
                          └───────────────┘  │ SubmittedItems│
                                             └──────────────┘
   ACR (Basic, admin OFF) ── images pulled by AKS kubelet identity (AcrPull)
```

All secret access is brokered by managed identities. The SQL password exists
only inside Key Vault (and Terraform state). No component reads it from source.

Replace this ASCII sketch with the **Resource Visualizer export** from your
actual deployment for the portfolio writeup (Resource group → Resource
visualizer → Export, High/Best quality), plus the **Export template** JSON.
