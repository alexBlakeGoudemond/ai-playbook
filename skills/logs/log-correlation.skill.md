---
name: Log Correlation
description: Additional things that could be done to collect related logs
applies-when:
  - analyzing logs
  - investigating incidents
guardrails:
  - logs/log-reporting-guardrail
---

When analyzing logs:

- Group events by correlation ID
- Group events by request ID
- Group events by user ID
- Construct event timelines
- Identify missing or out-of-order events
- Trace requests across services