# Specification Quality Checklist: Platform Core Foundation

**Purpose**: Validate specification completeness, clarity, traceability, scope, and Constitution v2.3.0 consistency
**Reviewed**: 2026-11-23
**Feature**: [spec.md](../spec.md)

## Existing Event-Communication Checks

- [x] PASS — The communication synchronization remains focused on module communication, contract governance, and user-observable behavior.
- [x] PASS — Event-communication requirements defer broker topology, retry thresholds, dead-letter topology, and Outbox storage design to planning; the explicit RabbitMQ initial-broker constraint remains Constitution-aligned.
- [x] PASS — Existing event, tenant, module-governance, and Foundation scope are preserved; the new Gateway and Dependency Inversion (DIP) material is additive.
- [x] PASS — Functional requirement declarations are sequential and unique from FR-001 through FR-121; event/tenant requirements extend through FR-070, Gateway/DIP requirements use FR-071–FR-091, Module Autonomy & Data Sovereignty requirements use FR-092–FR-120, and FR-121 specifies constitutional testing assurance.
- [x] PASS — Success-criteria declarations are sequential and unique from SC-001 through SC-073; no `[NEEDS CLARIFICATION]` markers remain.
- [x] PASS — Event requirements specify contract validation, at-least-once delivery, idempotent effects, tenant isolation, and lifecycle outcomes.
- [x] PASS — All 25 Platform Event Bus acceptance scenarios in User Story 4 have unambiguous requirement and success-criteria references; Scenarios 2, 3, 8, and 9 each have separate mappings.
- [x] PASS — Event-specific criteria SC-020–SC-035 and SC-037–SC-038 avoid adding broker latency, throughput, message-size, retention, retry-count, or availability targets; SC-036 leaves recovery objectives deployment-specific. SC-004 defines its measurement window and local/deployed profiles without selecting a broker product.
- [x] PASS — Event edge cases cover unavailable publishers/subscribers, no subscribers, duplicate and out-of-order delivery, malformed/unsupported events, tenant-context failures, repeated consumer failures, duplicate subscriptions, pending deliveries, upgrades, synchronous failures/cycles, and forbidden dependencies.
- [x] PASS — The Platform Event Bus remains authoritative for asynchronous cross-module communication; the Gateway does not replace it.

## Speckit Specification-Quality Validation

- [x] PASS — User/business value is stated through the Foundation vision and story goals, priority rationales, and outcomes for administrators, developers, operators, and extension partners.
- [x] PASS — The specification contains 15 actor/goal stories. User Stories 14–15 include rationales, independent-test statements, and Given/When/Then scenarios for private-state ownership, integration, lifecycle, and certification.
- [x] PASS — Core specification sections are present: Vision, Clarifications, User Scenarios & Testing, Requirements, Key Entities, Success Criteria, Assumptions, and Deliverables.
- [x] PASS — Clarification decisions are recorded; no unresolved `[NEEDS CLARIFICATION]` markers are present.
- [x] PASS — v1 scope is bounded: the spec limits the release to the platform foundation and explicitly excludes business modules, mobile support, SSO/OIDC, and a general administrative dashboard.
- [x] PASS — Assumptions identify deployment, persistence, messaging, technology, security, data, operational, and governance dependencies; the recovery-target decision is explicitly deployment-specific.
- [x] PASS (scope-limited) — The Gateway/DIP synchronization adds no product-specific implementation dependency or unnecessary deployment detail. Existing Foundation details such as FR-006, FR-020, FR-029, and FR-041 are retained as required by the preservation scope; SC-004 now defines its measurement boundary without selecting a broker product.
- [x] PASS — Explicit Foundation technology constraints are not treated as generic quality failures: Constitution v2.3.0 requires Node.js 22+, TypeScript 5+, NestJS/Fastify, PostgreSQL/Prisma/Redis, and RabbitMQ as the expected initial broker; JWT/refresh-token rules and OpenAPI contracts are also explicitly constitutional. Gateway selection is deferred to an ADR, with Kong only an evaluation candidate (FR-080, SC-049).
- [x] PASS — The newly added requirements define when manifest declarations are required or empty (FR-073), when quotas and CORS apply (FR-076), and that retry/dead-letter decisions follow a documented, versioned deployment policy with observable outcomes while numeric thresholds and topology remain deferred (FR-014).
- [x] PASS — User-story acceptance coverage includes primary, alternate, exception, and recovery cases, with traceability clarified for the preserved flows affected by the synchronization and broad event/Gateway/DIP edge-case coverage.
- [x] PASS — Success criteria use verifiable outcomes: SC-010 uses a maintained acceptance-test set, SC-011 measures published runnable examples, SC-014 ties scaling to deployment service objectives, SC-017 defines the start and end events, SC-018 requires an end-to-end acceptance test, and SC-004 defines a measurement window and deployment profiles without selecting a broker product.
- [x] PASS — The 2026-11-23 clarification that v1 has no platform-wide numeric recovery target is explicit in the assumptions and SC-036 requires deployment-specific objectives and recovery tests; the lack of a universal RPO/RTO number is intentional, not an unresolved marker.

## Acceptance and Traceability

- [x] PASS — Traceability was added or clarified for the preserved user stories affected by this synchronization. New Gateway/DIP and data-sovereignty scenarios identify governing functional requirements and applicable success criteria; no prior traceability references were removed.
- [x] PASS — User Story 13 now maps SC-049 only to User Story 7 Scenario 8, the Gateway product-selection ADR decision. Its prohibited-dependency scenarios map to FR-082–FR-088 and SC-045–SC-047; the allowed adapter directions map to FR-083, FR-087–FR-089 and SC-045, SC-048.
- [x] PASS — Gateway publication, API ownership, route lifecycle, trust-boundary, topology independence, and edge-policy flows are represented by User Stories 11–12 and their acceptance scenarios.
- [x] PASS — DIP ports/adapters, persistence, messaging, providers, Gateway management, certification, uniform module scope, and avoidance of artificial interfaces are represented in User Story 13, User Story 3, and the Edge Cases section.
- [x] PASS — Gateway and DIP criteria SC-039–SC-051 reference functional requirements and use objective conditions such as zero unmanaged routes, route lifecycle observability, and dependency-direction checks.
- [x] PASS — The new data-sovereignty success criteria SC-052–SC-072 reference functional requirements; the scenarios in User Stories 14–15 map individually to applicable FRs and SCs.

## Constitution v2.3.0 and Preservation

- [x] PASS — Platform Event Bus authority, versioned Integration Events, publisher independence, multiple subscribers, Domain Event boundaries, and duplicate handling are explicit (FR-012–FR-017, FR-055–FR-056).
- [x] PASS — Constitutional Outbox coordination, at-least-once delivery, idempotent consumption, and the prohibition on a generic exactly-once promise are explicit (FR-014, FR-059; SC-023–SC-024, SC-029).
- [x] PASS — Tenant context/isolation and module-governance boundaries are preserved across events, module dependencies, lifecycle, Gateway requests, and DIP certification (including FR-002, FR-022–FR-024, FR-053, FR-061, FR-070, FR-077, FR-082, FR-088).
- [x] PASS — API-first → MCP-second → CLI/GUI and authoritative application capability boundaries are preserved; the Gateway does not authorize business operations or replace the Event Bus (FR-065, FR-077, FR-079).
- [x] PASS — Gateway and DIP requirements match Constitution v2.3.0: module-owned canonical contracts; governed Gateway publication; no artificial APIs; no product-specific Domain/Application dependency; inner-owned ports; adapter-contained vendor models; responsibility boundaries without mandated directory names (FR-071–FR-091).
- [x] PASS — Constitution v2.3.0 explicitly establishes Module Autonomy & Data Sovereignty alongside the existing cross-module persistence, DIP, and tenant-isolation principles; the specification preserves those boundaries (FR-092–FR-120).
- [x] PASS — The named Module Autonomy & Data Sovereignty principle is normative in Constitution v2.3.0 (including ownership, isolation, projections, lifecycle, certification, and AI-agent governance); the specification aligns with it.
- [x] PASS — RabbitMQ, OpenAPI, and the named Foundation stack are intentional constitutional constraints, not evidence that the Gateway product has been selected. FR-080 explicitly defers selection to an ADR and says the specification must not compare or select products.
- [x] PASS — This correction updates only the existing specification and requirements checklist; it does not edit the Constitution, plans, tasks, templates, or application code.

## Module Autonomy & Data Sovereignty Validation

- [x] PASS — FR-092–FR-120 cover private-state ownership, authoritative mutation, governed cross-module reads, derived projections, tenant isolation, independent schema evolution, credentials, lifecycle, certification, observability, and agent refusal behavior.
- [x] PASS — Logical ownership and enforceable isolation are mandatory, while shared physical infrastructure is allowed and the physical database topology is explicitly deferred (FR-098–FR-099; SC-058; clarification 2026-11-23).
- [x] PASS — The sovereignty lifecycle requirements defer applicable retention and other handling to module/deployment/data-classification policy and select no universal lifecycle choice (FR-108, FR-112; SC-067).
- [x] PASS — No platform-wide numeric RPO/RTO is specified; objectives remain deployment-specific (clarification 2026-11-23; SC-036 and Assumptions).
- [x] PASS — Projection freshness/staleness handling is required to be defined and observable where applicable, without a platform-wide numeric target (FR-102, FR-119; SC-069).
- [x] PASS — Integration Event retention/archival is governed by configurable event and deployment policies; no universal event-retention period or module-data lifecycle choice is established. The existing seven-year audit-log retention remains a separate Constitution-aligned platform requirement.

## Acceptance-Coverage Resolution

- [x] PASS — FR-105 preservation is verified by User Story 15 Scenario 9, which requires projection, migration, backup, restore, export, analytics, archive, and dead-letter artifacts to preserve applicable classification, retention, tenant isolation, and access controls and remain inaccessible to unauthorized modules, principals, and tenants. Scenarios 9–10 trace to FR-105, FR-112, and SC-067.
- [x] PASS — FR-120 broader scope is verified by User Story 14 Scenario 11 and current SC-072: both name AI engineering agents and other automated implementation tools and require refusal or approval prohibition for unresolved or prohibited persistence designs, including all listed sovereignty violations and reporting of the ownership/governance issue.

## Constitutional Control Resolution

- [x] PASS — FR-105, User Story 15 Scenario 10, and SC-067 require AES-256 protection for applicable sensitive Platform Core and module-owned persisted representations while preserving classification, tenant isolation, retention, and access controls without selecting an encryption mechanism.
- [x] PASS — FR-065 defines applicable state-changing idempotency, safe retry, duplicate-request, correlation/operation identity, concurrency, conflict, and error semantics; User Story 12 Scenarios 4–6 and FR-090 / SC-044 make them independently testable.
- [x] PASS — FR-090 and User Story 12 Scenarios 7–8 require applicable MCP contract and cross-channel governance tests; MCP composition remains permitted without one-to-one endpoint correspondence, and unexposed channels are not required.
- [x] PASS — FR-121, User Story 7 Scenario 10, and SC-073 specify CI enforcement of the Constitution's layer-based targets: Domain and Application each 85%, critical Domain and Application each 95%, Infrastructure 70%, Presentation 60%, and generated-feature unit tests 85%, separately from mandatory test and security-boundary gates. Security or authorization code in critical Domain/Application scope receives the applicable 95% target; no blanket 95% target is invented for all security or authorization code.
- [x] PASS — User Story 4 Scenarios 2, 3, 8, and 9 each map separately to applicable FRs and SCs, removing the nested traceability ambiguity.
- [x] PASS — FR-033, FR-077, FR-105, SC-015, and SC-044 preserve applicable constitutional sensitive-operation auditing, secret rotation, input validation, output encoding, and sensitive-data encryption controls.

## Mandatory Channel Exposure Gate

- [x] PASS — FR-090 and SC-044 require all applicable contract, architecture, security, governance, and channel gates to pass before new or materially changed capability exposure; failed, missing, expired, or stale mandatory gates prevent publication or activation.
- [x] PASS — FR-078 and User Story 11 Scenario 11 gate Gateway route creation, publication, activation, new API versions, and changed contracts on mandatory validation.
- [x] PASS — FR-090 and User Story 12 Scenario 10 gate MCP tools, resources, and prompts on the canonical contract and applicable MCP compatibility and governance tests without requiring one-to-one endpoint correspondence.
- [x] PASS — FR-090, SC-044, and User Story 12 Scenarios 11–13 require applicable implemented-channel and cross-channel governance tests before release without requiring nonexistent channels.
- [x] PASS — FR-090 and User Story 12 Scenarios 14–15 require revalidation after material changes and governed disablement, withdrawal, or reconciliation when exposure eligibility is invalidated.
- [x] PASS — FR-078 and User Story 11 Scenario 10 preserve last-validated Gateway outage behavior without permitting new or changed route or contract exposure.

## Overall Assessment

**Status**: PASS — The specification aligns with Constitution v2.3.0 and retains 15 stories, with FR-001–FR-121 and SC-001–SC-073. C1–C4 and T1 and the mandatory pre-exposure gate are supported by the explicit acceptance, requirement, success-criterion, and CI evidence above; no required checklist item remains unresolved.

**Scope note**: This review compares the current on-disk specification with Constitution v2.3.0. No Gateway product, physical persistence topology, or other intentionally deferred implementation decision is selected.
