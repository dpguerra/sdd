# Research: Platform Core Foundation

Planning decisions below interpret [spec.md](./spec.md) under
[Constitution v2.3.0](../../.specify/memory/constitution.md). They do not authorize
unreviewed modules or weaken tenant isolation. These are local design evaluations,
not independent performance benchmarks or vendor certification claims.

## Application and channel boundaries

- **Decision**: Start with a modular monolith organized by bounded context. Define
  tenant, identity/access, audit, event, module, configuration, governance and
  documentation capabilities behind application ports. Publish versioned REST/OpenAPI
  contracts first; MCP, CLI, portals and SDK consume the same governed application
  capabilities and are tested against those contracts.
- **Rationale**: Contracts and ports enable extraction without duplicating decisions.
  An in-process adapter can call a port rather than perform loopback HTTP, provided all
  contract controls are preserved.
- **Alternatives considered**: Deploy services immediately (premature operational
  complexity); implement CLI or MCP independently (violates channel governance).

## Governed API Gateway and contract ownership

- **Decision**: Use the governed Platform API Gateway as the sole external entry
  point for published Core and module business APIs. Modules own their canonical,
  versioned machine-readable contracts and application capabilities; Platform Core
  owns publication governance, validation, route lifecycle coordination, edge-policy
  integration, and platform-wide observability. REST is the default external API
  style and uses OpenAPI. An alternative synchronous protocol requires an ADR and an
  equivalent versioned machine-readable contract.
- **Rationale**: The Gateway controls exposure without becoming a second business
  contract or replacing the module application capability. Stable contracts keep
  consumers independent of monolith/service topology.
- **Alternatives considered**: Direct unmanaged module listeners (bypass governance);
  Core-owned generic module business controllers (duplicate bounded-context contracts);
  a bespoke Gateway implementation (requires an ADR demonstrating market products
  cannot satisfy platform requirements).

## Gateway product and control-plane decisions

- **Decision**: Do not select or compare a Gateway product in this plan. Record a
  product-selection ADR as a prerequisite to product-specific adapter work. Evaluate
  the Constitution's OpenAPI, declarative configuration, container/Kubernetes,
  authentication, traffic policy, observability/OpenTelemetry, availability, route
  lifecycle automation, GitOps, upgrade, control/data-plane, and vendor-coupling
  criteria; Kong remains an initial candidate only.
- **Control-plane outage**: Continue using the last successfully validated data-plane
  configuration for capabilities that remain available; pause route registration,
  update, and withdrawal until control-plane recovery. Application capabilities
  continue to enforce current authorization and fail closed for disabled or unavailable
  capabilities. Surface and reconcile the control/data-plane discrepancy.
- **Rationale**: This preserves existing validated traffic while retaining application
  authority and avoids coupling business logic to the Gateway control plane.
- **Alternatives considered**: Fail all external traffic during any control-plane
  outage (unnecessary when a validated data plane remains available); apply stale
  routes to unavailable capabilities (violates lifecycle and authorization gates).

## Dependency inversion and adapter boundaries

- **Decision**: Apply DIP uniformly to Platform Core and all modules, regardless of
  ownership, repository, process, or deployment. Application use cases own meaningful
  outbound ports; infrastructure adapters implement them. Keep persistence, broker,
  Gateway, and provider/vendor types outside Domain and authoritative Application
  policy. Add architecture certification for forbidden imports, port ownership,
  unmanaged routes, and contract/route correspondence.
- **Rationale**: In-process deployment does not justify implementation coupling.
  Inward-owned ports allow the modular monolith to evolve without embedding technology
  semantics in business capabilities.
- **Alternatives considered**: Vendor-shaped interfaces defined by Infrastructure
  (reverses dependency direction); interface-per-class abstractions (adds no useful
  boundary); product-specific Gateway or broker types in module business APIs.

## Tenant isolation and authorization

- **Decision**: Resolve authenticated tenant context on every tenant operation; deny
  missing, invalid or mismatched context. Use tenant-aware repository ports, explicit
  tenant predicates and PostgreSQL row-level security as defense in depth; establish and
  clear database session context transactionally for pooled connections. Explicitly
  identify and separately authorize global/platform operations. Revalidate tenant
  context in asynchronous consumers and enforce it on caches and event subscriptions.
  Apply the stakeholder-approved default role grants in the canonical contract,
  deny unspecified access, and limit credentials to their owner's current authority.
- **Provisioning authority**: The Platform Operator is platform-global and creates
  root and child tenants in v1, suspends/reactivates tenants, and bootstraps the
  initial Tenant Admin when none exists; non-admin users do not by themselves prevent
  bootstrap. Organization Administrator is a user-story persona mapped to Platform
  Operator for provisioning, suspension/reactivation, and initial bootstrap, not a
  separate role. A Tenant Admin cannot create a root tenant and may request child
  provisioning only through a future explicitly governed capability; the request does not create or
  authorize the child. An explicit delegated-authority policy after v1 may grant
  scoped child creation. Hierarchy or an existing child-administration grant confers
  neither that permission nor global administration authority.
- **Delegated administration**: Treat the parent-child link as organizational metadata,
  never as an authorization grant. A child tenant authority creates or revokes an
  explicit grant for its direct parent, listing allowed canonical operation permissions.
  Re-check the active grant on each request; intersect grant scope with the actor's
  parent-tenant authority and non-delegable platform rules. Execute with the child as
  the authoritative tenant context, while retaining the parent actor tenant and grant
  identity in audit evidence. Grants are not transitive; hierarchy changes invalidate
  grants that no longer match the direct parent relationship. Do not set an arbitrary
  numeric hierarchy-depth limit without an approved requirement.
- **Rationale**: Shared storage can remain efficient without relying on a single filter
  or mutable process-global context. Explicit, least-privilege delegation follows the
  general pattern in Microsoft's [Granular Delegated Admin Privileges guidance](https://learn.microsoft.com/en-us/partner-center/customers/gdap-introduction),
  where customer access is explicitly granted and scoped rather than implied by association.
- **Alternatives considered**: Tenant roles implicitly acquiring platform provisioning
  authority (violates the clarified role boundary); separate database per tenant (operational overhead);
  application filtering alone (single point of failure); implicit inherited parent
  access (violates the clarified no-implicit-access rule); child-data queries based on
  a parent filter (creates a broad cross-tenant access path).

## Tenant identity, suspension, and session revocation

- **Decision**: Enforce globally case-insensitive tenant-slug uniqueness and
  tenant-qualified, case-insensitive e-mail uniqueness atomically, including concurrent
  creation or updates. Sign-in requires tenant qualification. Select and document
  normalization, persisted uniqueness keys, and collision handling before implementing
  these contracts; do not assume locale-dependent comparisons.
- **Suspension**: Deny suspended tenants' initiated business operations. Allow only
  explicitly authorized background processing and maintenance under the affected tenant
  context, with audit, isolation, and event-delivery controls intact.
- **Sessions**: Bind access and refresh credentials to a session. Logout durably revokes
  only that session's refresh credentials and makes its already-issued access credentials
  invalid immediately for subsequent requests, without revoking other sessions. Each
  applicable authorization check must obtain sufficiently current session status; deny
  access if required session status cannot be established. Select the revocation store,
  failure recovery and safe retention strategy before implementation.
- **Rationale**: These outcomes follow the clarified specification and cannot rely on JWT
  expiry or application-side uniqueness checks alone.
- **Alternatives considered**: JWT expiry alone (does not ensure immediate logout);
  globally unique e-mail (forbids valid cross-tenant accounts); unrestricted background
  workers (bypasses suspension authorization).

## Module data sovereignty and persistence

- **Decision**: Each bounded context owns its authoritative data, private persistence
  ports, credentials or equivalent identities, migrations, Outbox and any consumer-owned
  Inbox. A shared PostgreSQL cluster is permissible only with enforceable logical ownership,
  tenant isolation and independently verifiable boundaries. Choose database-versus-schema
  topology in a separate physical-isolation ADR before provisioning.
- **Integration**: Use a canonical synchronous capability when an immediate authoritative
  result is inherent; otherwise consume governed Integration Events into consumer-owned,
  tenant-aware and idempotent derived projections. Preserve classification, retention and
  access restrictions on persisted copies and protect applicable sensitive data at rest
  with AES-256. Select the concrete encryption mechanism separately.
- **Rationale**: Physical co-location does not confer shared business ownership or authorize
  cross-module access, and projections must never silently become authoritative.
- **Alternatives considered**: Shared authoritative tables and cross-module repositories
  (violate ownership); physical isolation per module as a universal requirement (not
  required by the Constitution).

## Pre-exposure validation and contract semantics

- **Decision**: Gate each new or materially changed capability and each channel that
  actually exposes it on versioned canonical-contract, contract-test, architecture-test,
  applicable security/governance and channel-compatibility evidence. Fail closed for
  failed, missing, expired or stale evidence; revalidate material contract, policy,
  tenant-enforcement, certification or lifecycle changes. Reconcile or withdraw existing
  exposure under the governed lifecycle, without reporting failed gates as available.
  An outage permits only the last validated Gateway configuration for still-available
  capabilities and never new or changed route or version activation.
- **Contracts and tests**: Define applicable operation identity, idempotency, duplicate,
  retry, concurrency, conflict, stale-state and error behavior without forcing an
  idempotency key on naturally idempotent operations. A deployment-defined retention
  policy covers the supported retry and asynchronous completion windows, including
  applicable retries after completion; in-progress asynchronous protection cannot
  expire before completion. No universal duration is specified. MCP contract tests cover semantic
  compatibility, including composition; cross-channel governance tests cover only
  implemented exposures. Do not select storage or concurrency-control technology here.
- **Rationale**: Security and architecture guarantees must be established before exposure,
  not inferred from Gateway publication or a high coverage percentage.
- **Alternatives considered**: Post-publication testing (too late to prevent exposure);
  identical MCP/API endpoint mapping (unnecessarily forbids composition).

## Module lifecycle and isolation

- **Decision**: Use a reviewed-code modular monolith with manifest validation,
  dependency graph and lifecycle states. Disable a failed optional module and all
  transitive dependents while allowing the core and unaffected modules to operate.
  Apply capability, tenant and contract boundaries to module code; do not claim a
  security sandbox for malicious in-process code. Authorized partners submit
  releases through the platform; an operator reviews the exact artifact before
  publication or installation. Shared deployments have tenant-owned enablements,
  and removing one tenant's enablement must not stop other tenants' modules.
- **Review and approval**: Bind both decisions to the platform-computed digest of the
  immutable submitted artifact. Record review and approval as distinct, attributable
  decisions; approval requires a positive review of the same digest. Enforce the
  deployment's versioned separation-of-duties policy at approval time, and record both
  identities and the effective policy version. Publication and installation revalidate
  the active approval against the artifact digest. Approval remains a trust decision,
  not a sandbox or safety guarantee.
- **Submission lifecycle**: An authorized partner creates a new `pending_review`
  submission. A Platform Operator may transition `pending_review` to `approved`
  after positive review and separate positive approval of the exact digest, or to
  `rejected` on a negative review or approval; may transition `pending_review`,
  `approved`, or `published` to `revoked`; and may transition `approved` to
  `published` after manifest validation and active exact-digest approval. `rejected`
  and `revoked` are terminal. All other changes are denied; resubmission or a changed
  approved artifact creates a new submission with fresh decisions. Catalog
  publication does not itself install, activate, certify, or expose a module.
- **Concurrency and audit**: Review, approval, publication and revocation use a
  strong `If-Match` on the current submission version. A missing precondition yields
  428, a stale one 412, and an otherwise invalid transition 409 with the platform
  `lifecycle_conflict` problem code, without mutation. Exact authorized retries
  follow the existing idempotency contract. Creation and accepted transitions emit
  immutable, secret-free evidence for the tenant, submission, actor, time, old/new
  status, digest, reason and evidence reference, correlation, and applicable policy
  version; unauthorized or invalid changes are denied and audited. Revocation
  invalidates applicable approval and availability eligibility and initiates governed
  exposure/lifecycle reconciliation without discarding assigned delivery obligations.
- **Rationale**: Explicitly matches the approved trust boundary and fault-isolation
  requirement without promising process isolation. Separate decisions allow the
  platform to enforce a deployment policy that sometimes requires two operators,
  without imposing that requirement on every deployment. New submissions preserve
  immutable artifact identity and prior terminal decisions; version checks prevent
  concurrent review, publication or revocation from silently overwriting one another.
- **Alternatives considered**: Unreviewed code in process (unsafe); mandatory separate
  containers for every module (not necessary for the stated v1 trust boundary);
  approval by module name/version rather than immutable artifact digest (does not bind
  the decision to the exact code); a single combined decision (cannot enforce or audit
  reviewer/approver separation); reopening a terminal submission (obscures immutable
  review history); treating catalog publication as module or route activation
  (bypasses separate certification and exposure gates).

## Event reliability and retention

- **Decision**: Use RabbitMQ initially behind a messaging port, with transactional
  outbox publication and tenant-scoped durable subscriptions. The subscriber
  deduplicates by subscription, tenant and stable event identity, and atomically records
  successful local effects. Concurrent duplicate deliveries must not apply effects twice.
  Retry transient failures; dead-letter persistent failures with explicit alerting and
  authorized replay, preserving the delivery obligation rather than silently discarding
  it. Preserve pending deliveries through archive and module drain; archive after the
  configured retention period without deleting undelivered obligations. Uninstallation
  remains pending until assigned events are processed, including on persistent failure.
  A newly activated subscription receives no historical events; existing assigned
  delivery obligations remain subject to governed retries and replay.
- **Rationale**: At-least-once transport admits duplicates; local idempotent effects and
  an outbox prevent retries from becoming lost or duplicated business changes. No
  distributed exactly-once effect is claimed for arbitrary external side effects.
- **Alternatives considered**: Kafka initially (allowed but not the spec's primary
  assumption); best-effort delivery (violates the spec); infinite hot retention alone
  (ignores configurable archival).

## Configuration and secrets

- **Decision**: Resolve configuration in the stated source order (environment, file,
  database); within a source choose the most specific applicable scope (module, tenant,
  global). Invalid updates leave the last valid value in force. Non-secret configuration
  changes record before/after values; secret-valued changes record only redacted
  references or versions, never plaintext. Secrets remain in an external secret manager.
  Non-critical changes reload without restart; database URL changes are validated and
  staged until restart, and other critical infrastructure changes may require restart.
- **Rationale**: Defines a deterministic precedence without placing secrets in platform
  data or audit records, while honoring FR-029 through FR-033.
- **Alternatives considered**: Scope overriding source priority (contradicts stated
  source priority); plaintext or encrypted secret snapshots in audit (contradicts the
  selected secret-handling boundary).

## API credentials

- **Decision**: Include tenant-scoped developer self-service API credential management
  in v1, subject to authenticated, authorized canonical API operations and auditing.
  Present a newly generated secret only at issuance and retain only a verifier or
  externally managed secret reference, not the recoverable credential.
- **Rationale**: The planning clarification resolves FR-045's former contradictory
  scope; minimizing recoverable credentials reduces exposure.
- **Alternatives considered**: Defer the capability (rejected by stakeholder);
  store reusable plaintext credential material (incompatible with secret handling).

## Recovery readiness

- **Decision**: Do not set platform-wide numeric recovery point or recovery time
  objectives in v1. Each production deployment documents its own measurable
  data-loss and restoration-time objectives, runs recovery tests against them, and
  records ownership, outcomes and any accepted gaps. The exact record format,
  approval process, test type and cadence remain deployment/operations decisions.
- **Rationale**: The objectives are deployment-specific by clarification; platform
  readiness is evidenced by documented targets and tested recovery, not invented
  global numbers. This is consistent with the contingency-planning purpose of
  [NIST SP 800-34 Rev. 1](https://csrc.nist.gov/pubs/sp/800/34/r1/upd1/final).
- **Alternatives considered**: A universal numeric RPO/RTO (unsupported by the
  clarification); omitting recovery validation (conflicts with SC-036); qualitative
  "fast" or "minimal" targets (not testable).

## Tenant capacity and deployment profiles

- **Decision**: Set no platform-wide active-tenant limit. Each production deployment
  documents and tests its active-tenant capacity and concurrency profile as part of
  its service objectives. The platform remains horizontally scalable without a
  universal tenant-count commitment.
- **Rationale**: The clarification selects deployment-specific capacity rather than
  an unsupported global ceiling. SC-014 remains verifiable against each deployment's
  documented objectives.
- **Alternatives considered**: Inventing a universal tenant maximum (unsupported);
  leaving capacity evidence undocumented (not testable against SC-014).

## Portal accessibility

- **Decision**: Treat WCAG 2.2 Level AA conformance for the in-scope documentation and
  developer portals as a release gate. Use automated checks for regression coverage
  and a human evaluation of full in-scope pages and complete user flows before release.
  Record scope and findings; an automated scan alone is not sufficient conformance
  evidence.
- **Rationale**: WCAG 2.2 is a W3C Recommendation with testable success criteria, and
  WCAG-EM 2.0 provides a structured approach for defining scope, selecting a
  representative sample, evaluating, and reporting findings.
- **Alternatives considered**: WCAG 2.1 AA (the spec selects 2.2); automated-only
  evaluation (does not establish all conformance criteria); AAA as a blanket target
  (not required by the spec).
- **References**: [WCAG 2.2](https://www.w3.org/TR/WCAG22/);
  [WCAG-EM 2.0](https://www.w3.org/TR/wcag-em-2/).

## Validation and release

- **Decision**: Validate via unit, real-adapter integration, OpenAPI and event contract,
  architecture, cross-channel authorization and tenant-isolation, end-to-end, concurrency,
  deployment-specific recovery and performance tests. Apply constitution coverage
  thresholds per layer. Benchmark the exact spec targets in explicitly documented
  environments. Test delegated access with child context, grant revocation and denial
  cases; test conditional reviewer/approver separation; gate portal release on WCAG
  2.2 AA evaluation. Add Gateway route/contract correspondence, route lifecycle,
  control-plane outage and stale-route denial tests; add architecture tests proving
  inward-owned port direction and rejecting product dependencies in Domain/Application.
  CI independently enforces Domain and Application minimum 85% and critical-scope 95%,
  Infrastructure 70%, Presentation 60%, and generated-feature unit-test coverage 85%.
  Security and authorization code inherits 95% only when it is in critical Domain or
  Application scope; mandatory boundary tests pass independently of coverage.
- **Rationale**: The feature's isolation and cross-channel promises cannot be verified
  solely through unit tests.
- **Alternatives considered**: Mock-only tests or a GUI-only verification path (cannot
  establish real isolation or canonical contract conformance).

## Follow-up validation

- Complete the Gateway product-selection ADR before implementing a product-specific
  adapter; this plan does not choose a product or define vendor configuration.
- Keep tenant active-capacity and concurrency objectives deployment-specific and
  record test profiles before interpreting performance results.
- Document operational ownership, escalation and replay procedures for dead-lettered
  deliveries. Unavailability may leave uninstall pending indefinitely; delivery is
  never silently waived.
- Classify other infrastructure settings and document restart behavior before exposing
  their update contracts. Standards grace periods cannot waive constitutional security
  or tenant isolation; after expiry, disable non-compliant modules and their dependents
  without stopping the core or unaffected modules.
- Preserve the clarified separation of platform provisioning authority and
  tenant-scoped administration in implementation and channel validation; do not infer
  child-creation authority from hierarchy, a request, or an administrative grant.
- Deployment-specific recovery objective ownership, approval, test type and cadence
  remain operational decisions; no global values are selected here.
- The parent hierarchy's maximum depth is not specified. Delegation is non-transitive
  and must be checked against the direct parent-child relationship.
