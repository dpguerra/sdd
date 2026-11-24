# Implementation Plan: Platform Core Foundation

**Feature**: `001-platform-core-foundation` | **Date**: 2026-11-23 | **Spec**: [spec.md](./spec.md)

**Git branch at planning**: `005-sync-module-data-sovereignty`.

## Summary

Plan a contract-first, multi-tenant modular monolith for tenant and identity management,
governed synchronous APIs through the Platform API Gateway, asynchronous Integration
Events through the Platform Event Bus, reviewed module lifecycle, configuration,
governance, documentation and developer portals, and an extension SDK. Module-owned
contracts remain independent of Gateway product and deployment topology. Dependency
Inversion and module-owned private data apply to Core and all modules. Every implemented
channel is subject to pre-exposure and revalidation gates. Parent-child relationships are organizational
only; delegated child administration requires an explicit scoped grant and executes in
child tenant context. The Platform Operator creates root and child tenants in v1,
suspends and reactivates tenants, and bootstraps the initial Tenant Admin when none
exists; non-admin users do not by themselves prevent bootstrap. Tenant Admins may
request child provisioning only through a future explicitly governed capability;
the request does not create or authorize the child. Business modules and a general administrative
dashboard are out of scope.

## Technical Context

**Language/Version**: Node.js 22+ and TypeScript 5+ with constitution-mandated strict
compiler options, including `noUncheckedIndexedAccess` and `exactOptionalPropertyTypes`.

**Primary Dependencies**: NestJS with Fastify; Prisma; PostgreSQL; Redis; OpenTelemetry;
RabbitMQ behind an application-owned messaging port; JWT and refresh-token support;
external secret management; a market-standard API Gateway selected by ADR. Kong is an
evaluation candidate only. Kafka is a possible future alternative, not a transparent
substitute. Frameworks, ORM, broker clients, Gateway product APIs, and providers stay
in infrastructure adapters.

**Storage**: PostgreSQL with tenant predicates and row-level security as defense in
depth; Redis for appropriate tenant-keyed transient state; durable module-owned Outbox,
consumer-owned Inbox where applicable, delivery obligations, audit records, and event
archive. Each module has an enforceable private logical persistence boundary even when
physical infrastructure is shared. Database-versus-schema topology requires a separate
ADR. Unprocessed deliveries are never discarded by retention or uninstall.

**Testing**: Unit, real-adapter integration, OpenAPI/JSON Schema contract, architecture,
cross-channel security, concurrency, recovery, accessibility, performance, and end-to-end
tests. Jest and Supertest are candidate tools from the existing plan; confirm package
selection when implementation is scaffolded. CI independently enforces the Constitution
v2.3.0 targets: Domain and Application each 85%, critical Domain and Application each
95%, Infrastructure 70%, Presentation 60%, and generated-feature unit tests 85%.
Security/authorization code receives 95% when classified in a critical Domain or
Application scope; there is no blanket 95% target for all security code.

**Target Platform**: Docker deployment, Kubernetes-ready; TLS and externally managed
secrets.

**Project Type**: API-first modular monolith with bounded contexts, a governed Gateway,
and governed MCP, CLI, portal, SDK, and automation adapters. REST is the default
external API style; an alternative protocol requires an ADR and equivalent
machine-readable contract. No business module is implemented in this feature.

**Performance Goals**: Use SC-001 through SC-005, SC-009 through SC-011, and SC-014
with their stated thresholds and qualifiers. Record the deployment's
active-tenant capacity and concurrency profile; there is no platform-wide tenant cap.
Establish workload and environment conditions before implementation and make no
unverified performance claims.

**Constraints**: Tenant isolation, delegation, and authorization fail closed; source
dependencies point inward; module and Core contracts are independently owned; external
business routes use the governed Gateway; control-plane outages retain only the last
validated route configuration and pause route changes while application capabilities
fail closed when disabled or unavailable. Audit is immutable; only exact
operator-reviewed artifacts can be installed; reviewer/approver separation follows
deployment policy; event delivery is at least once with idempotent effects and no
historical backfill to new subscriptions; failed optional modules and their dependents
stay unavailable without stopping unaffected modules; uninstall remains pending while
assigned events are unprocessed; database URL changes are staged until restart; the
in-scope documentation and developer portals meet WCAG 2.2 Level AA.

**Scale/Scope**: Foundation only. Startup with 10+ modules and governance checks for
50+ modules are explicit test cases, not production capacity commitments. V1 sets no
platform-wide active-tenant limit; each deployment documents and tests its capacity
and concurrency profile. Each production deployment defines and tests its own recovery
objectives; v1 sets no platform-wide numeric data-loss or restoration-time target.

## Constitution Check

**Initial architecture gate: conditional pass.** No Constitution exception is proposed.
The tenant-provisioning actor clarification is resolved; implementation and release
remain subject to the applicable design, test, and operational gates below.

- Use the contract-first sequence: resource/capability model, canonical API contract,
  application port/use case, inbound adapter, contract/architecture tests, Gateway
  publication, then agent and presentation channels where applicable.
- REST is the default external API style and uses OpenAPI. An alternative synchronous
  protocol requires an ADR and equivalent versioned machine-readable contracts.
- Each module owns its canonical API and business semantics; Platform Core governs
  external Gateway publication and never implements module business capabilities.
  Modules without external synchronous capabilities need no artificial API.
- External business routes are Gateway-only; Gateway acceptance is not authoritative
  authorization. Application capabilities revalidate identity, tenant, policy, and
  authorization and fail closed.
- A data plane may use its last successfully validated routes for available
  capabilities during control-plane outage; route changes pause and application
  authorization remains authoritative.
- Every implemented channel must pass its applicable contract, architecture, security,
  governance and channel compatibility gates before new or materially changed
  capability exposure; failed, missing, expired or stale gates prevent activation.
  MCP compatibility permits composition, and absent channels are not required.
- Dependency Inversion applies uniformly to Platform Core and every module. Inner layers
  own meaningful capability ports; infrastructure adapters implement them. No vendor
  or concrete infrastructure dependencies leak into Domain or authoritative Application
  code.
- The Platform Event Bus remains the only governed asynchronous cross-module channel.
  Outbox publication, at-least-once delivery, idempotency, and assigned-delivery
  obligations remain intact.
- Module Autonomy & Data Sovereignty requires one authoritative owner per business fact,
  independently governed private persistence, owner-controlled migrations and credentials,
  explicitly derived local projections, and publisher/consumer ownership of Outbox/Inbox.
  Shared physical infrastructure never weakens logical or tenant isolation.
- Tenant operations, delegated grants, audit, channel adapters, reviewed-code
  lifecycle, security, and resilience preserve their constitutional controls.
- Unit, integration, contract, architecture, accessibility, performance, recovery,
  security, and end-to-end evidence are required; coverage targets follow the
  Constitution.
- The [requirements checklist](./checklists/requirements.md) is 57/57 checked; it
  assesses specification quality only, not implementation or release readiness.
- **Tenant-provisioning authority**: User Story 1 maps the Organization Administrator
  persona to the platform-global Platform Operator for tenant provisioning,
  suspension/reactivation, and initial Tenant Admin bootstrap, not to a new role.
  The operator creates root and child tenants in v1, suspends and reactivates tenants,
  and bootstraps the initial Tenant Admin when none exists; non-admin users do not
  by themselves prevent bootstrap. A Tenant Admin cannot create a root tenant and may
  request child provisioning only through a future explicitly governed capability.
  The request creates no tenant and grants no creation authority; an explicit policy
  after v1 would be required to delegate scoped child creation. Hierarchy and existing
  child-admin grants confer no provisioning or global administration authority.

### Post-design assessment

**Conditional design pass.** The design must preserve child-owned delegated access,
digest-bound review and approval, WCAG 2.2 AA, deployment-specific recovery and capacity,
delivery obligations, module-owned contracts, data sovereignty and uniform Dependency
Inversion. It must also cover session-scoped revocation, tenant-qualified identity,
sensitive-data protection and channel exposure gates. No Constitution exception is
proposed. The implementation and evidence described below remain release prerequisites,
not claims of completed tests.

The refreshed OpenAPI 3.1 contract passed semantic validation, including its
relative Integration Event schema reference. The module declaration and Integration
Event schemas passed Draft 2020-12 schema checks, and the quickstart's module
declaration fixture validated against its schema. Eleven HTTP examples were checked
against their declared operations and required headers. These checks do not replace
implementation, security, compatibility or release tests.

**Release gate: BLOCKED pending implementation evidence.** The design artifacts and checklist do
not demonstrate that application code, security, architecture, contract, accessibility,
recovery, or cross-channel tests exist or pass. Establish performance test conditions
before treating the stated thresholds as verified.

## Design and Delivery Approach

1. Define canonical, versioned resource and operation contracts. Platform Core owns its
   platform contracts; each module owns its own synchronous API contract, request,
   response, and error semantics. Authentication bootstrap validates credentials
   without requiring a pre-existing access token.
   Platform-scoped operations require explicit platform authority; tenant-scoped
   operations enforce tenant identity and permissions on every channel. Under the
   v1 policy, Platform Operator authority is required for root and child creation,
   suspension/reactivation, and initial Tenant Admin bootstrap. Future governed requests
   for child provisioning do not themselves create tenants or confer authority.
2. Implement context-specific use cases and inner-owned capability ports, then inbound
   API adapters and outbound infrastructure adapters. Apply Dependency Inversion to
   Core, every module, and standalone extensions without creating artificial ports for
   pure domain collaborators. Use the same guards and application controls for direct
   in-process adapters as for HTTP, without mandating loopback HTTP calls.
3. Use PostgreSQL tenant predicates and row-level security, with transaction-scoped
   tenant context; validate pooled-connection reuse and isolation in integration tests.
   A global path must be explicit, separately authorized and audited.
4. Model the tenant hierarchy separately from authorization. A child tenant's
   authority creates/revokes a scoped grant for its direct parent. Revalidate each
   grant per operation, intersect it with the actor's permissions, run all child data
   access under the child tenant context, and retain parent actor/grant attribution in
   audit. Do not infer access from ancestry or make grants transitive.
5. Persist business changes and outbox records atomically. Use RabbitMQ behind a port
   and stable event identities for idempotent subscribers. A new subscription receives
   no historical events, while already-assigned delivery obligations remain subject to
   governed retry/replay and survive archive or module drain.
6. Accept authenticated partner release submissions without core-repository access;
   compute and retain the exact artifact digest. Record review and approval as distinct
   attributable decisions; at approval, enforce the deployment's reviewer/approver
   separation policy and capture both identities and its policy version. Publication
   and installation revalidate the active approval for that exact digest. Validate
   manifests and dependency graphs before activation. Shared deployments have
   tenant-owned enablements; removing one tenant's enablement must not stop another
   tenant's modules. Failed optional modules and their transitive dependents remain
   unavailable. In-process module boundaries are not a hostile-code sandbox.
   The submission starts `pending_review`; only a Platform Operator may transition it
   to `approved` after positive review and separate approval, or to `rejected` after
   a negative decision, revoke a pending, approved or published submission, or publish
   an approved submission after manifest validation and active exact-digest approval.
   `rejected` and `revoked` are terminal, and a resubmission or changed approved
   artifact is a new submission. Review, approval, publication and revocation use
   the current submission version and applicable idempotency controls; an invalid
   transition returns 409 `lifecycle_conflict`, while stale or missing `If-Match`
   returns 412 or 428, respectively, without mutation.
   Persist immutable, redacted transition evidence. Submission approval and catalog
   publication do not replace separate certification, installation, route lifecycle
   or mandatory channel-exposure gates; revoked exposure is reconciled without
   discarding assigned delivery obligations.
7. Resolve configuration by source priority, then scope specificity. Changes to a
   database URL are validated and staged until restart. Keep secrets in external
   management and out of configuration audit payloads; authorize and audit developer
   credential issuance, expose its secret only once and store a verifier or secret reference.
8. Release channel adapters only after their underlying canonical contract and controls
   exist. Include documentation and developer portals, conforming to WCAG 2.2 Level AA;
   exclude a general admin dashboard. Do not implement the separate feature 002 RACI
   workflow as part of this foundation.
9. Authenticate using short-lived JWT access tokens and refresh tokens. Authorize in
   shared application capabilities, not only controllers; use explicit errors, input
   validation, output encoding, transport encryption and encryption of sensitive data
   at rest. Record immutable, redacted audit evidence and propagate correlation and
   trace context across every channel and message.
10. Put infrastructure and external integrations behind ports and adapters with bounded
   timeouts, retries, circuit breakers and bulkheads. Do not convert an unavailable
   security, audit or tenant control into a successful operation.
11. Before each production deployment, document its measurable data-loss and
    restoration-time objectives and validate them with recovery tests. Do not introduce
    a platform-wide numeric objective; define operational ownership, test type and
    cadence per deployment.
12. Publish externally consumable business APIs exclusively through the governed
   Platform API Gateway. Platform Core owns the Gateway-management application port;
   a product-specific infrastructure adapter performs route registration, update, and
   withdrawal. Gateway configuration owns edge policy, not business semantics,
   application authorization, tenant authorization, or domain rules. Select a mature
   Gateway product only through an ADR; Kong is a candidate, not a dependency.
13. Gate Gateway route creation, publication and activation, new API versions and
   changed contracts on all mandatory applicable tests and lifecycle checks. Treat
   Gateway publication as a lifecycle with contract, version, compatibility,
   availability, and observable outcome checks. During control-plane outage, retain
   the last validated data-plane routes only for available capabilities, pause route
   changes, fail closed for disabled or unavailable application capabilities, and
   surface discrepancy and recovery. Do not bypass the Gateway through module
   listeners or claim an unconfirmed publication or withdrawal succeeded.
14. Each bounded context owns its authoritative data, private persistence adapters and
    credentials or equivalent identities, migrations and Outbox; consumer Inbox and local
    projections remain consumer-owned. Explicitly classify projections as derived, track
    their source/version/tenant and protect them against duplicate events. Each applicable
    module design defines consistency expectations, stale/unavailable-source behavior,
    incompatible versions, replay, reconciliation, rebuild and observable health without
    imposing a universal freshness target. Never use
    another module's database, schema, repository, ORM, migrations or privileged runtime
    credential as an integration contract. Record the physical-isolation ADR before
    provisioning; shared PostgreSQL is acceptable only with enforceable logical ownership.
15. Enforce deployment-wide case-insensitive slug uniqueness and tenant-qualified,
    case-insensitive e-mail uniqueness atomically, including concurrent writes. Require
    tenant-qualified sign-in. Choose and document normalization and storage comparison
    before implementation rather than assuming application checks prevent races.
16. Associate access and refresh tokens with a session. Logout invalidates that session's
    refresh tokens and immediately rejects its already-issued access tokens for subsequent
    requests, without invalidating other sessions. Authorization fails closed when
    required current session status is unavailable. Select revocation persistence,
    consistency, failure handling and retention before implementation.
17. Deny suspended tenants' initiated business operations. Allow explicitly authorized
    background work and maintenance under the affected tenant context, with isolation,
    audit and delivery obligations intact; decide how that authorization is enforced
    before implementing the worker paths.
18. Complete canonical contract and architecture tests, then applicable security,
    governance and channel compatibility tests before exposing or materially changing
    any capability. Validate API, MCP, CLI, GUI, SDK, automation and external
    integrations only where implemented. MCP compositions preserve canonical semantics;
    cross-channel tests reject privileged bypass. Invalidate eligibility on relevant
    contract, policy, tenancy, certification or lifecycle changes; failed, stale, expired
    or missing gates block activation, and existing exposure is withdrawn, disabled or
    reconciled under FR-078 and FR-090. Last-validated Gateway outage behavior cannot
    activate new or changed routes or versions.
19. Define each applicable state-changing contract's idempotency, operation identity,
    duplicate/retry, concurrency, stale/conflict and error behavior. Use a governed
    protection only where needed; do not require idempotency keys for every operation.
    Preserve classification, tenant controls and AES-256 protection for applicable
    sensitive persisted state and copies, with the encryption mechanism selected later.

## Phased Delivery

1. **Planning and design**: Reconcile specification, Constitution, research, data model
   and canonical contracts. Resolve tenant-provisioning authority and record the
   Gateway-product and physical-isolation ADRs before their dependent implementation.
   Define deployment-owned retry/dead-letter policy, capacity and recovery objectives.
2. **Foundation and identity**: Establish context boundaries, tenant isolation,
   session-aware authentication, audit, configuration and observability with their
   unit, contract and integration tests.
3. **Module and event boundaries**: Implement reviewed module lifecycle, ownership
   certification, local persistence, event contracts, Outbox and idempotent subscribers;
   verify sovereignty and tenant isolation with architecture and integration tests.
4. **Governed exposure**: Implement canonical capability adapters, Gateway publication
   and applicable channels; require pre-exposure and revalidation evidence, channel
   compatibility and lifecycle recovery tests before activation.
5. **Release evidence**: Verify independent coverage and test gates, accessibility,
   deployment-specific performance and recovery objectives, and full end-to-end flows.
   Tests accompany the corresponding implementation rather than being deferred to
   this final phase.

## Validation Strategy

- Map the design to FR-001–011 (tenancy and identity), FR-012–017 (events),
  FR-018–028 (modules and scaffolding), FR-029–039 (configuration and governance),
  FR-040–054 (portals and SDK), FR-055–070 (communication governance and delegated
  tenant access), FR-071–080 (Gateway governance), FR-081–091 (Dependency Inversion,
  certification, channel gates and observability), FR-092–120 (module data sovereignty),
  and FR-121 (constitutional test assurance). Include explicit acceptance cases
  for requirements not covered by a user-story scenario.
- Verify each tenant operation and asynchronous subscription rejects missing, mismatched
  and unauthorized cross-tenant contexts; test delegated grant creation/revocation,
  scope limits, child-context execution, non-transitivity, suspended/re-parented tenants,
  concurrent requests, and pooled connection reuse.
- Verify API bootstrap, RBAC, platform authority, credential issuance/revocation,
  configuration secret redaction, output encoding, transport and at-rest protection,
  audit integrity and correlation/trace propagation.
- Verify Platform Operator root and child creation, suspension/reactivation, and
  initial Tenant Admin bootstrap; deny those operations to tenant-scoped roles in v1.
  Deny attempts by a Tenant Admin to grant platform-global authority to itself or
  another tenant role, with no change in effective authority.
  Test bootstrap with no users, with only non-admin users, and with an existing Tenant
  Admin; non-admin users alone do not prevent it, but an existing Tenant Admin does.
  If a future governed child-provisioning request capability is implemented, verify an
  authorized Tenant Admin request has no creation or authorization effect. Hierarchy
  and existing child-administration grants do not authorize creation.
- Test duplicate tenant slugs across the deployment and duplicate e-mail within a tenant
  ignoring case, including concurrent writes and separate-tenant accounts; reject
  unqualified sign-in. Verify tenant suspension blocks tenant-initiated operations but
  permits only authorized background processing in the correct tenant context.
- Test two sessions for the same user: logout revokes the targeted session's refresh and
  already-issued access tokens immediately while the other session remains usable.
  Simulate session-status unavailability and verify fail-closed authorization and
  observable failure.
- Verify event outbox crash recovery, duplicate and concurrent deliveries, tenant-scoped
  subscriptions, no historical backfill to new subscriptions, dead-letter recovery,
  retained delivery obligations and uninstall drain.
- Verify partner submission, platform-computed digest integrity, separate review and
  approval, same-identity denial only when deployment policy requires it, audit identity
  recording, invalid modules, dependency cycles, failed optional modules and dependents,
  governance upgrades and non-weakening security controls.
- Exercise all FR-019 submission transitions and terminal-state denials, exact retries,
  concurrent updates, stale/missing submission ETags and attributable audit evidence;
  verify new-submission resubmission, gate independence and governed revocation of
  already-published releases.
- Test OpenAPI and integration-event contracts, backwards compatibility, idempotency
  and concurrency. Check equivalent authorization and audit behavior through each
  exposed channel and enforce dependency boundaries with architecture tests.
- Test safe duplicate requests, conflicting concurrent mutations, unsafe retry and
  stale-state errors across applicable contracts. Require MCP semantic contract tests
  where exposed, including compositions, and cross-channel governance tests for the
  channels actually present; no GUI or CLI is required only to run these tests.
- Test all new or materially changed capability exposures against mandatory contract,
  architecture, security, policy, tenancy and applicable channel gates before activation.
  Reject failed, missing, expired or stale evidence; revalidate changes and reconcile
  invalidated exposure. Verify no new or changed route or version is activated during a
  Gateway control-plane outage.
- Test certification rejection of private-state cross-module reads or writes, shared
  authoritative tables, foreign migrations and overprivileged credentials. Verify
  derived projection ownership, idempotency and tenant/classification propagation,
  Outbox/Inbox ownership, extraction readiness and AES-256 for applicable sensitive
  primary, projection, backup, restore, export, archival and dead-letter persistence.
  Validate each constitutional coverage scope and mandatory test gate independently.
- Verify every externally published business route maps to a module-owned or
  Platform-Core-owned canonical API contract and supported version. Test route
  registration, update, and withdrawal, compatibility rejection, exclusively governed
  Gateway exposure, topology-independent consumers, and the narrowly scoped health
  endpoints. Confirm modules without an external synchronous capability do not acquire
  an artificial API requirement.
- Simulate Gateway control-plane loss with active data planes: previously validated
  routes continue only for available capabilities, route changes pause, application
  authorization denies disabled or unavailable capabilities, and outage/recovery
  status is observable. Verify no module listener, Gateway edge decision, or agent
  channel bypasses application authorization or Gateway governance.
- Run architecture certification against Core and module samples: permit
  Application-owned ports implemented by Infrastructure adapters and governed
  application capability calls; reject prohibited Domain framework/ORM/broker/Gateway/
  provider imports, concrete Application adapter dependencies, vendor-owned ports,
  infrastructure leakage in canonical contracts, and unmanaged routes. Allow pure
  domain collaborators without artificial interfaces.
- Verify the measurable Gateway, Dependency Inversion, observability, and deployment
  outcomes in SC-039–SC-051, including zero unmanaged routes and prohibited dependency
  violations, complete Gateway publication coverage, the product-selection ADR, and
  deployment-specific capacity evidence.
- Verify SDK type safety, automatic module instrumentation, and the scaffold-to-first
  valid Integration Event workflow against SC-012, SC-016, and SC-017, including the
  stated two-hour completion target in a documented environment.
- Verify a representative external request propagates validated identity, tenant,
  correlation, and trace context across Gateway, inbound adapter, application,
  infrastructure, and applicable event publication without leaking credentials,
  secrets, or cross-tenant data. Keep traffic limits and quotas deployment-policy
  driven unless assigned by policy.
- Exercise the applicable performance criteria under recorded workload and environment;
  include deployment-specific active-tenant capacity and concurrency, without
  introducing a global tenant-count ceiling; document gaps before task generation.
  Verify each deployment's recorded recovery objectives against measured
  recovery-test results without assuming common numeric targets. Gate portal release
  on WCAG 2.2 AA checks, including automated regression tests and human evaluation of
  representative pages and complete flows.

## Operational Risks

- Tenant context must not leak between reused connections, requests or message handlers.
- A parent-child relationship can be mistaken for blanket access. Check an explicit,
  current, operation-scoped grant on every delegated request and use only the child
  tenant context for data access.
- The hierarchy's maximum depth is unspecified. Keep delegation direct and non-transitive;
  do not introduce a numeric depth limit without an approved requirement.
- Idempotency must be durable and atomic with local effects, not merely an in-memory cache.
- A session-status dependency outage must fail closed rather than accept logged-out tokens;
  determine consistency and recovery behavior before implementing session checks.
- Case-insensitive uniqueness needs concurrency-safe storage enforcement and a documented
  normalization policy. Suspended-tenant workers must not inherit blanket authority.
- A module's shared physical database is not a shared business boundary. Choose and
  verify physical topology separately without weakening logical isolation; protect all
  applicable sensitive persisted representations using AES-256.
- A permanently failed subscriber can hold an uninstall pending indefinitely. Alerting
  and authorized recovery are necessary; automatic discarding would violate the selected
  delivery and uninstall requirements.
- A standards grace period cannot override mandatory tenant isolation or security.
- Changes to critical infrastructure settings must not be reported as applied before
  restart, and audit records must not expose secret values or issued credentials.
- Module approval can be incorrectly reused across changed artifacts or evade
  separation-of-duties rules; bind decisions to immutable digests and enforce policy
  server-side.
- Recovery readiness cannot be inferred without deployment-owned objectives and test
  evidence; missing targets or failed tests must remain visible as release gaps.
- Portal conformance cannot be established by automated scans alone; preserve manual
  evaluation and the WCAG 2.2 AA release gate.
- A Gateway control-plane outage may leave data-plane routes active with stale
  configuration. Preserve last-validated behavior only for still-available
  capabilities, pause configuration changes, enforce authorization in application
  capabilities, and expose the discrepancy and recovery state.
- Gateway acceptance is not application authorization. Do not let edge policies,
  route configuration, alternate module listeners, MCP, or SDK behavior replace
  tenant-aware application checks or governed publication.
- Vendor-specific Gateway assumptions can leak through routes, ports, contracts, or
  the Extension SDK. Keep product models in the Gateway infrastructure adapter and
  select the product through an ADR before product-specific implementation.
- Tenant capacity is deployment-specific. Record each deployment's active-tenant
  capacity and concurrency profile rather than inferring a global limit from scale tests.
- Tenant-scoped roles must not acquire platform authority through hierarchy,
  child-administration grants, or a child-provisioning request. Any future delegated
  child-creation policy requires explicit governance and scoped authorization.
- Define a deployment-owned idempotency-retention policy sufficient for the supported
  retry and asynchronous completion windows, including applicable retries after
  completion. Never expire an in-progress asynchronous operation's protection before
  completion; test the policy without imposing a platform-wide duration.

## Project Structure

### Documentation

```text
specs/001-platform-core-foundation/
├── spec.md
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   ├── README.md
│   ├── openapi.yaml
│   ├── integration-events-v1.yaml
│   └── module-api-declarations.schema.json
└── checklists/
    └── requirements.md
```

### Source Code

```text
src/
├── contexts/              # business-aligned bounded contexts
│   ├── tenant/
│   ├── identity-access/
│   ├── audit/
│   ├── eventing/
│   ├── api-publication/
│   ├── module-catalog/
│   ├── configuration/
│   └── governance/
├── channels/               # governed API, MCP, CLI and portal inbound adapters
├── shared/
│   ├── application/        # common ports and cross-cutting use-case support
│   ├── infrastructure/     # Prisma, broker, Gateway and provider adapters
│   └── observability/
└── main.ts                 # composition root
test/
├── unit/
├── integration/
├── contract/
├── architecture/
├── accessibility/
├── performance/
└── e2e/
```

**Structure Decision**: Adopt the constitution's context-first layout with domain,
application, presentation and infrastructure boundaries inside each bounded context.
Shared components remain cross-cutting ports/adapters rather than a technical-module
home for business logic. Gateway product APIs remain behind the Core-owned
Gateway-management port. Channel adapters consume canonical application capabilities
and never own authoritative rules. The tree describes planned files rather than
existing implementation.

## Complexity Tracking

No constitution exceptions have been approved.
