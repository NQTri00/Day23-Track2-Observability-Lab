# Day 23 Lab Reflection

> Fill in each section. Grader reads the "What I'd change" paragraph closest.

**Student:** Ninh Quang Trí
**Submission date:** 2026-05-11
**Lab repo URL:** https://github.com/NQTri00/Day23-Track2-Observability-Lab.git

---

## 1. Hardware + setup output

Paste output of `python3 00-setup/verify-docker.py`:

```
Docker:        OK  (29.4.0)
Compose v2:    OK  (5.1.1)
RAM available: 7.7 GB (OK)
Ports free:    OK
Report written: D:\VINAILAB\Day23-Track2-Observability-Lab\00-setup\setup-report.json
```

---

## 2. Track 02 — Dashboards & Alerts

### 6 essential panels (screenshot)

Drop `submission/screenshots/dashboard-overview.png`.

### Burn-rate panel

Drop `submission/screenshots/slo-burn-rate.png`.

### Alert fire + resolve

| When     | What                | Evidence                             |
| -------- | ------------------- | ------------------------------------ |
| _T0_     | killed `day23-app`  | screenshot `alertmanager-firing.png` |
| _T0+90s_ | `ServiceDown` fired | screenshot `slack-firing.png`        |
| _T1_     | restored app        | —                                    |
| _T1+60s_ | alert resolved      | screenshot `slack-resolved.png`      |

One thing that surprised me was how Alertmanager handles configuration—it doesn't natively interpolate environment variables in its YAML file like Prometheus does. This forced us to hardcode the Slack webhook, highlighting a critical difference in how these components manage secrets and dynamic configs. Also, the power of Grafana's auto-provisioning system made it surprisingly easy to deploy complex dashboards without manual UI interaction.

---

## 3. Track 03 — Tracing & Logs

### One trace screenshot from Jaeger

Drop `submission/screenshots/jaeger-trace.png` showing `embed-text → vector-search → generate-tokens` spans.

### Log line correlated to trace

Paste the log line and the trace_id it links to:

```json
{"model": "llama3-mock", "input_tokens": 4, "output_tokens": 40, "quality": 0.797, "duration_seconds": 0.3661, "trace_id": "87cf3e4999fa57d1350aa953ac7b27cb", "event": "prediction served", "level": "info", "timestamp": "2026-05-11T04:13:19.864096Z"}
```
Linked Trace ID: `87cf3e4999fa57d1350aa953ac7b27cb`

The tail-sampling policy is configured to keep 100% of errors and 1% of healthy traces. If the service produces $N$ traces/sec, where $E$ are errors and $H$ are healthy ($N = E + H$), the collector keeps:
$$Traces_{kept} = E \times 1.0 + H \times 0.01$$
For example, at 100 traces/sec with a 5% error rate, we keep $5 + 95 \times 0.01 = 5.95$ traces/sec, a significant reduction in egress and storage costs while maintaining full visibility into failures.

---

## 4. Track 04 — Drift Detection

### PSI scores

Paste `04-drift-detection/reports/drift-summary.json`:

```json
{
  "prompt_length": {
    "psi": 3.461,
    "kl": 1.7982,
    "ks_stat": 0.702,
    "ks_pvalue": 0.0,
    "drift": "yes"
  },
  "embedding_norm": {
    "psi": 0.0187,
    "kl": 0.0324,
    "ks_stat": 0.052,
    "ks_pvalue": 0.133853,
    "drift": "no"
  },
  "response_length": {
    "psi": 0.0162,
    "kl": 0.0178,
    "ks_stat": 0.056,
    "ks_pvalue": 0.086899,
    "drift": "no"
  },
  "response_quality": {
    "psi": 8.8486,
    "kl": 13.5011,
    "ks_stat": 0.941,
    "ks_pvalue": 0.0,
    "drift": "yes"
  }
}
```

### Which test fits which feature?

- **PSI (Population Stability Index)**: Used for `prompt_length` and `response_length`. It is an industry standard for monitoring general population shifts (e.g., users suddenly sending much longer prompts) without being too sensitive to small sample fluctuations.
- **KS (Kolmogorov-Smirnov) Test**: Used for `embedding_norm`. Since embeddings are continuous and highly sensitive numerical values, KS is better at detecting subtle distribution changes that PSI might overlook.
- **KL Divergence**: Used for `response_quality` scores. It measures "information loss" and is very effective at detecting how much the prediction logic has diverged from the expected probability distribution (Beta-distributed quality scores).
- **MMD (Maximum Mean Discrepancy)**: Used for high-dimensional drift (e.g. comparing raw embedding vectors), though not explicitly calculated in this script.

---

## 5. Track 05: Cross-Day Integration

### Integration Summary
The Day 23 stack successfully acts as a central observability hub by scraping metrics from the Day 19 Vector Store (Qdrant) and Day 20 Model Serving (llama.cpp) stubs. This demonstrates the ability of a centralized OTel/Prometheus pipeline to provide a unified view across distinct microservices in an AI pipeline.

### Hardest Metric to Expose
The **llama.cpp (Day 20)** tokens-per-second metric was the hardest to expose. Unlike modern cloud-native tools (like Qdrant or FastAPI), llama.cpp's core server does not natively export Prometheus metrics. We had to rely on a sidecar or a custom stub script to translate its internal JSON state into a format Prometheus could scrape, highlighting the "last-mile" instrumentation challenge in AI infra.

---

## 6. The single change that mattered most

The most impactful change was hardcoding the Slack webhook URL directly into the Alertmanager configuration after discovering that the standard `prom/alertmanager` image does not natively support environment variable interpolation in its YAML config. Without this, the alerting pipeline would have remained broken despite a correctly configured `.env` file. This connects directly to the "Cardinality and Configuration" concepts from the deck—observability tools are only as useful as their reachability.

Additionally, implementing structured logging with `trace_id` injection via `structlog` made the biggest difference in debuggability. By correlating logs to traces, we move from "knowing something is wrong" to "seeing exactly where it failed" across spans like `embed-text` and `generate-tokens`. This implements the "Three Pillars" integration discussed in §2 of the deck.
