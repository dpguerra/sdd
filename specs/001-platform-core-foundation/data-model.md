# Data Model: Platform Core Foundation

**Feature**: `001-platform-core-foundation`
**Status**: Draft
**Sources**: [spec.md](./spec.md), [research.md](./research.md), and
[constitution.md](../../.specify/memory/constitution.md)

This is a conceptual model for v1, not a physical schema or API contract. It
defines consistency, logical ownership, and security boundaries. Physical
persistence topology remains deferred; tenant context enforcement follows the
existing decisions in [research.md](./research.md). This model does not select
a Gateway product, session, normalization, encryption, concurrency, or
idempotency mechanism, capacity target, or recovery objective.

## Conventions and classifications

- **Global** records are shared platform control-plane/catalog data. A global
  record is not implicitly accessible to tenant callers; platform operations
  require separate authorization.
- **Tenant-scoped** records have a mandatory `tenant_id`. Every read, write,
  cache key, subscription, and asynchronous operation is bound to the
  authenticated current tenant.
- **Module-scoped** records identify a module and may additionally be global or
  tenant-scoped. A module identifier never substitutes for tenant authorization.
- IDs are opaque stable identifiers. Timestamps are UTC instants. Versioned
  contracts and immutable evidence are retained as versions rather than
  overwritten in place where history is required.
- Platform-wide operations with no tenant are explicit control-plane operations;
  they do not inherit an ambient tenant and must not be used to bypass tenant
  authorization.

## Entities

### DeploymentCapacityProfile — deployment-specific operational control

The deployment owner records the active-tenant capacity and concurrency
profile, service-objective reference, validation conditions, and test evidence
for each production deployment. This is operational governance metadata, not
a platform-wide tenant limit. Recovery objectives and their validation remain
deployment-specific. No numeric capacity, RPO, or RTO is selected here.

### Tenant — global identity / tenant boundary root

| Field | Meaning |
|---|---|
| `id` | Stable tenant identifier |
| `name` | Display name |
| `slug` | Human-readable key, unique across the deployment ignoring case |
| `status` | `active` or `suspended` |
| `parent_tenant_id` | Optional direct parent tenant identifier; organizational metadata only |
| `isolation_root` | Opaque logical isolation-boundary reference; it does not specify physical topology |
| `created_at`, `updated_at` | Lifecycle timestamps |

Tenant owns its users, role assignments, credentials, configuration overrides,
tenant audit records, event deliveries, and tenant-specific operational data.
Suspension is soft: it denies normal tenant operations while preserving records
for applicable compliance and retention periods. Explicitly authorized
background processing and maintenance may continue only within the suspended
tenant's context and applicable authorization, isolation, audit, and delivery
controls. No hard-delete behavior is specified.

In v1, the platform-global Platform Operator creates root and child tenants,
suspends/reactivates tenants, and bootstraps the initial Tenant Admin when none
exists. Existing non-admin users do not by themselves prevent bootstrap. A Tenant
Admin cannot create a root tenant and may request child provisioning only through
a future explicitly governed capability; the request neither creates nor authorizes
the child. An explicit delegated-authority policy after v1 may grant scoped child
creation.

`parent_tenant_id` may be null and does not grant authority. When present, it
identifies one direct parent for organizational purposes. Hierarchy depth and
transitive parent relationships are not assigned platform-wide limits or
inferred authorization rules; neither the relationship nor an existing child-admin
grant authorizes provisioning.

### TenantDelegatedAdministrationGrant — child-owned, tenant-scoped

| Field | Meaning |
|---|---|
| `id` | Stable grant identifier |
| `child_tenant_id` | Child tenant that owns and may create/revoke the grant |
| `parent_tenant_id` | Direct parent tenant named as the delegated actor tenant |
| `allowed_operations` | Explicit canonical operation scopes granted to the parent |
| `status` | `active` or `revoked` |
| `created_by`, `created_at` | Child-authorized grant creator and creation timestamp |
| `revoked_by`, `revoked_at`, `revocation_reason` | Revocation attribution and reason, when revoked |

A grant is required for parent-to-child administration and is never implied by
the parent reference. It grants no operations outside
`allowed_operations`; scopes are canonical permissions/operations, not broad
tenant, role, module, or data categories. Each request revalidates the active
grant, direct parent relationship, actor membership and authority in the parent
tenant, and all non-delegable platform rules. The result is a deny-by-default
decision: missing, mismatched, revoked, suspended, or otherwise invalid grant
context is denied.

On an allowed delegated operation, the effective tenant context is the child
tenant; the parent tenant actor and grant are retained only as attribution in
audit/evidence. The operation may not broaden the parent's authority, access
child data outside the grant, or access a grandchild or unrelated tenant. There
is no transitive access: child-owned grants are required independently for
each direct parent-child relationship, and hierarchy changes invalidate grants
that no longer match that relationship.

### ModulePersistenceBoundary and DataOwnershipDeclaration — logical ownership

These are conceptual ownership/governance records, not physical database
objects. A module or bounded context owns its private authoritative state,
including its persistence model and invariants, inward-owned persistence port,
adapter, schema evolution, migrations, local transaction boundary, and lifecycle.
The owner and boundary are identifiable and independently verifiable. Enforceable
logical ownership preserves distinct migration authority, least-privilege module
identity/access, tenant isolation, prevention of unauthorized cross-boundary
reads and writes, and persistence-access attribution. Physical co-location does
not confer access or shared authority. Whether boundaries use separate databases,
schemas, clusters, servers, or another topology remains deferred.

Each authoritative business datum has one declared owner. A non-owning module
that needs eventual information maintains its own explicitly derived projection;
it does not read or mutate the owner's private persistence.

### User — tenant-scoped

| Field | Meaning |
|---|---|
| `id`, `tenant_id` | Identity and mandatory owning tenant |
| `email` | Login/contact email |
| `password_hash` | bcrypt or equivalent one-way password hash; never plaintext |
| `display_name` | User-facing name |
| `created_at`, `updated_at`, `last_login_at` | Lifecycle/authentication timestamps |

A user belongs to exactly one tenant. Tenant identity in a token or request must
be validated against this membership; it is not trusted solely because it was
provided by a client. Email uniqueness is tenant-qualified and case-insensitive:
the same address may identify one account in different tenants, but not duplicate
accounts in one tenant. The comparison/normalization and persistence mechanism
are not selected here. Sign-in resolves an explicit valid tenant before account
selection and is denied without one.

### Role and UserRole — tenant assignment, with explicitly marked global roles

**Role** fields: `id`, `name`, `permissions`, `scope` (`tenant` or
`platform`), and `tenant_id` (required for tenant roles, absent for global roles).
The v1 tenant role names are Tenant Admin, User, Billing Manager, Developer, and
Governance Officer. Platform Operator is a separately authorized platform-global
role. Organization Administrator is a persona mapped to Platform Operator for
tenant provisioning, suspension/reactivation, and initial Tenant Admin bootstrap,
not a separate role. Permissions are governed by platform policy, not arbitrary
client-supplied values.

**UserRole** fields: `user_id`, `role_id`, `tenant_id`, `assigned_at`,
`assigned_by`. Assignment is tenant-scoped and must refer to a user and tenant
role in that same tenant. A platform role is separately granted
and authorized; it does not imply access to tenant data.

### AuthenticationSession and authentication tokens — tenant or platform scope

An **AuthenticationSession** is the conceptual identity and current status for
one authenticated session: `session_id`, principal identity, scope, status
(`active`, `revoked`, or `expired`), and lifecycle timestamps. A tenant session
also has its required `user_id` and `tenant_id`; an explicitly platform-scoped
operator session has no ambient tenant and grants no implicit tenant access.
Access and refresh tokens are logically bound to that session; token claims and
the session-status storage/validation mechanism are not prescribed.

JWT access tokens carry subject, tenant, roles, issue time, and expiry (15
minutes); refresh tokens carry subject, tenant, token type, issue time, and
expiry (7 days) and are delivered in an httpOnly cookie. Tokens are validated
for signature, expiry, current tenant membership, and applicable session
status. Concrete token/session persistence and revocation mechanisms are not
prescribed here.

Logout revokes refresh-token use for the current session only and makes every
already-issued access token for that session invalid immediately for subsequent
requests; other sessions remain usable. Each applicable authorization check
must establish sufficiently current session status and deny access if that
status cannot be checked. The persistence, propagation, and recovery mechanism
for session status is deferred.

### Audit records — tenant-scoped or explicit platform scope

**AuditRecord** fields: `id`, `tenant_id` (nullable only for explicitly
platform-scoped events), `actor_type`, `actor_id`, `action`, `target_type`,
`target_id`, `occurred_at`, `reason` when supplied, `correlation_id`, and
redacted structured details. Delegated-administration evidence additionally
records `effective_tenant_id` (the child context), `parent_tenant_id`,
`parent_actor_id`, and `delegation_grant_id` when the actor is operating under
a grant. It records login, logout, refresh, failed
authentication, tenant/user/module/standards/configuration/credential changes,
and attempted isolation violations. Audit records are immutable and retained
for seven years. Secret values are never included in details.

### ModuleSubmission, ModuleDefinition, ApprovedCode, ModuleInstallation, and dependency

**ModuleSubmission** is tenant-scoped: `id`, `tenant_id`, `submitted_by`,
`submitted_at`, versioned manifest, immutable artifact reference and digest, and
`status`, whose complete enum is `pending_review`, `approved`, `rejected`,
`published`, or `revoked`. An authorized partner creates a new submission in
`pending_review` without core-repository access; submission does not execute code.
Only a Platform Operator, authorized through the applicable governed capability,
may perform these status changes:

| From | To | Condition |
|---|---|---|
| `pending_review` | `approved` | Positive review and separate positive approval of the exact immutable artifact digest, under the applicable separation-of-duties policy |
| `pending_review` | `rejected` | Negative review or approval decision |
| `pending_review` | `revoked` | Withdrawal or revocation |
| `approved` | `published` | Authorized catalog publication after successful manifest validation and active positive review and approval of the exact digest |
| `approved` | `revoked` | Withdrawal or revocation |
| `published` | `revoked` | Withdrawal or revocation |

A positive review records a review decision while the submission remains
`pending_review`; it is not itself a status transition.
`rejected` and `revoked` are terminal, and rejected submissions cannot become
active. Any other status change, including a return to `pending_review`, or an
unauthorized change is denied without mutation and audited. An exact retry
follows applicable idempotency rules and does not create another transition.
Resubmission after rejection or revocation creates a new submission in
`pending_review`, with fresh review and approval; prior decisions and status
remain immutable and are not inherited. A changed approved artifact likewise
requires a new submission and fresh review and approval.

Review, approval, publication, and revocation use the submission version as
their optimistic-concurrency target. Each accepted review and status transition
advances that version, including a positive review that leaves the status
`pending_review`. For HTTP, a strong `If-Match` is required;
a stale precondition returns 412 and a missing precondition returns 428, without
mutation. An invalid transition returns HTTP 409 with Problem code
`lifecycle_conflict`, without mutation. Other channels preserve equivalent
concurrency, authorization, idempotency, and audit semantics. No storage or
concurrency-control mechanism is prescribed.

Creation and each accepted status transition produce immutable, attributable,
secret-free audit evidence containing submission and tenant IDs, actor, time,
previous and new status (no previous status for creation), artifact digest,
reason and decision or supporting-evidence reference, correlation context, and
applicable policy version.

Submission status is distinct from certification, installation/lifecycle,
publication eligibility and publication status, and channel-exposure status.
Publication and installation require active positive review and approval of the
exact digest and applicable standards validation. Approval does not bypass
certification, and certification does not bypass mandatory applicable
pre-exposure gates. Catalog publication does not install or activate a module or
expose a route; Gateway exposure remains subject to applicable contract,
architecture, security, authorization, tenant, and channel gates. Revocation
invalidates applicable approval and availability eligibility; affected exposure
is disabled, withdrawn, or reconciled under its governed lifecycle without
discarding pending delivery obligations, and is not reported available while
eligibility is invalid. Route or installation withdrawal is a separate lifecycle
outcome and does not itself change submission status.

**ModuleDefinition** is global catalog data representing a module and its manifest:

| Field | Meaning |
|---|---|
| `id` | Stable module identity / manifest name |
| `description` | Catalog description |
| `current_version` | Catalogued version (not a side-by-side installation guarantee) |
| `manifest_reference` | Immutable reference to the versioned manifest that was validated |
| `created_at`, `updated_at` | Catalog timestamps |

Each versioned manifest declares `name`, `version`, dependencies, permissions,
event and query contracts, Integration Event and provider contracts where
applicable, and the platform standards version it targets. For every externally
consumable synchronous capability, it additionally declares the module-owned
canonical API contract and supported versions, externally publishable operations,
route-publication metadata, compatibility rules, authentication requirements,
authorization requirements, tenant requirements, and observability requirements.
A manifest may declare an operational endpoint; it may also declare outbound
capability/provider requirements. Those lists may be empty when the module does
not expose or require the corresponding capability. Manifest fields express
governed capabilities and contracts, never substitute an implementation,
Infrastructure technology, or provider product for a contract. `name` is globally
unique; module names are the namespace for event types.

**ApprovedCode** is derived trust evidence linking `module_id`, `version`,
`artifact_digest`, and an active approval. Installation is permitted only for
the exact platform-computed immutable artifact digest that has positive review
and approval evidence; approval of a name or version alone does not approve
changed code. Unreviewed code is not an allowed v1 installation. Operator
review and approval are trust boundaries, not claims that in-process code is
sandboxed or safe against malicious behavior.

**ModuleReviewDecision** and **ModuleApprovalDecision** are distinct append-only
decision records. A review or approval may only be recorded for the exact
platform-computed `artifact_digest` of the immutable submission; it binds the
decision to the submission and module version. The review decision records
`reviewer_identity`, `reviewed_at`, `result`, review evidence/reference, and
immutable audit attribution. The approval decision additionally records
`effective_policy_version`, `approver_identity`, `approved_at`, `result`,
approval evidence/reference, and immutable audit attribution. Publication and
installation revalidate the active positive approval against the exact digest.

The deployment-configured separation-of-duties policy is evaluated at approval
time. If that policy requires distinct identities, an approver who is also the
reviewer is denied approval; otherwise one identity may satisfy both roles.
The deployment policy, effective policy version, reviewer identity, approver
identity, and audit evidence remain recorded even for the permitted
configuration. The platform does not infer separation or impose a single
deployment-wide rule.

**ModuleInstallation** fields: `id`, `module_id`, `version`,
`approved_artifact_digest`, `status`, `installed_at`, `updated_at`,
`failure_reason` (non-secret diagnostic), and optional `standards_grace_id`.
The registry/installation control plane is global in this conceptual model;
module operations on tenant data still require a separately resolved tenant
context and authorization.

**TenantModuleEnablement** is tenant-scoped: `tenant_id`, `module_installation_id`,
`status`, `version`, and timestamps. Tenant installation creates this relation to
the shared approved deployment. Tenant lifecycle operations cannot mutate another
tenant's enablement. Shared code cannot be stopped or unregistered while another
tenant remains enabled; platform-wide failures affect the shared deployment and
its dependents.

Installation lifecycle: `registered → validating → validated → starting →
running → stopping → stopped → unregistering → unregistered`. Validation or
startup may instead transition to `failed`; a failed optional module remains
unavailable. The core and unaffected modules continue operating. Any transitive
dependent of a failed or unavailable dependency is also unavailable until its
dependency chain is valid and running. Dependency edges identify
`module_id`, `dependency_module_id`, and declared version constraint; circular
dependencies are rejected. Uninstall/drain transitions are detailed under
event delivery below.

### CanonicalApiDeclaration and PublishableOperation — module-owned

**CanonicalApiDeclaration** is a global, versioned module-owned contract record:
`id`, `module_id`, `contract_name`, `contract_version`, `machine_readable_contract`,
`compatibility_rule`, `request_semantics`, `response_semantics`,
`business_error_semantics`, `authentication_requirement`,
`authorization_requirement`, `tenant_requirement`, and
`observability_requirement`. Its manifest declaration is linked to the exact
version. REST declarations identify a valid OpenAPI contract. The declaration is
owned by the module bounded context and remains the source of business API
semantics; Platform Core does not redefine it with a generic controller or use
Gateway configuration as its sole source.

**PublishableOperation** is a module-owned declaration of one externally
publishable operation: `id`, `canonical_api_declaration_id`, `operation_name`,
`availability_scope`, `compatibility_rule`, `authentication_requirement`,
`authorization_requirement`, `tenant_requirement`, and
`observability_requirement`. It does not name internal hosts or deployment
topology and it may be empty for a module with no external synchronous capability.
An inbound application adapter exposes the corresponding authoritative
application capability. Channel adapters, MCP tools, CLI/GUI/SDK/automation
consumers invoke that capability; they do not create a second business contract
or use Gateway administration to bypass it.

**OperationalEndpointDeclaration** is optional manifest data for a health,
readiness, or liveness endpoint. It declares the governed endpoint purpose and
exposure exception, but no business operation or tenant data semantics. Direct
reachability is allowed only under the narrow governed deployment exception and
must not mutate state, grant authority, expose unauthorized tenant data, or
bypass application controls.

### RoutePublicationMetadata and GatewayRoutePublication — product-neutral lifecycle

**RoutePublicationMetadata** is module/operation metadata associated with a
published canonical declaration. It records the externally supported
contract/version, publication intent, edge-authentication requirement,
applicable traffic/quotas, request-size constraints, abusive-traffic protection,
applicable CORS/observability requirements, and compatibility metadata. It is
conceptual publication declaration rather than a chosen Gateway product,
vendor configuration, or route convention. Conflicting or undeclared metadata
is rejected and identified; external exposure remains absent.

**GatewayRoutePublication** is a global Platform Core-owned control-plane
record: `id`, `module_id`, `module_installation_id`, `canonical_api_declaration_id`,
`publishable_operation_id`, `supported_contract_version`,
`route_publication_metadata_id`, `status`, `validation_evidence`,
`last_validated_configuration`, `last_validated_at`, `data_plane_status`,
`control_plane_status`, `discrepancy_reason`, `correlation_id`, and
timestamps/outcomes. It coordinates, but does not implement, module business
capabilities. It records the last successfully validated data-plane
configuration separately from the desired/recently requested configuration.

Allowed lifecycle: `draft → validating → rejected` or
`draft → validating → activating → active`; `active → updating → active`,
`active → disabling → disabled`, `active → withdrawing → withdrawn`, or
`active → suspending → suspended`. An activation/update/withdrawal may also
remain `incomplete` and must not be reported as successful or complete.
`rejected`, `disabled`, `suspended`, `withdrawn`, and unavailable capabilities
are not governed as externally active. Disablement, suspension, withdrawal,
uninstall, expiry, loss of support, non-compliance, failed revalidation,
missing identity/tenant/authorization context, or capability failure withdraw or
disable the publication and are observable.

While the Gateway control plane is unavailable, route registration, update,
withdrawal, and activation pause. Active data-plane routes may continue routing
only with their last successfully validated configuration for capabilities that
remain available. The application capability remains authoritative and fails
closed for disabled or unavailable capabilities or missing/invalid required
identity, tenant, authorization, or policy context. Gateway acceptance never
constitutes application authorization. The control/data-plane discrepancy,
continued last-known-good routing, recovery, and reconciliation outcome remain
observable.

**ChannelExposureGateEvidence** conceptually associates a capability and
canonical contract version with each channel that actually exposes it. It
identifies applicable gate categories, outcomes, evidence references, assessment
time, and eligibility/invalidation status. New publication or activation
requires current positive evidence for all mandatory applicable contract,
architecture, security, authorization, tenant, policy, governance, and
channel-compatibility gates. Missing, failed, expired, or stale evidence blocks
exposure. Material contract, policy, tenant-enforcement, certification,
architecture, security, or lifecycle changes invalidate affected eligibility;
new exposure is denied and existing exposure is disabled, withdrawn, or
reconciled under the governed channel lifecycle. Outcomes and invalidation are
observable. This model does not prescribe a gate runner, evidence store, or
channel-specific implementation.

### OutboundCapabilityRequirement and CapabilityPort

**OutboundCapabilityRequirement** is manifest and module metadata:
`id`, `module_id`, `required_capability`, `provider-neutral contract`,
`required_provider_kind`, `authentication_requirement`, `tenant_requirement`,
`observability_requirement`, and status. It describes a capability such as
provider-dependent DNS or storage behavior, not a concrete vendor SDK or API.
It may be empty; vendor-specific models and APIs remain inside infrastructure
adapters.

**CapabilityPort** is an inward-owned application or domain capability contract:
`id`, `owner_inner_layer`, `owner_bounded_context_id`, `capability_semantics`,
`operation_contract`, and `error_contract`. Application code owns outbound
ports it needs (for example persistence, messaging, Gateway management, and
provider capabilities); the inner abstraction expresses platform/domain
capability semantics rather than transport or vendor behavior. Infrastructure
implements the port through an infrastructure adapter. Domain and canonical
Application contracts must not leak vendor, broker, ORM, persistence, Gateway,
or provider-specific types.

Gateway management is represented by a Platform Core-owned application
`CapabilityPort` implemented by a Gateway infrastructure adapter. It is not a
module-owned business API, and Domain/Application code must not depend on
Gateway-product SDKs, plugins, CRDs, administrative APIs, or persistence models.
Messaging, persistence, and provider integrations follow the same inward-port,
outward-adapter direction. A pure domain collaborator with no meaningful
external technology boundary does not require an artificial port.

### DomainEvent, EventContract, Subscription, and EventDelivery — tenant-scoped events, global contracts

**DomainEvent** is immutable and tenant-scoped: `event_id` (UUID),
`aggregate_id`, `tenant_id`, `timestamp`, `event_type`, `data`, `metadata`,
`schema_version`, `source_module_id`, and `correlation_id`. Data is minimal and
uses references rather than full entities where possible. Tenant-scoped
publishing requires a valid current tenant; global/platform events, if any, are
explicitly classified and separately authorized.

**EventContract** is a global versioned registry record: `event_type`,
`schema_version`, `source_module_id`, schema/documentation reference, and
compatibility metadata. `event_type` is globally unique by module namespace
(for example `module.EventName`); contract versions are independently
versioned from internal domain models.

**EventSubscription** fields: `id`, `subscriber_module_id`, `event_type`,
`handler_id`, `status`, and tenant assignment/filter where applicable.
Subscriptions are tenant-scoped for tenant events. A subscriber cannot widen
its tenant access through a filter or platform-wide subscription. A new
subscription receives no events accepted before its activation; previously
assigned delivery obligations remain subject to governed retries and replay.

**DerivedProjection** is owned by the consuming module and remains explicitly
non-authoritative for source facts. Where applicable it identifies the source
module, source contract/event type and version, tenant, source aggregate/resource,
event identity, last-applied version/event/checkpoint, and correlation/trace
context. It is populated from governed Integration Events, not another
module's persistence. Projection freshness, replay, reconciliation, rebuild,
incompatible-version, and unavailable-source behavior are defined by the
owning module without a platform-wide numeric staleness target.

**EventDelivery** tracks the accepted event-to-subscriber obligation:
`id`, `event_id`, `subscription_id`, `subscriber_module_id`, `tenant_id` (for tenant events),
`status`, `attempt_count`, `next_attempt_at`, `last_error` (redacted),
`assigned_at`, and `processed_at`. At-least-once delivery permits duplicate
attempts. Transient errors are retried; persistent errors are dead-lettered,
alerted, and retained for authorized replay. A dead-lettered delivery is still
an outstanding obligation, not successful processing.

Event lifecycle: accepted event is persisted with its operation and outbox
entry; delivery is assigned, attempted/retried, then processed or dead-lettered.
Archive is allowed after the configured retention period (30 days by default,
configurable per tenant), but must preserve pending, in-flight, retrying, and
dead-lettered obligations and the data needed for authorized replay. Archival
does not silently discard or mark an unprocessed event successful.

### Outbox, inbox/idempotency, and request idempotency

**OutboxEntry** is persisted in the same database transaction as the
corresponding domain change and event: `id`, `event_id`, `tenant_id` when
applicable, `created_at`, `status` (`pending`, `published`), `attempt_count`,
`published_at`, and redacted error metadata. A publisher retries pending
entries; broker publication is not treated as an atomic exactly-once effect.

**EventInbox/ProcessedEvent** records successful local subscriber effects:
`subscription_id`, `subscriber_module_id`, `event_id`, `tenant_id` when applicable,
`processed_at`, and effect/result reference. Its unique identity is
`(subscription_id, tenant_id, event_id)` for tenant-scoped events.
The consumer owns this state. Deduplication and the local business effect commit
atomically. Arbitrary external side effects are not guaranteed exactly once.

Publisher-owned Outbox state and consumer-owned Inbox/idempotency state remain
inside their respective private persistence boundaries. A shared supporting
infrastructure does not transfer ownership or prescribe a physical topology.

**IdempotencyRecord** supports canonical API commands across channels:
`tenant_id` (or explicit platform scope), `principal_id`, `operation`, `idempotency_key`,
`request_fingerprint`, `status`, stored outcome/reference, and timestamps.
Uniqueness is scoped to the authorized principal, tenant or platform scope, and operation. Concurrent
reuses with a different request fingerprint must not be interpreted as the
same command. A deployment-defined retention policy covers the supported retry and
asynchronous completion windows, including applicable retries after completion;
in-progress asynchronous protection cannot expire before completion. No universal
duration is specified. The exact conflict response remains a contract decision.

Module drain/uninstall remains pending until every event already assigned to
that module's subscriptions has been successfully processed. Subscription closure and assignment are coordinated so an event
accepted for an active subscription cannot fall between them. The module stops
accepting new assignments as part of drain; assigned events continue to be
retried/replayed, including persistent failures. Only after that tenant's obligations are processed may its handlers unregister
and its enablement reach `unregistered`. Shared deployment code remains registered
while any other tenant is enabled.
The precise mechanism for pausing new assignment while preserving accepted
delivery is an implementation detail.

### Sensitive persisted data and classification

Applicable data-classification and privacy requirements follow sensitive data
across authoritative private persistence, consumer-owned projections, backups,
restore artifacts, exports, archives, analytical copies, and persisted
dead-letter payloads and any other applicable persisted copies. Applicable
sensitive persisted Platform Core and module-owned data, including personally
identifiable information where present, is protected at rest using AES-256.
Each copy preserves its applicable classification, tenant isolation, retention,
and access controls. Classification taxonomy, encryption design, key management,
and implementation mechanism are not selected by this conceptual model.

### ConfigurationValue and ConfigurationChange — global, tenant, or module scope

**ConfigurationValue** fields: `id`, `key`, `source` (`environment`,
`file`, `database`), `scope_type` (`global`, `tenant`, `module`),
`tenant_id`/`module_id` as required by scope, `environment`, `version`,
`value` for non-secrets or `secret_reference` for secrets, `secret` flag,
`valid_from`, and `updated_at`. Secret material lives only in the external
secret manager; neither plaintext nor recoverable secret snapshots are stored
in platform data.

Resolution order is source priority (environment, then file, then database);
within the winning source, the most specific applicable scope is selected
(module, tenant, global). Invalid updates do not replace the last valid value.
Non-critical changes may hot-reload; critical infrastructure changes may need
restart. A database URL update is validated and staged as a candidate, with
the active connection setting unchanged until restart applies it.

**ConfigurationChange** is an audit/change-history record: `id`, configuration
key and scope, `tenant_id`/`module_id` where applicable, actor, reason,
timestamp, validation result, and version. Non-secret changes retain before
and after values. Secret changes retain only redacted references or versions,
never secret values. Staged changes distinguish candidate from active version.

### StandardsVersion, StandardsGrace, and ComplianceReport — global governance

**StandardsVersion** fields: `version`, `release_date`, `breaking_changes`,
`migration_guide`, and enforcement metadata for new installations.

**StandardsGrace** fields: `id`, `standards_version`, `started_at`,
`expires_at`, and the set of already-installed module installations covered.
Grace applies only to modules already installed when the grace period applies.
An installation created during that period must meet the standards enforced
for new installations and is rejected if it does not. After expiry,
non-compliant modules and their dependents are disabled; the core and unaffected
modules remain available.

Grace affects standards conformance only. It never relaxes authentication,
authorization, tenant isolation, secret handling, reviewed-code approval, or
other security controls; every operation must still enforce the strict current
tenant context.

**ComplianceReport** fields: `id`, `module_installation_id`,
`standards_version`, `assessed_at`, `violations` (including remediation
guidance), and compliance status. **ComplianceTransition** history records
module, standards version, prior/new status, and timestamp. Standards releases,
reports, and history are global governance records; access to them is still
authorized.

### API credential — tenant-scoped developer credential

Fields: `id`, `tenant_id`, `owner_user_id`, `label`, `status` (`active`, `revoked`, or
`expired`), `created_at`, `expires_at`, `last_used_at`, `revoked_at`, and either a
one-way `secret_verifier` or an external secret-manager reference. A newly
generated secret is shown only at issuance; it is never recoverable from the
platform database and never appears in audit details or logs. Credential
creation, use-sensitive changes, and revocation are audited.

Credential operations use canonical authorized application capabilities. A
credential acts only within its owner's permitted tenant scope; it cannot
select another tenant or grant itself roles/permissions. Authentication and
authorization are revalidated on every request. Credential format, optional
expiry, and rotation policy are not specified.

## Relationships and ownership summary

- One `Tenant` owns many `User`, `UserRole`, API credential, tenant configuration,
  module submissions and enablements, audit, event subscription/delivery, and
  idempotency records.
- An optional direct-parent `Tenant` relationship is organizational metadata;
  it owns no implicit access. A child tenant owns zero or more
  `TenantDelegatedAdministrationGrant` records for explicit administration by
  its direct parent.
- One `User` belongs to exactly one `Tenant`; `UserRole` links that user only
  to roles valid in the same tenant.
- `ModuleDefinition` has versioned manifests and approved code artifacts;
  `ModuleInstallation` references exactly one approved artifact and may depend
  on other module definitions. Each `TenantModuleEnablement` references one
  shared installation; submission ownership does not confer operator authority.
- Each `ModuleDefinition` owns its versioned manifest declarations,
  `CanonicalApiDeclaration`, `PublishableOperation`, optional
  `OperationalEndpointDeclaration`, and `OutboundCapabilityRequirement`
  records. Module names and versions namespace contracts and have no authority
  to create an unmanaged external listener or route.
- Each module or bounded context owns one or more explicitly declared logical
  private-persistence boundaries for its authoritative state; physical database
  topology is not implied. Consumer-owned projections remain derived and
  reference their authoritative source and applicable event/checkpoint metadata.
- `GatewayRoutePublication` references the module-owned canonical declaration,
  publishable operation, supported contract version, and publication metadata.
  It is not a source of module business semantics and cannot outlive governed
  capability availability.
- `ChannelExposureGateEvidence` binds current gate outcomes and evidence to the
  relevant capability version and applicable exposure channel; material changes
  invalidate eligibility until revalidation.
- `CapabilityPort` is owned by the inner Application or Domain boundary that
  requires it. Infrastructure adapters implement ports for persistence,
  messaging, Gateway management, and providers. Outer/adaptation code may invoke
  authoritative application capabilities, but a port has no vendor-shaped
  contract owned by Infrastructure.
- `ModuleReviewDecision` and `ModuleApprovalDecision` are separate append-only
  records for the exact immutable artifact digest. Each active approval has
  evidence of a positive review and the effective deployment policy version.
- `EventContract` belongs to one source module namespace; events reference the
  contract version and create outbox entries and subscriber delivery
  obligations.
- `EventInbox/ProcessedEvent` is owned by its consumer and uniquely links a
  subscriber to an event to prevent repeated local business effects; the
  publishing module owns its Outbox state.
- `AuthenticationSession` provides the conceptual session identity/status bound
  to access and refresh tokens; its persistence and validation mechanism is
  deferred.
- `StandardsGrace` covers only pre-existing module installations;
  `ComplianceReport` and transition history reference a module installation and
  standards version.
- Configuration history references the same key and scope as the changed
  configuration, while audit records identify the actor and action without
  embedding secrets.

## Invariants, uniqueness, and referential integrity

1. A tenant-scoped record always has a non-null `tenant_id`; references between
   tenant-scoped records must have matching tenant IDs. Repositories apply
   explicit tenant predicates and PostgreSQL row-level security is defense in
   depth. Tenant database session context is established and cleared
   transactionally for pooled connections; physical database/schema topology
   is not selected here.
2. Resolve and validate authenticated tenant context on every tenant operation.
   Missing, invalid, or mismatched context is denied. A suspended tenant cannot
   initiate business operations; explicitly authorized background processing
   and maintenance may continue only under that tenant's context and applicable
   authorization, isolation, audit, and delivery controls. Async consumers
   revalidate tenant context and applicable authorization; caches and
   subscriptions are tenant-keyed and tenant-authorized. Never trust a client
   header, token claim, module, or channel adapter as the sole tenant check.
   Parent-to-child operations revalidate the active child-owned grant and direct
   relationship on every request. They execute under the child tenant context
   and intersect the actor's parent authority with the grant's explicit operation
   scopes and non-delegable rules; they do not grant implicit or transitive access.
3. Global/platform access is a separate, explicit authorization path. No
   nullable-tenant record creates implicit cross-tenant access. Root and child
   provisioning, suspension/reactivation, and initial Tenant Admin bootstrap require
   Platform Operator authority in v1; a tenant-scoped role,
   child-provisioning request, hierarchy, or existing child-administration grant
   does not confer that authority.
4. `Tenant.slug` is unique deployment-wide ignoring case; user email is unique
   within a tenant ignoring case, while the same email may exist in separate
   tenants. Creation and modification enforce these uniqueness rules atomically,
   including concurrent attempts. Tenant role name is unique within that tenant;
   a platform role name is unique within platform scope. No normalization,
   uniqueness-key, or persistence mechanism is prescribed.
5. Module name, module/version, exact approved artifact digest, and namespaced
   event type/schema version are unique in their respective global catalogs.
   Dependency graphs must be acyclic.
6. Event IDs are stable and unique. Outbox records refer to one event.
   `(subscription_id, tenant_id, event_id)` is unique for successful tenant-event processing;
   tenant identity is included in storage/query policy and cannot be bypassed
   by deduplication.
7. An event and its outbox entry are committed atomically with the originating
   operation. A subscriber's local effect and successful inbox record are
   committed atomically. Delivery is at least once; exactly-once transport or
   arbitrary external effects are not promised.
8. A module cannot start/install without validated manifest, operator approval
   for the exact code artifact, resolved acyclic dependencies, and applicable
   enforced standards. A failed module and transitive dependents stay
   unavailable; unaffected modules and core remain available.
9. Uninstall cannot complete while any assigned delivery remains unprocessed,
   including dead-lettered obligations. Archive cannot erase outstanding
   delivery obligations.
10. Configuration source priority and scope precedence are deterministic.
    Invalid candidates leave the active valid value unchanged. Secret values
    are external and redacted in audit, event, and diagnostic data. A database
    URL candidate is staged until restart.
11. Standards grace is limited to already-installed modules and standards
    enforcement. New installations meet current enforced standards; security
    and strict current-tenant controls apply without grace.
12. Audit records are append-only/immutable and retained seven years. Event
    archive retention defaults to 30 days and is configurable per tenant,
    subject to preserving all undelivered obligations.
13. Module review and approval are independent append-only decisions bound to
    the exact computed artifact digest and effective policy version. A
    deployment policy may require distinct identities; otherwise separate
    decision records and identities are still required. Sandbox or malicious-code
    safety must not be inferred from reviewed or approved code.
14. A module exposing a synchronous external capability must have a valid
    machine-readable canonical declaration and publishable operation metadata
    before route activation. Modules with no externally consumable synchronous
    capability need no public API. Public route declaration and capability
    lifecycle are validated together; unmanaged routes and route-only business
    semantics are rejected.
15. A route's last successfully validated data-plane configuration may remain
    active only during control-plane outage and only for an available capability.
    It may not authorize business effects, and route registration/update/
    withdrawal pause until control-plane recovery. Reconciliation restores
    desired state or leaves the publication observable as incomplete.
16. Dependency and architecture certification applies inward-owned ports uniformly
    to Platform Core and all module/extension/topology types. Domain cannot import
    frameworks or vendor infrastructure. Application cannot depend on concrete
    persistence, messaging, Gateway, or provider implementations where an inward
    port is required. Vendor-shaped ports and infrastructure-specific types in
    canonical contracts are rejected.
17. Each authoritative business datum has exactly one owner. Module-owned
    logical persistence boundaries preserve independently verifiable ownership,
    migration authority, access control, tenant isolation, and attribution;
    co-location never authorizes cross-module access. A consumer-owned
    projection is explicitly derived and cannot mutate or replace its source's
    authoritative state.
18. Applicable sensitive persisted Platform Core and module-owned data,
    including applicable persisted copies such as projections, backups,
    exports, archives, analytical copies, restore artifacts, and dead-letter
    payloads, is protected at rest using AES-256 and retains applicable
    classification, tenant isolation, retention, and access controls. The
    encryption mechanism is not selected here.
19. Access and refresh tokens are bound to a logical session. Logout invalidates
    only the current session's refresh credentials and already-issued access
    tokens immediately for subsequent requests. Every applicable request checks
    current session status and fails closed if that status cannot be established;
    other sessions remain usable.
20. A channel exposure is eligible only with current positive evidence for all
    mandatory applicable gates. Missing, failed, expired, or stale evidence
    blocks new exposure; material contract, authorization/policy, tenant,
    certification, architecture, security, or lifecycle changes invalidate
    affected eligibility. Existing exposure is disabled, withdrawn, or
    reconciled under its governed lifecycle and is not reported available while
    mandatory evidence is invalid.

## Lifecycle transition summary

| Record | Allowed lifecycle |
|---|---|
| Tenant | `active ↔ suspended`; suspension preserves retained data |
| Authentication session | `active → revoked` or `active → expired`; revocation immediately invalidates that session's access and refresh credentials |
| Module submission | Created in `pending_review`; Platform Operator transitions: `pending_review → approved/rejected/revoked`, `approved → published/revoked`, `published → revoked`; `rejected` and `revoked` are terminal, as detailed above |
| Module installation | `registered → validating → validated → starting → running → stopping → stopped → unregistering → unregistered`; validation/startup may fail, and dependency failure keeps transitive dependents unavailable |
| Event outbox | `pending → published` (retry pending publication on failure) |
| Event delivery | `assigned → attempting/retrying → processed` or `dead-lettered → authorized replay → attempting/retrying`; dead-lettered remains outstanding |
| Module uninstall | drain/pending while assigned events remain; unregister only after all assigned events process |
| Configuration | `candidate → validated → active`; invalid candidate leaves active value; database URL remains staged until restart |
| API credential | `active → revoked` or `active → expired`; secret material is presented once at issuance |
| Standards compliance | assessed against a version; existing installations may be report-only during grace, then non-compliant modules and their dependents are disabled; new installations are checked against current enforced standards |
| Canonical API declaration | `declared → validating → validated`; validation failure is retained as a rejected declaration |
| Publishable operation | `declared → validating → publishable` or `rejected`; withdrawal removes publishability |
| Channel exposure eligibility | `pending → eligible` only with applicable passing evidence; material changes or failed, missing, expired, or stale evidence invalidate eligibility pending revalidation |
| Gateway route publication | `draft → validating → activating → active`; `validating/activating` may fail to `rejected` or remain `incomplete`; active publications may transition through updating, disabling, suspending, or withdrawing to `disabled`, `suspended`, or `withdrawn` |

## Assumptions and unresolved physical decisions

- The module catalog and shared deployments are global control-plane records;
  per-tenant enablement is separately tenant-owned and authorized.
- A `Tenant` has one stable `isolation_root` referencing its logical isolation
  boundary. Neither that reference nor the module persistence boundary selects
  a physical database, schema, cluster, or server. Enforceable logical
  ownership and tenant isolation remain mandatory; tenant-aware repositories,
  explicit predicates, and row-level security remain as described in research.
- Recovery objectives are deployment-specific operational evidence, not platform
  application entities or selected platform-wide RPO/RTO values. A production
  deployment documents its measurable data-loss/restoration objectives, tests
  recovery against them, and retains test scope, date, outcome, and accepted
  gaps as operational evidence. Approval, evidence format, and ownership remain
  deployment decisions.
- Existing installations are identified at the start of the applicable
  standards grace period. Grace duration and credential expiry policy require
  operational configuration; session-status persistence/validation and API
  idempotency mechanisms remain implementation decisions. A deployment-defined
  policy retains API idempotency records for the supported retry and asynchronous
  completion windows, including applicable retries after completion, without a
  fixed platform-wide duration.
- Secret references are opaque identifiers only. Secret-manager product,
  credential format, and rotation workflow remain infrastructure decisions.
- Tenant slug and email comparisons are case-insensitive, but normalization,
  uniqueness-key, and collision-handling mechanisms are not selected here.
- Sensitive persisted data protection follows the AES-256 outcome and applicable
  classification requirements above; encryption/key-management mechanisms,
  concurrency controls, and idempotency mechanisms remain deferred.
- No Gateway product or deployment capacity target is selected in this model.
- Platform/operator identities are represented as audit actor references;
  their identity-provider schema is outside this feature's stated v1 scope.
