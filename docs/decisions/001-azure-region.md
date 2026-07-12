# ADR-001: Azure Region Selection

## Status

Accepted

## Context

The server will primarily be accessed from the Philippines and must remain
within the limited Azure for Students budget.

## Decision

Use the Azure Southeast Asia region in Singapore.

## Reasons

- Geographically close to the Philippines
- Suitable starting point for lower network latency
- Keeps the initial architecture within one Azure region
- Compatible with the project's student budget

## Consequences

- The project initially has no multi-region disaster recovery
- Available VM sizes depend on regional capacity
- A future production deployment may require additional redundancy