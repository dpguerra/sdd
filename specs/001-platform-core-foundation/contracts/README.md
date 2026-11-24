# Platform Core Foundation contracts

## Canonical artifacts

- `openapi.yaml` is the canonical synchronous REST contract (OpenAPI 3.1.0,
  API version `v1`). It defines tenant, identity/auth/RBAC, developer API
  credentials, events and subscriptions, module discovery/approval/lifecycle,
  scaffolding, configuration, standards/compliance, audit, documentation, and
  health and tenant-scoped module telemetry interfaces.
- `integration-events-v1.yaml` is the separately versioned JSON Schema
  contract for asynchronous integration-event envelopes. It is not a list of
  business-module events; module-specific payload schemas are registered and
  governed separately.
- `module-api-declarations.schema.json` is a JSON Schema for the optional API
  declaration portion of a module manifest. It records module-owned,
  versioned canonical API contract references, publishable operations,
  compatibility and security/context requirements, observability, abstract
  publication metadata, operational endpoint declarations, and applicable
  outbound capability/provider requirements. Modules without externally
  consumable synchronous APIs may omit API declarations.

The module API declaration schema describes what a module owns and requests
for governed publication; it is not a substitute for the module's canonical
business API contract. REST business contracts remain module-owned OpenAPI
documents, while `openapi.yaml` remains the Platform Core REST contract.
Likewise, asynchronous cross-module contracts remain governed Integration
Events and use the Event Bus, not the Gateway. The manifest declaration schema
does not define Gateway product configuration, physical routes, runtime
publication status, or pre-exposure gate evidence. Its publication metadata is
an exposure request, not approval to publish; the platform independently
evaluates the applicable gates.

## Authority, tenancy, and lifecycle invariants

- Tenant context is derived from validated tenant JWT membership or a
  tenant-bound API credential. Any tenant identifier in a URL or payload must
  match that resolved context. Missing, invalid, or mismatched context is
  denied; repositories, database row-level security, caches,
  subscriptions, asynchronous consumers, and audit queries must preserve the
  same boundary. Platform-wide operations use a distinct platform-operator
  authority; tenant roles cannot grant it.
- Tenant slugs are unique across the deployment regardless of hierarchy and
  compared case-insensitively. User email identity is tenant-scoped: the same
  email may identify one account in different tenants, but uniqueness within a
  tenant and tenant-qualified sign-in are case-insensitive. These contracts do
  not select a normalization or persistence mechanism.
- In v1, the platform-global Platform Operator is the authoritative actor for
  root- and child-tenant creation, tenant suspension and reactivation, and
  initial Tenant Admin bootstrap. `Organization Administrator` is the User
  Story 1 persona mapped to Platform Operator for these operations, not a
  separate role.
  Initial Tenant Admin bootstrap is permitted when no Tenant Admin exists;
  existing non-admin users do not prevent it. Bootstrap is denied once a
  Tenant Admin exists.
  The tenant-creation operation accepts an optional direct parent identifier,
  but only Platform Operator authority may create the child; the relationship
  itself grants no authority.
- The child-provisioning request capability is future and, if introduced,
  must be explicitly governed. It does not create a tenant or itself grant
  creation authority; under v1 policy, creation remains a Platform Operator
  action. No child-provisioning request endpoint is defined here because the
  capability is optional and its contract is unspecified. Future scoped
  child-creation delegation after v1 requires an explicit policy and is not
  implied by tenant membership, hierarchy, or an administrative grant for an
  existing child.
- Suspended tenants cannot initiate business operations. Explicitly authorized
  background processing and maintenance may continue under that tenant's
  context with isolation, audit, and event-delivery controls intact. Only a
  platform-global Platform Operator may suspend or reactivate a tenant;
  tenant-scoped roles cannot perform either action.
- Parent-child tenancy is explicit organizational metadata, not an authorization
  relationship. A parent actor may operate in a direct child's context only with
  a child-owned, active grant selected per request through
  `X-Delegated-Tenant-Grant`; the grant is not transitive or inferred. The server
  rechecks the grant, direct parent relationship, operation permission, parent
  actor membership/admin authority, and revocation on every request. It executes
  with the child as the effective tenant context and retains parent actor and
  grant identities in audit evidence. Grant creation/revocation is attributable
  and audited.
- Tenant and platform login/refresh authenticate supplied credentials without
  a prior access token. Initial platform-operator enrollment is deliberately
  out of band and cannot be self-created or elevated through these APIs.
  A Platform Operator may bootstrap the initial Tenant Admin once if the tenant
  has no Tenant Admin and bootstrap has not previously completed; other tenant
  users may already exist. Concurrent attempts create at most one initial Tenant
  Admin. Later identity changes use tenant-scoped RBAC.
  Logout revokes only the authenticated session's refresh credentials and
  immediately invalidates its already-issued access tokens for subsequent
  requests; other sessions remain usable. Authorization fails closed when
  sufficiently current session status cannot be established.
  JWTs are short-lived access tokens (15 minutes); refresh tokens are 7-day
  Secure, HttpOnly cookies and are never returned in JSON.
- Retry-safe state changes define their duplicate, retry, and conflict
  outcomes. `Idempotency-Key` is required only where an operation needs an
  operation identity to make retries safe; naturally idempotent operations do
  not require it. Conflicting concurrent updates use strong
  `ETag`/`If-Match`; configuration PUT uses `If-Match` for replacement and
  `If-None-Match: *` for creation. Reuse of a key with a different request is a
  conflict, and a replay has no duplicate effect. Each deployment defines
  idempotency-key retention sufficient to cover its supported retry window and
  asynchronous completion window; no universal numeric retention is prescribed.
  Keys for asynchronous operations are never deleted before completion, and
  may be retained after completion only for the deployment's documented
  supported retry window. These requirements do not select an idempotency
  store or concurrency-control mechanism. API credential
  secrets are disclosed only in the initial successful issuance response;
  retries and all later reads return metadata only.
- A new or materially changed capability or channel is not exposed until its
  applicable canonical-contract, contract-test, architecture-test,
  security/governance, and channel-compatibility gates pass. Missing, failed,
  expired, or stale evidence fails closed; material changes require
  revalidation. Existing exposure is reconciled or withdrawn when eligibility
  is invalidated. An outage permits only the last validated configuration for
  still-available capabilities, not new or changed exposure.
- Module code may be installed only after platform-operator review and approval
  of the exact artifact digest. Authorized partners submit releases without core
  repository access; operator approval of that exact artifact precedes catalog
  publication. Failure disables the module and its dependent
  modules, not the core or unaffected modules. Uninstall drains assigned event
  work and remains pending while any delivery obligation is unresolved;
  persistent delivery failure does not authorize dropping an event. Tenant
  enablement is separate from the shared deployment; one tenant's uninstall
  cannot unregister code still enabled for another tenant.
- Review and approval are separate, attributable decisions for the exact
  immutable artifact digest. Approval requires a positive review of the same
  digest. The server, never the caller, enforces the deployment-configured
  reviewer/approver separation policy and records both identities and the
  effective policy version. This is governed trust approval, not a sandbox claim.
- Module-submission lifecycle mutations use the submission ETag, not a derived
  ETag from a review, approval, catalog, or revocation response representation.
  Before a new review, approval, publication, or revocation, re-fetch
  `GET /platform/modules/submissions/{submissionId}` and send that submission ETag
  in `If-Match`; those operations also require
  `Idempotency-Key`. A positive or negative review advances the submission
  version even though positive review leaves `pending_review`. Missing
  `If-Match` returns 428, stale `If-Match` returns 412, an invalid transition
  returns 409 with `lifecycle_conflict`, and a key reused for a different request
  returns 409 with `idempotency_key_reused`. After authentication and
  authorization, exact replay resolution precedes submission ETag/precondition
  evaluation; an exact replay reuses the original request, key, and ETag and has
  no second transition even if that ETag is now stale. Reuse of the same key
  with a different canonical request is 409.
- Submission creation and all accepted transitions have immutable audit evidence:
  submission and tenant IDs, actor, time, previous/new status (creation omits
  previous status), exact artifact digest, reason and decision or supporting
  evidence, correlation context, and the effective policy version when applicable.
  Creation uses a server-derived submission reason. Publication uses a server-derived
  publication reason plus manifest and exact-digest approval evidence. Review
  and approval use an explicit reason when supplied, or a server-derived decision
  reason; `standardsAssessment`, the bound review and an optional
  `supportingEvidenceRef` supply supporting evidence. Revocation uses its
  required explicit reason. Unauthorized or invalid changes are denied and
  audited without secret values.
- `ModuleSubmission.status` uses only `pending_review`, `approved`, `rejected`,
  `published`, and `revoked`. The initial status is `pending_review`;
  `rejected` and `revoked` are terminal.

  | From | To | Authorized governed operation and gates |
  |---|---|---|
  | (creation) | `pending_review` | Authorized partner submission; server-derived audit reason |
  | `pending_review` | `approved` | Platform Operator positive approval after positive review of the exact digest, enforcing the deployment separation policy; reviewer and approver may coincide when permitted |
  | `pending_review` | `rejected` | Platform Operator negative review or negative approval |
  | `pending_review` | `revoked` | Platform Operator governed revocation |
  | `approved` | `published` | Platform Operator publication after successful manifest validation and active positive exact-digest review/approval |
  | `approved` | `revoked` | Platform Operator governed revocation |
  | `published` | `revoked` | Platform Operator governed revocation |

  No transition from `rejected` or `revoked` is permitted, and no return to
  `pending_review` or resubmission-derived inheritance is permitted.
  Resubmission always creates a new submission in `pending_review` with fresh
  review and approval. Publication, certification, installation, activation,
  route exposure, and channel enablement remain distinct outcomes. This contract
  does not make catalog publication or approval an exposure side effect.
- A standards grace deadline applies only to modules already installed at the
  release instant. New installs always meet the currently enforced standard;
  grace cannot waive security or tenant-isolation requirements. On expiry,
  disable non-compliant modules and their dependents while preserving the core
  and unaffected modules.
- Config precedence is environment, file, then database; specificity is
  resolved within each source. Invalid changes leave the last valid setting
  active. Secret values remain in an external secret manager and are never
  returned, logged, or audited. Database URL changes are validated and staged
  for restart rather than switched immediately.
- Each bounded context owns its authoritative data, private persistence
  boundary, migrations, and applicable Outbox/Inbox; other contexts do not
  access its private persistence or migrations directly. Projections are
  consumer-owned derived data, not silent substitutes for authoritative state.
  Applicable classifications, tenant boundaries, retention, and access
  controls follow persisted data into primary/private persistence, projections,
  migrations, backups, restores, exports, archives, analytics, and dead-letter
  copies. Applicable sensitive persisted data is protected at rest using
  AES-256; no encryption mechanism or physical database topology is selected
  here.
- Audit records are immutable and retained for seven years. They include actor,
  reason where required, outcome, timestamp, and correlation context, and
  retain non-secret before/after values. Secret changes contain redacted
  references or versions only.
- Event delivery is at least once, not distributed exactly once. Stable event
  identity, transactional outbox publication, consumer deduplication, retry,
  dead-letter alerting, authorized replay, and retention/archive behavior must
  preserve delivery obligations. Hot retention defaults to 30 days; expired
  records are archived, and undelivered events never expire or disappear.
- WCAG 2.2 Level AA conformance for the documentation and developer portals is
  a release gate, with representative human evaluation and automated
  regression checks; it is not represented as a REST endpoint.
- Recovery-point, restoration-time, test type, ownership, and evidence are
  deployment-specific release/operations gates. The contract defines no
  platform-wide numeric RPO/RTO or recovery endpoint.

## Channel conformance

REST/OpenAPI is the canonical operational contract. Any MCP, CLI, GUI/portal,
SDK, automation, or external integration is only a consumer of the same
governed application capability. Channels must not implement authoritative
authorization, tenant selection, policy, lifecycle, or secret-handling rules.
They must preserve validation, errors, idempotency, concurrency, audit, and
correlation/trace semantics. In-process adapters may call application ports
directly only when the same controls apply; loopback HTTP is not required.

The documentation and developer portals consume these APIs. The CLI
`module:scaffold` and `module:update-standards` commands, SDK event/config
operations, and any future MCP tools must conform to the corresponding
operations and schemas here. No alternate privileged path is permitted.
Requests accept or propagate `X-Correlation-Id`; responses return it.
`traceparent` and correlation context propagate across asynchronous events.
Logs, traces, and metrics must not contain credentials, secret values, or
cross-tenant data.

## Explicitly unsupported in this feature

- Billing, subscriptions, analytics, or any other business-module behavior,
  and Feature 002/RACI-domain capabilities.
- A general administrative dashboard, mobile app, SSO/OIDC/SAML, multi-region
  or multi-deployment management, and side-by-side/blue-green module versions.
- Installation or execution of unreviewed code, a security sandbox for
  malicious in-process modules, and self-service installation by ordinary users.
- Exactly-once broker delivery or guarantees about arbitrary external side
  effects. At-least-once delivery with idempotent consumers is the contract.
- Recovery or bootstrap of the first platform operator through a public API.

These exclusions do not prevent the core from providing generic extension
points. They do prohibit adding business-specific operations or sample
business modules to this contract.

## Specification gaps and explicit contract assumptions

- The contract maps the User Story 1 `Organization Administrator` persona to
  the platform-global Platform Operator for provisioning,
  suspension/reactivation, and initial Tenant Admin bootstrap, as specified. The
  optional governed child-provisioning request capability has no endpoint here;
  if introduced, it must not create a child and must preserve the current
  Platform Operator-only creation policy unless a future explicit policy
  delegates scoped authority. The first Platform Operator remains an out-of-band
  deployment responsibility.
- The initial Tenant Admin bootstrap endpoint implements the specified
  Platform Operator-only bootstrap authority and one-time condition. The
  precondition is that no Tenant Admin exists, not that the tenant has no users.
  Enrollment details beyond that contract are not specified.
- Case-insensitive slug and tenant-scoped email uniqueness are normative, but
  normalization, persisted comparison keys, and collision handling remain
  implementation prerequisites; the contract does not choose them.
- Immediate session-scoped access-token revocation is normative, but the
  revocation store, failure recovery, and safe retention strategy remain
  implementation prerequisites.
- Database-versus-schema physical topology requires a separate isolation ADR
  before provisioning. The contract does not select a database topology.
- Gateway product selection remains a product-selection ADR prerequisite to
  product-specific adapter work; this contract selects no Gateway product.
- The default role grants and API-credential scope catalog are defined by
  `x-authorization-policy` in the OpenAPI contract. Implement and test those
  grants, ownership constraints, credential scope intersection and default denial.
- Partners submit releases through the platform. Operators review the exact
  submitted artifact and separately publish approved releases to the catalog.
  Submission does not execute the artifact.
- Standards grace is limited to already-installed modules and never weakens
  new-install, security, or isolation requirements. At expiry, non-compliant
  modules and their dependents are disabled.
- The spec explicitly stages database URL changes but does not classify the
  restart behavior of other critical infrastructure settings. Those settings
  require classification before their update behavior is implemented.
- Idempotency retention is deployment-defined. It must cover the deployment's
  supported retry window and asynchronous completion window, with no universal
  numeric retention. Asynchronous operation keys must not be deleted before
  completion.

## Contract and acceptance test requirements

Before any channel is released, automate at least the following:

1. Parse and lint OpenAPI 3.1 and JSON Schema; validate every request, response,
   error, event, and supported-version compatibility fixture.
2. Verify unauthenticated login and refresh bootstrap, JWT signature/expiry/
   audience and tenant membership checks, globally case-insensitive slug
   uniqueness, tenant-scoped case-insensitive email uniqueness and sign-in,
   session-scoped logout with immediate access-token rejection and continued
   validity of other sessions, and fail-closed session-status checks.
   Also verify API-credential scope, RBAC denial by default,
   platform-versus-tenant authority separation, Platform Operator-only root and
   child creation, suspension/reactivation, and initial Tenant Admin bootstrap
   when no Tenant Admin exists (including when non-admin users already exist).
   Verify bootstrap is denied once a Tenant Admin exists and tenant-scoped
   attempts are denied. Child-provisioning requests do not create tenants;
   hierarchy and grants do not confer creation authority, and any future scoped
   creation delegation is absent unless an explicit policy authorizes it. Verify
   child-owned
   direct-parent grants with operation scope, child-context execution,
   non-transitivity and revocation, and password/refresh secret non-disclosure.
3. Exercise cross-tenant reads, writes, configuration, event subscription and
   asynchronous delivery—including mismatched identifiers, pooled database
   session context, caches, and row-level security—and prove zero leakage.
   Verify suspension blocks tenant-initiated business operations while only
   authorized background processing and maintenance continue under tenant
   controls. Verify applicable sensitive persisted representations and copies
   are protected at rest using AES-256 without requiring a particular mechanism.
4. Race concurrent mutations; prove one result per idempotency key where
   required, rejection of changed-payload key reuse, stale/missing `If-Match`
   and invalid `If-None-Match` rejection, and no duplicate side effects on
   retries through every channel. Verify naturally idempotent operations do
   not require an idempotency key and conflicting concurrent updates do not
   overwrite accepted state. Verify the deployment-defined idempotency
   retention covers supported retry and asynchronous completion windows and
   that no key is deleted before asynchronous completion.
5. Verify partner submission, separate operator review and approval, and
   publication without core repository access. Bind both decisions to the
   submitted and installed artifact digest; require positive review for positive
   approval; enforce the deployment-configured reviewer/approver separation
   policy and retain its effective version. Reject unapproved publication or
   code, dependency cycles, and new installs that rely on grace. Verify grace
   applies only to pre-existing modules and never weakens security/isolation
   requirements.
6. Exercise module register/validate/start/stop/unregister and dependency
   failure handling; ensure the core and unaffected modules remain available.
   For uninstall, test pending/in-flight/dead-lettered deliveries, retry,
   authorized replay, archive/retention, and completion only after all
   assigned delivery obligations are processed.
7. Verify event schema/version compatibility, transactional outbox recovery,
   at-least-once retries, stable event identity, atomic consumer deduplication,
   subscription tenant filters, no historical events for newly activated
   subscriptions while preserving previously assigned delivery obligations,
   and trace/correlation propagation.
8. Test configuration precedence and scope resolution, schema rejection with
   last-valid-value preservation, immediate hot reload for non-critical
   settings, and database URL validation/redaction/staging until restart.
   Assert secret values never appear in response, audit, logs, traces, or
   errors; assert non-secret audit before/after values are retained.
9. Verify immutable audit coverage for authentication attempts and sensitive
   operations; authorization of tenant/platform audit reads; retention policy;
   and safe error responses with stable codes and correlation identifiers.
10. Before exposure, verify applicable contract, architecture,
    security/governance, and channel-compatibility gates fail closed for
    missing, failed, expired, or stale evidence; verify material changes are
    revalidated and ineligible exposure is reconciled or withdrawn.
    Run contract-conformance tests for portals, CLI, SDK, and any MCP or
    automation adapter. Assert no channel can bypass canonical authorization,
    tenancy, validation, audit, idempotency, concurrency, or lifecycle rules.
11. Run API end-to-end flows for tenant provisioning, user/role assignment,
    one-time API credential issuance, scaffold generation, module approval and
    install/uninstall, standards/compliance reporting, documentation search,
    and health. Validate the specification's stated performance targets in a
    documented test environment before claiming them.
12. Run automated and representative human WCAG 2.2 Level AA evaluation for
    in-scope documentation and developer portals. For each production
    deployment, test recovery against that deployment's documented objectives
    and retain evidence; do not infer a platform-wide numeric target or
    approval process.

The OpenAPI contract intentionally describes externally visible requirements,
not the persistence/broker vendor or internal module implementation. Those
choices must preserve these invariants and be covered by real-adapter
integration tests.
