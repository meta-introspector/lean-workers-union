# lean-workers-union

A registry and coordination layer for Lean workers and Choir members.

## Purpose

This repository defines the shared membership and role contract for distributed
formal agents. The union is intentionally not a task runner: it names the
identity, role, and capability model a member advertises, while Choir remains
responsible for orchestration and lifecycle decisions.

## Core design

A member is not permanently bound to a single role. The same runtime can act as:

- an orchestrator at one time
- a worker at another time
- a relay or observer in other phases

The registry records the identity of each member and enforces the valid role
transitions that preserve membership invariants.

## Membership contract

A member advertises:

- member id
- repo or runtime identity
- public key or signing identity
- capabilities
- current role
- credit / heartbeat / lease state

The registry stores members in a uniform shape so that downstream integrations
can query them without depending on a specific implementation.

## Role model

The union defines four fundamental roles:

- `Orchestrator`
- `Worker`
- `Relay`
- `Observer`

The same member may move between these states, but only via valid transitions.

## Integration story

The intended composition is:

- `Choir` = orchestration and task lifecycle
- `lean-workers-union` = registration, identity, and role coordination
- `lean-worker` = a formal member implementation with proofs
- `aristotle-cli-rs` / `kant-zk-pastebin` / `cloudflare/cloudflare-os` = capability-backed services that can
  register under the same union contract

## Files

- `Member.lean` — the core Lean definition of member identity, states, and
  transitions
- `Union.lean` — the registry contract for union membership and lookup

## Invariants

The union enforces the following concepts:

- member identity is stable across role transitions
- role changes are explicit and valid
- capabilities are part of the public member contract
- change in role is logged as a transition, not an implicit mutation
- each member can be looked up by identity, repo, or capability

## Status

This repository is intentionally small and protocol-first. The aim is to define
shared semantics before deciding how the adapters and worker implementations use
those semantics in their own repositories.
