# Feature 001 — Quickstart and Validation Scenarios

**Status:** Future implementation guide. This repository contains no implementation today.
The HTTP paths and payloads below describe the canonical OpenAPI contract; they do not
represent commands or services that are currently runnable. No package script,
deployment command, broker, database, CLI command, SDK, or endpoint is claimed.

> **Tenant authority:** Organization Administrator is a persona mapped to the
> platform-global Platform Operator for provisioning, suspension/reactivation, and
> initial Tenant Admin bootstrap. In v1, the operator creates root and child tenants,
> suspends/reactivates tenants, and bootstraps the initial Tenant Admin when none
> exists; non-admin users do not by themselves prevent bootstrap. A Tenant Admin may
> request a child only through a future explicitly governed capability, but the
> request neither creates nor authorizes a tenant. Hierarchy and child-administration
> grants confer no creation or global administration authority; scoped delegation
> after v1 requires an explicit policy.

## Future setup

The following describes the expected deployment and test environment; it is not a
current setup procedure:

- Deploy the implementation with PostgreSQL, a durable broker, Redis only for transient
  supporting state if retained, and externally managed secrets.
- Use TLS and configure platform-operator bootstrap out of band.
- Define an isolated test tenant pair (`tenant-a` and `tenant-b`) and a platform
  operator with no tenant role.
- Keep the test environments, sample secret references, and artifact digests under
  test fixtures. Never place real passwords or secret values in examples or logs.
- Run contract, integration, cross-channel, concurrency, recovery, security, and
  end-to-end tests only after the implementation exists.

The first platform operator is not created by an API. Use the future deployment's
out-of-band bootstrap mechanism, then authenticate at
`POST /v1/platform/auth/sessions`.

```http
POST /v1/platform/auth/sessions
Content-Type: application/json
X-Correlation-Id: quickstart-platform-login
Idempotency-Key: quickstart-platform-login

{"email":"operator@example.test","password":"<test-password>"}
```

The response is a 15-minute access token. Store it only in the test client's memory;
the refresh cookie is automatically supplied by the future HTTPS client. Never put
credentials or tokens in URLs or logs.

## End-to-end tenant and identity scenario

1. **Provision:** platform operator creates a root tenant.

```http
POST /v1/tenants
Authorization: Bearer <platform-access-token>
Content-Type: application/json
X-Correlation-Id: quickstart-create-tenant
Idempotency-Key: quickstart-create-tenant

{"name":"Example Organization","slug":"example-org"}
```

2. **Bootstrap the first administrator:** only a platform operator may do this,
   once, for a tenant with no existing Tenant Admin. Other users may already exist.

```http
POST /v1/platform/tenants/<tenant-a-id>/bootstrap-administrator
Authorization: Bearer <platform-access-token>
Content-Type: application/json
X-Correlation-Id: quickstart-bootstrap-admin
Idempotency-Key: quickstart-bootstrap-admin

{
  "email":"admin@example.test",
  "displayName":"Test Tenant Admin",
  "password":"<test-password>"
}
```

3. **Authenticate the tenant administrator:** tenant login validates membership and
   sets a 7-day Secure, HttpOnly refresh cookie. Reuse of the refresh cookie does
   not require an access token.

```http
POST /v1/auth/sessions
Content-Type: application/json
X-Correlation-Id: quickstart-admin-login
Idempotency-Key: quickstart-admin-login

{
  "tenantId":"<tenant-a-id>",
  "email":"admin@example.test",
  "password":"<test-password>"
}
```

4. **Create and list users:** use `/v1/tenants/{tenantId}/users` with the tenant
   administrator token. Verify that member and role data are visible only to
   `tenant-a`, and that a `user` role cannot perform tenant-administrator actions.
   Future validation must also prove global, case-insensitive tenant-slug
   uniqueness and tenant-qualified, case-insensitive email uniqueness/concurrency.
   Create slugs that differ only by case (including simultaneous requests) and
   require exactly one accepted result; attempts using the losing slug must be
   denied without mutating tenant state. Across a pair of tenants, prove that
   the same email may identify separate accounts with tenant-qualified sign-in,
   while concurrent attempts to create a second account with the same email in
   one tenant converge to exactly one account. Record the selected normalization
   and collision behavior only as test evidence; the guide does not prescribe
   a persistence mechanism.

5. **Tenant isolation:** repeat reads, writes, configuration access, event
   subscriptions, caches, and database queries from `tenant-b` context. A mismatched
   path identifier or payload tenant must produce `403`, and no other tenant's
   metadata or data may appear. Tenant suspension must deny normal operations while
   retaining records.

Future provisioning and suspension validation:

- Create a child using Platform Operator authority and the direct parent identifier.
  Attempt root and child creation with a Tenant Admin, including with a child
  administration grant; both attempts must be denied under the current policy.
- If a future explicitly governed child-provisioning request capability is
  implemented, verify an authorized Tenant Admin can request a child without
  creating it or granting creation authority.
- Verify that only a Platform Operator can bootstrap the initial Tenant Admin and
  that a tenant-scoped actor cannot do so. Test both a tenant with no users and a
  tenant with non-admin users but no Tenant Admin; both permit otherwise valid
  bootstrap. An existing Tenant Admin blocks initial bootstrap. Verify concurrent
  attempts produce only one initial Tenant Admin, and subsequent attempts remain denied.
- Suspend and reactivate a tenant through Platform Operator authority; deny both
  operations to tenant-scoped roles.
- Attempt tenant-initiated business operations with tenant JWT, API credentials,
  subscriptions, cache access, and event consumers. They must fail closed and
  have no business effect.
- Configure an explicitly authorized maintenance or background fixture for that
  suspended tenant. It may continue only the authorized controlled work; it must
  preserve tenant context, isolation, audit/correlation, replay/deduplication,
  and event-delivery controls. Normal user-triggered work must remain denied.

Future multiple-session logout validation:

- Log in the same account to create a current session and at least one other
  usable session.
- From the current session, log out. Every access token already issued for that
  session must be rejected immediately on subsequent requests, while its refresh
  credential is revoked. The other session's access and refresh credentials must
  remain usable.
- Repeat applicable authorization checks while session-status persistence is
  unavailable or cannot establish current revocation status. Access must fail
  closed: no status-dependent operation may proceed. Restoring sufficiently
  current status must restore only the authorization/effect that the session
  and channel are otherwise allowed to perform.

## Child-owned delegated tenant administration

Use a future fixture with parent tenant `tenant-parent`, direct child
`tenant-child`, an unrelated tenant `tenant-unrelated`, and a parent actor who is
a Tenant Admin in `tenant-parent`. The child may create a grant only for its direct
parent and only with operation IDs from the canonical `x-delegated-tenant-access`
applicable operation list.

```http
POST /v1/tenants/<tenant-child-id>/delegated-admin-grants
Authorization: Bearer <child-tenant-admin-access-token>
Content-Type: application/json
X-Correlation-Id: quickstart-create-delegated-grant
Idempotency-Key: quickstart-create-delegated-grant
If-None-Match: "*"

{
  "parentTenantId":"<tenant-parent-id>",
  "permissions":["listTenantUsers","getTenantUser","replaceTenantUserRoles"]
}
```

Keep the returned grant ID as `<child-grant-id>`. Exercise each request from the
parent actor using the parent JWT and the grant header:

```http
GET /v1/tenants/<tenant-child-id>/users
Authorization: Bearer <parent-tenant-admin-access-token>
X-Delegated-Tenant-Grant: <child-grant-id>
X-Correlation-Id: quickstart-delegated-child-list
```

The server must execute this request in child context and audit the parent actor
and grant identity. Repeat with the applicable update operations. Then verify the
following focused matrix; each denial must be `403` (or another explicit canonical
`Problem` code), must expose no child or unrelated data, and must create attributable
authorization/audit evidence:

| Future test | Request context | Expected outcome |
|---|---|---|
| Direct child, active grant, granted operation | Parent JWT + `<child-grant-id>` + `listTenantUsers` | Allowed only for `tenant-child`; effective context is child |
| Denied cross-child | Parent JWT + child A grant + tenant B child path | Denied; grant and path child mismatch |
| Unrelated parent or tenant | Parent JWT with no direct relationship + grant owned by child, or unrelated tenant path | Denied; no implicit hierarchy or relationship access |
| Ungranted operation | Parent JWT + grant that lists `listTenantUsers` only + `replaceTenantUserRoles` or another omitted operation ID | Denied; grant scope is intersection-only |
| Revoked grant | Child calls `DELETE /v1/tenants/<tenant-child-id>/delegated-admin-grants/<child-grant-id>` with the grant's current `If-Match` ETag and an `Idempotency-Key`, then parent retries an otherwise allowed child operation | Revocation takes effect on the subsequent check; denied |

Hierarchy metadata must not create a grant. A parent grant is never transitive:
the grandchild or a grant owned by one child must not authorize access to another
child. Revoke or remove the direct relationship and retry the operation; the server
must invalidate it as well. API credentials and platform JWTs cannot supply this
tenant-delegated path.

## Cross-channel authorization and tenant test matrix

The future REST, MCP, CLI, portal, SDK, and automation adapters must share the same
authoritative application policy. A test may call a channel's supported adapter, but
must assert identical outcomes and audit evidence; loopback HTTP is not required.

| Future test | Tenant JWT | API credential | Platform JWT | Expected outcome |
|---|---|---|---|---|
| List tenant-a users as tenant-b | tenant-b | none | none | `403`; no tenant-a disclosure |
| Read tenant-b configuration as tenant-a | tenant-a | none | none | `403` |
| Create tenant-a user as user role | tenant-a user | none | none | `403` |
| Issue tenant credential as developer | tenant-a developer | none | none | allowed only within owner tenant |
| Issue tenant credential as ordinary user | tenant-a user | none | none | `403` |
| Provision tenant as tenant admin | tenant-a admin | none | none | `403` |
| Provision tenant as platform operator | none | none | platform_operator | allowed |
| Create child with hierarchy or an existing child-admin grant | tenant-a admin | none | none | `403` under current policy |
| Suspend or reactivate tenant as tenant admin | tenant-a admin | none | none | `403` |
| Bootstrap initial Tenant Admin as tenant admin | tenant-a admin | none | none | `403` |
| Approve module as tenant admin | tenant-a admin | none | none | `403` |
| Approve module as platform operator | none | none | platform_operator | allowed |

Attempt to grant platform-global authority to the Tenant Admin itself and to another
tenant role. Each attempt must be denied without changing effective authority.

For each denied action, verify authentication/authorization audit output, safe
`Problem` response, correlation/trace propagation, and no cross-tenant data in logs,
metrics, traces, or errors. Repeat while pooled database connections are reused and
during concurrent requests.

For every implemented channel, retain the channel conformance matrix as a
cross-channel test: REST, MCP, CLI, portal, SDK, automation, and other external
integrations must invoke the same application capability and preserve identical
authorization, tenant context, validation, audit, correlation/trace, idempotency,
concurrency, and lifecycle outcomes. An operation is not required to gain an
idempotency key merely because it is naturally idempotent or because a channel
is absent. MCP compositions, and MCP tools that compose multiple operations,
must apply the same preconditions and atomicity/effect expectations as their
underlying operations; they must not create a bypass or imply partial success.
Do not claim equivalence for a channel that is not implemented or for a contract
fixture that was not run.

## Events: duplicate, retry, replay, and drain

Before publishing, register or discover the event contract. The contract is a JSON
Schema envelope from `contracts/integration-events-v1.yaml`, not a business-module
payload. The following future example uses `POST /v1/tenants/<tenant-a-id>/events`
and tenant JWT or a tenant-bound credential.

```http
POST /v1/tenants/<tenant-a-id>/events
Authorization: Bearer <tenant-access-token>
Content-Type: application/json
X-Correlation-Id: quickstart-event
Idempotency-Key: quickstart-event-publish

{
  "event_id":"38ad7f3e-8342-4c54-9e8d-22ce532d2112",
  "aggregate_id":"tenant_01HXYZ",
  "tenant_id":"<tenant-a-id>",
  "timestamp":"2026-11-22T18:00:00Z",
  "event_type":"platform.TenantCreated",
  "schema_version":"1.0.0",
  "source_module":"platform.tenant",
  "data":{"tenant_id":"<tenant-a-id>","name":"Example Organization"},
  "metadata":{"correlation_id":"quickstart-event","traceparent":"<test-traceparent>"}
}
```

Future contract tests must verify:

- a mismatched `tenant_id` is denied and never published;
- the event and its outbox entry commit atomically;
- crash recovery retries pending outbox publication;
- repeated delivery with the same `event_id` has no repeated local business effect;
- concurrent duplicate deliveries deduplicate on
  `(subscription_id, tenant_id, event_id)` and commit the inbox record with the effect;
- transient subscriber failure retries with backoff;
- persistent failure becomes dead-lettered but remains an outstanding obligation;
- authorized replay retains the stable `event_id` and creates no duplicate effect;
- a newly activated subscription receives zero events accepted before activation;
  existing assigned delivery obligations remain and continue through governed
  retry/replay handling;
- hot retention does not expire or discard pending, retrying, in-flight, or
  dead-lettered work;
- tenant-b cannot subscribe to tenant-a events and tenant context is revalidated in
  the broker consumer.

### Uninstall drain

Create a tenant subscription with a supported OpenAPI payload:

```http
POST /v1/tenants/<tenant-a-id>/event-subscriptions
Authorization: Bearer <tenant-access-token>
Content-Type: application/json
X-Correlation-Id: quickstart-subscription
Idempotency-Key: quickstart-subscription

{
  "subscriberModuleId":"<approved-module-id>",
  "eventTypes":["platform.TenantCreated"],
  "aggregateIds":[] ,
  "retentionDays":30
}
```

Future uninstall test:

1. Assign one or more deliveries to the module subscription.
2. Call `POST /v1/tenants/<tenant-a-id>/modules/<module-id>/uninstallation` with
   `If-Match`, `Idempotency-Key`, correlation, and tenant administrator authority.
3. Confirm the module and subscription stop accepting new assignments and enter
   draining/pending state.
4. Deliver the assigned events repeatedly; verify successful processing removes the
   obligation and duplicate deliveries remain harmless.
5. Make the subscriber permanently fail. Confirm the dead-lettered delivery keeps
   uninstall pending; use the future authorized replay endpoint
   `/v1/tenants/<tenant-a-id>/event-subscriptions/<subscription-id>/failures/<event-id>/replay`
   only after recovery.
6. Complete uninstall only after every assigned obligation is processed. Do not
   silently archive or waive a pending obligation.

## Module failure and standards grace

Future partner-publication test:

1. Submit an artifact and manifest through
   `POST /v1/tenants/<tenant-id>/module-submissions`; verify a new
   `pending_review` submission and capture its strong ETag.
2. As a Platform Operator, inspect
   `GET /v1/platform/modules/submissions/<submission-id>` for the current
   submission status and strong ETag, and download the exact submitted bytes through
   `GET /v1/platform/modules/submissions/<submission-id>/artifact`.
3. Record the platform-computed SHA-256 artifact digest and verify that review
   and approval both refer to that same immutable digest.
4. Record a positive review with
   `POST /v1/platform/modules/submissions/<submission-id>/review`, then separately
   record approval with `POST /v1/platform/modules/approvals`. Supply the required
   `Idempotency-Key` and the current submission `If-Match` precondition for each
   decision. Re-read the operator submission resource after each decision to obtain
   the current ETag; positive review does not itself approve the submission.
5. Publish through
   `POST /v1/platform/modules/submissions/<submission-id>/publication` with a
   fresh submission ETag and idempotency key. Verify `approved → published` by
   re-reading the submission; publication does not install, activate, certify,
   or expose the module.

The positive approval request identifies the submission, its positive `reviewId`,
the same artifact digest, and `decision: approved`; send the required idempotency
and concurrency preconditions from the contract. The review request binds the digest
to the submission identified in its path.

Use a single submission/digest fixture and a second changed-artifact fixture.
Verify review and approval are distinct, attributable decisions; approval requires
a positive review of the same submission and digest; mismatched or changed digests
are rejected; and neither publication nor installation is possible before an active
approval.

At approval time, the server—not the request—must enforce the deployment-configured
reviewer/approver separation policy and effective policy version. Exercise both
policy modes, where the test deployment configuration is made visible only to the
test runner:

| Deployment policy | Reviewer identity | Approver identity | Expected outcome |
|---|---|---|---|
| Separate identities required | Operator A | Operator A | Rejected; reviewer may not approve |
| Separate identities required | Operator A | Operator B | Approved; review and approval identities plus policy version recorded |
| Same identity permitted | Operator A | Operator A | Approved if the positive review binds the same digest and policy permits self-approval |

The server must record reviewer and approver identities and the effective policy
version in the immutable approval result. Publication and installation must
revalidate the active approval against the exact digest. Changed/unapproved
artifacts, reusing a name or version alone, and developer self-approval are denied.
No core repository access is required for partner submission.

Exercise the submission lifecycle on separate fixtures:

- Verify `pending_review → approved` requires positive review and separate positive
  approval, while a negative review or approval yields terminal `rejected`.
- From `pending_review`, `approved`, and `published`, use the governed operator
  revocation capability and verify each becomes terminal `revoked`. Revocation
  invalidates applicable approval and availability eligibility; affected exposure
  is disabled, withdrawn, or reconciled without discarding assigned deliveries.
- Resubmit after rejection or revocation and submit a changed approved artifact;
  verify each creates a new `pending_review` submission and does not inherit
  previous decisions. Reject all other status changes without mutation; exact
  authorized retries follow the existing idempotency contract.
- For each new review, approval, publication, or revocation, check the current
  submission ETag. Verify missing `If-Match` returns 428, stale `If-Match` returns
  412, and a current-version invalid transition returns 409 with
  `lifecycle_conflict`. Concurrent transitions cannot both succeed on the same
  version; an exact retry reuses the original request, key and ETag, returning its
  recorded outcome without a second transition even if that ETag is now stale.
- Confirm each creation and accepted transition records immutable, secret-free
  tenant/submission IDs, actor, time, previous/new status, digest, reason and
  decision or evidence reference, correlation, and applicable policy version.
  Denied changes are also audited. Verify separate certification and applicable
  contract, architecture, security, authorization, tenant, and channel gates before
  availability or exposure.

For a fixture with the matching test digest, the operator revocation request is:

```http
POST /v1/platform/modules/submissions/<submission-id>/revocation
Authorization: Bearer <platform-access-token>
Content-Type: application/json
If-Match: "<current-submission-etag>"
Idempotency-Key: quickstart-revoke-submission
X-Correlation-Id: quickstart-revoke-submission

{"artifactDigest":"sha256:0000000000000000000000000000000000000000000000000000000000000000","reason":"Test withdrawal"}
```

Future test an optional module whose manifest or startup fails:

- register and validate a reviewed artifact, then induce validation or startup failure;
- verify the core and unaffected modules remain available;
- verify the failed module and transitive dependents are unavailable or disabled;
- verify dependency cycles and unapproved artifact digests are rejected;
- verify an exact approved digest is required; approval of a name or version alone
  is insufficient;
- verify one tenant's uninstall does not stop shared code still enabled for another.

Standards test:

1. Publish a future standards version through
   `POST /v1/platform/standards` with platform authority.
2. Give only already-installed modules a grace deadline.
3. Assess existing modules and report violations with `enforcement: grace_period`
   rather than weakening tenant or security controls.
4. Before grace expiry, attempt a new install that does not meet the currently
   enforced standards. It must be rejected.
5. After expiry, verify non-compliant modules and their dependents are disabled
   while the core and unaffected modules remain available.

Scaffolding is future-only. `POST /v1/scaffolds/modules` with a supported
`ScaffoldModuleRequest` may only generate templates; it must not register, approve,
or install executable code.

## Module data sovereignty and persisted representations

Future certification fixtures must prove that each bounded context owns its
authoritative data, private persistence boundary, migrations, and applicable
Outbox or consumer-owned Inbox. Run positive and negative fixtures with
shared PostgreSQL infrastructure and independent module deployments; reject
direct cross-module database/repository access, cross-module ORM-model or private
service imports, shared authoritative business tables, and shared privileged
normal-runtime credentials. Module-owned migrations and private persistence
must be discoverable and migratable only by their owning module.

Each projection fixture must identify its owning module and authoritative
source. Exercise duplicate, out-of-order, incompatible, missing-tenant,
unavailable-source, stale, replay, reconciliation, and rebuild outcomes. A
projection is explicitly derived state, never an undeclared substitute for
authoritative state, and remains attributable to its owner and tenant/operation
context where applicable.

Verify the Outbox record is committed atomically with the owning module's local
transaction, then published reliably; test crash recovery, stable event identity,
at-least-once retry, and consumer-owned Inbox deduplication. Cross-module effects must not
require global ACID transactions or distributed two-phase commit by default.

Validate every applicable sensitive persisted representation, including
Platform Core and module primary/private persistence, projections, migration
state, backups/restores, exports, archives, analytics/archival copies,
dead-letter payloads, and other derived copies. They must preserve classification,
tenant isolation, retention, and access controls and be protected at rest using
AES-256 without prescribing or requiring a particular implementation mechanism.
Missing or invalid tenant context must fail closed for applicable private,
projection, and derived persistence access.

## Module API declarations and governed publication

Use a reviewed module fixture containing its own versioned OpenAPI document and
the optional `apis` declaration from
[`contracts/module-api-declarations.schema.json`](contracts/module-api-declarations.schema.json).
The module contract remains authoritative for operation IDs, request/response
schemas, and business errors; the declaration describes which contract operations
may be published. `contracts/README.md` documents this boundary. Do not create a
Core-owned replacement business contract or a product-specific Gateway manifest.

Validate this declaration against
`contracts/module-api-declarations.schema.json`, then run the contract validator
against the referenced OpenAPI document and the declaration together. Use a
fixture with this shape (replace the operation ID with one actually defined in
the module's OpenAPI document):

```json
{
  "apis": [
    {
      "contract": {
        "reference": "./contracts/openapi.yaml",
        "version": "1.0.0"
      },
      "operations": ["getExample"],
      "compatibility": {
        "policy": "backward-compatible",
        "supportedVersions": ["1.0.0"]
      },
      "authentication": {
        "required": true,
        "mechanisms": ["Bearer JWT"]
      },
      "authorization": {
        "required": true,
        "requirements": ["example.read"]
      },
      "tenant": {
        "scope": "tenant",
        "contextRequirement": "validated tenant membership"
      },
      "observability": {
        "correlationId": true,
        "traceContext": true
      },
      "publication": {
        "exposure": "tenant-scoped",
        "versionExposure": ["1.0.0"]
      }
    }
  ]
}
```

For the positive fixture, verify schema validity, a resolvable canonical contract
reference, exact contract-version agreement, and that every declared publishable
operation exists in the contract. Also validate any declared operational endpoint
and outbound capability requirements against their applicable contracts. For
negative fixtures, independently remove each required field, add an undeclared
property, duplicate an operation/version, use an unsupported operation ID or
contract version, and omit required authentication/authorization details. Each
invalid declaration or contract must fail validation with an observable reason
and must not become publishable. A module with no external synchronous API must
still pass certification with no `apis` declaration.

For an approved, active module fixture, exercise the Platform Core publication
capability with the module declaration and an operator-authorized publication
decision. Assert that activation is rejected until the contract, version,
compatibility, security/context, observability, module status, and certification
checks pass. After activation, call the published contract through its external
entry point and verify its module-owned response and error semantics. Attempt to
publish an undeclared operation and an unsupported version; neither may be exposed.
Do not infer a Gateway product, administrative endpoint, physical route format,
or internal module address from this scenario.

Before any implemented channel or capability is exposed, run its applicable
canonical-contract, contract-test, architecture-test, security/governance, and
channel-compatibility gates. MCP tool/composition exposure and cross-channel
MCP compositions require the same evidence, plus tests that each composition
preserves tenant, authorization, validation, audit, correlation/trace,
idempotency/concurrency, and lifecycle semantics and cannot bypass the canonical
application capability. Gate evidence must be complete, passing, unexpired, and
matching the exact artifact/declaration/policy versions. Missing, failed,
expired, stale, or mismatched evidence fails closed. Material contract, policy,
tenant-enforcement, lifecycle, module, artifact, or channel changes invalidate
existing eligibility and require revalidation before exposure. Ineligible,
invalidated, disabled, suspended, withdrawn, or stale exposure must be reconciled
or withdrawn.

Update an active publication to a supported compatible version, then withdraw it.
Observe each requested, validated, active, rejected, incomplete, and withdrawn
outcome through the governed publication lifecycle. Verify that only supported
versions become externally available, a failed or partial update/withdrawal is
not reported complete, and a disabled, suspended, uninstalled, expired, or
non-compliant capability is no longer treated as active. The module-owned
contract remains the source of business semantics throughout.

## Topology-independent consumers and control-plane outage

Use the same external consumer and canonical contract before and after changing
the module test deployment from in-process to an independently hosted service.
The consumer must use only the published external contract and must continue to
work without changes to its configured external entry point or knowledge of
internal hosts, ports, service-discovery names, process boundaries, or deployment
topology. Do not require independent deployment for initial module publication.

For the outage test, first activate a route and record the fingerprint/version
of its last successfully validated configuration. Keep the corresponding
capability available, then make the Gateway control plane unavailable while
leaving its data plane running:

1. Call the previously published external operation. It may continue only with
   the recorded last validated configuration and only while the application
   capability remains available.
2. Request a route update, new registration, activation, and withdrawal. Each
   route change must pause; no request may be reported as successfully applied
   while the control plane is unavailable. The outage permits no new exposure
   and no changed exposure: only the last validated configuration for
   capabilities that remain available may continue.
3. Disable the capability through its authoritative module/application lifecycle
   while preserving the outage. Send a request that passes any edge checks but
   targets that capability. The application must deny it, produce no business
   effect, and not treat Gateway acceptance as authorization. Missing or invalid
   operation authorization or tenant context must also fail closed.
4. Inspect the observable control/data-plane discrepancy, last-known-good
   configuration, paused changes, and application denial. No credential, secret
   value, unredacted secret reference, or unauthorized cross-tenant data may
   appear in the evidence.
5. Restore the control plane and reconcile the paused desired state. Verify that
   updates/withdrawals reach an observable terminal result, unavailable
   capabilities remain denied, and recovery/reconciliation is traceable.

## Dependency inversion and certification boundaries

Run the same architecture certification suite against Platform Core, an
in-repository module, an operator-developed module, and a standalone
partner-developed extension. Include in-process and independently hosted
fixtures. The passing fixtures must show Domain/Application depending on
inward-owned capability ports, infrastructure adapters implementing those
ports, and inbound controllers, MCP adapters, and event consumers entering
authoritative application capabilities. Include persistence, Event Bus,
Gateway-management, and provider ports where those boundaries apply. A pure
domain collaborator without an external technology boundary must not require
an artificial interface.

For each applicable architecture boundary, run a negative fixture and verify
that certification fails with the offending dependency and boundary identified:

- Domain imports of NestJS/Fastify, Prisma or another ORM, PostgreSQL clients,
  RabbitMQ/Kafka clients, Gateway SDKs, or provider/vendor SDKs;
- Application business logic imports of concrete repositories, broker clients
  or adapters, Gateway administration APIs/adapters, or provider adapters where
  an inward-owned port is required;
- a vendor-shaped port owned by Infrastructure, infrastructure-specific types
  leaking into Domain or canonical Application contracts, or cross-module
  imports of another module's repository, schema, internal domain, private
  service, or infrastructure adapter.

Verify that the positive Core and module/extension fixtures pass the same rules
regardless of code ownership or topology, and that a module with no public API
does not acquire an artificial one to pass certification.

## Trace and context propagation

Send a test request to a published external operation with a known
`X-Correlation-Id` and valid W3C `traceparent`. Verify the response returns the
correlation identifier and that the same correlation/trace context is observable
across the Gateway, inbound adapter, application capability, domain operation,
infrastructure interaction, and any resulting Integration Event and consumer
processing. Repeat with a generated correlation identifier and verify it is
propagated; do not replace supplied valid context without a governed reason.

Repeat with denied authorization, invalid/missing tenant context, a disabled
capability, and a failed downstream operation. Each result must remain
correlatable and observable without weakening fail-closed behavior. Inspect
responses, audit records, access logs, metrics, traces, and error details:
credentials, access tokens, secret values, unredacted secret references, and
unauthorized cross-tenant data must not be disclosed. For event propagation,
retain applicable event identity, schema version, tenant, correlation/trace
identifiers, delivery attempt, and outcome while preserving the same
sensitive-data exclusions.

## Credential issuance and secret redaction

Issue a credential only as an authorized tenant developer or tenant administrator:

```http
POST /v1/tenants/<tenant-a-id>/api-credentials
Authorization: Bearer <tenant-access-token>
Content-Type: application/json
X-Correlation-Id: quickstart-credential
Idempotency-Key: quickstart-credential

{
  "name":"quickstart-ci",
  "permissions":["events:publish","events:subscribe"]
}
```

Future assertions:

- the initial successful `201` response is the only response that contains `secret`;
- replay with the same key returns `200` metadata only and never repeats disclosure;
- list/get responses contain prefix and metadata only;
- revoked credentials fail authentication and no secret is recoverable;
- a developer can manage only their own credentials; requested scopes cannot
  exceed the issuer's current tenant authority and are revalidated on use;
- mismatched tenant, ordinary `user` role, and cross-tenant credential use are denied;
- credential use and revocation are audited.

Test secret-valued configuration with an external secret reference, not plaintext:

```http
PUT /v1/tenants/<tenant-a-id>/configurations/api.token
Authorization: Bearer <tenant-access-token>
Content-Type: application/json
X-Correlation-Id: quickstart-secret-config
Idempotency-Key: quickstart-secret-config
If-Match: "<expected-etag>"

{
  "scope":"tenant",
  "source":"database",
  "secretReference":"secret://test/api-token:v2",
  "reason":"Rotate test credential reference",
  "schema":{"type":"string"}
}
```

Verify responses, audit, logs, traces, errors, and event data contain neither
`secretReference` secret material nor any submitted secret value. Secret audit
changes must identify a redacted reference/version only.

## Database URL staged/restart scenario

Future `PUT /v1/tenants/<tenant-a-id>/configurations/database.url` test:

```http
PUT /v1/tenants/<tenant-a-id>/configurations/database.url
Authorization: Bearer <tenant-access-token>
Content-Type: application/json
X-Correlation-Id: quickstart-database-url
Idempotency-Key: quickstart-database-url
If-Match: "<expected-etag>"

{
  "scope":"tenant",
  "source":"database",
  "secretReference":"secret://test/database-url:v2",
  "reason":"Stage test database URL for restart",
  "schema":{"type":"string","format":"uri"}
}
```

Future assertions:

- the update is validated and the candidate is marked `staged_for_restart`;
- the active connection setting remains unchanged;
- tenant operations continue using the active connection until restart;
- the staged candidate survives the restart input and becomes active only after
  restart validation/switch;
- restart applies no invalid candidate and leaves the last valid setting active;
- audit records are redacted and never expose the database URL or credentials;
- this staged behavior is verified by a restart test, not inferred from an immediate
  `PUT` response.

For a non-secret hot-reload setting, verify a valid update applies immediately,
an invalid update leaves the last valid value, and audit retains before/after values.
Database URLs are the explicitly staged exception described by the contract.

## Portal accessibility gate

Before a release, evaluate the complete in-scope documentation and developer portal
surface against WCAG 2.2 Level AA. Define the scope, representative page sample,
complete flows, assistive technologies, browser/viewports, and exclusions in the
test evidence. Automated regression checks must cover the same release candidate,
and a human evaluation must include keyboard operation, focus, zoom/reflow,
target size, reading order, forms, errors, notifications, dialogs, code examples,
navigation, and all other applicable success criteria. An automated scan alone is
not conformance evidence.

Record scope, tool/version, human evaluator, date, findings, remediation/exception
status, and release decision. A release is blocked until the in-scope pages and
flows meet the WCAG 2.2 AA gate.

## Deployment-specific recovery objective evidence

Do not select or test a platform-wide RPO or RTO. For every production deployment,
record the deployment's own measurable data-loss objective and restoration-time
objective, the owner, scope, test date/type, evidence, and accepted gaps. Run a
recovery test that demonstrates restoration against those deployment-specific
targets, for example:

- document the target values and their units for a named environment;
- take a recoverable baseline and perform or simulate the documented failure;
- restore the system, database, outbox and durable broker state, and access controls;
- measure elapsed restoration time and measured data-loss interval;
- verify tenant isolation, authentication, active configuration, replay/deduplication
  and outstanding event obligations after restoration;
- retain dated evidence and compare the measured results with the declared targets;
- document accepted gaps and ownership without inventing a platform-wide target,
  universal approval process, or mandatory test cadence.

This is a deployment release/operations gate. The exact format, approval/ownership
workflow, test mechanism, and cadence remain deployment decisions; recovery evidence
must be sufficient to show whether the named deployment met its own objectives.

## Future validation gates

Before releasing a future implementation, the automated suite must cover:

- OpenAPI 3.1 and integration JSON Schema parsing and version compatibility;
- HTTP and channel-conformance contract tests;
- 15-minute JWT and 7-day refresh behavior, credential expiry/revocation, and
  one-time-first-tenant-administrator bootstrap; concurrent global
  case-insensitive slug uniqueness and tenant-qualified, case-insensitive email
  uniqueness/sign-in; multiple-session logout with immediate access-token rejection
  for the current session only, continued usability of other sessions, and
  fail-closed missing/stale session status;
- Platform Operator-only root/child creation in v1, suspension/reactivation, and
  initial Tenant Admin bootstrap; future governed child requests cannot create a
  tenant or grant authority;
- cross-tenant read/write/configuration/event/cache/database and pooled-session tests;
- suspended-tenant tenant-initiated denial and only explicitly authorized
  controlled background/maintenance work;
- retry/concurrency behavior where required: `Idempotency-Key` only for operations
  that need an operation identity for retry safety, plus `If-Match`,
  `If-None-Match`, stale precondition, and payload-key conflict behavior; do not
  require keys for naturally idempotent operations or channels that do not implement
  the operation. Verify the deployment-defined retention policy protects retries
  throughout the supported retry and asynchronous completion windows, including
  applicable retries after completion, and never expires in-progress protection;
- module approval, lifecycle, dependency, failure, standards, uninstall drain, and
  replay/recovery cases;
- module-owned persistence, migrations and projections; publisher-owned Outbox
  atomically paired with its local business transaction and consumer-owned Inbox
  atomically paired with its local effect; deduplication/replay and classification/
  tenant controls;
  100% of applicable sensitive primary/private persistence, projections, migrations,
  backups/restores, exports, archives, analytics/archival copies, and dead-letter
  payloads protected at rest using AES-256 without prescribing a mechanism;
- mandatory pre-exposure contract, architecture, security/governance, and
  channel-compatibility evidence for every implemented channel; MCP tools and
  MCP compositions and cross-channel flows must pass the same gates and cannot
  bypass application controls;
- module API declaration JSON Schema validation, module-owned OpenAPI validation,
  operation/version correspondence, and rejection of undeclared or unsupported
  publication;
- governed route activation, update, withdrawal, topology-independent consumers,
  control-plane outage with last-validated routes only for available capabilities,
  no new or changed exposure during outage, application-level fail-closed behavior,
  invalidation/revalidation of eligibility, and observable recovery;
- uniform DIP architecture certification for Platform Core, modules, and extensions,
  including permitted inward-owned ports and rejected infrastructure/vendor leakage;
- Gateway-to-application and event trace/context propagation with credential, secret,
  and cross-tenant-data exclusion from responses, audit, logs, metrics, traces, and
  errors;
- redaction in credentials, configuration, audit, logs, traces, metrics, and errors;
- staged database restart and last-valid-value preservation;
- immutable seven-year audit retention and 30-day event hot retention semantics while
  preserving undelivered obligations;
- independent constitutional coverage gates: Domain 85% minimum and at least 95%
  for every critical Domain scope; Application 85% minimum and at least 95% for
  every critical Application scope; Infrastructure 70%; Presentation 60%; and
  unit tests for every generated feature 85%; required unit, integration, contract,
  architecture, end-to-end, and applicable security/authorization boundary gates
  must pass independently, with zero untested or failing mandatory boundaries
  masked by aggregate coverage;
- all applicable feature success criteria and deployment-specific performance
  targets in documented environments only; benchmark conditions are not current
  performance claims.
