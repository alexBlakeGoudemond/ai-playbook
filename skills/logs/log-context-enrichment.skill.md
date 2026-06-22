---
name: Log Context Enrichment
description: Additional things that could be done to understand a log entry
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