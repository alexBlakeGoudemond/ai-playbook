---
name: log-context-enrichment
description: When analyzing logs, look at the source code
requires:
  - source code
applies-when:
  - analyzing logs
---

When analyzing logs and source code is available:

- Search for logger definitions
- Locate originating log statements
- Identify surrounding business logic
- Identify related code paths
- Explain why the log entry exists
- Identify the source file and function
- Trace the execution path leading to the log statement
- Determine whether the log indicates expected or exceptional behavior