# Tasks: Platform Core Foundation

**Input**: Design documents in `specs/001-platform-core-foundation/`
**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/`
**Task scope**: This feature has no implementation yet. Tests are included because the specification and Constitution require unit, integration, contract, architecture, accessibility, performance, and end-to-end verification.

> **Authority**: The Platform Operator creates root and child tenants, suspends or
> reactivates tenants, and bootstraps the initial Tenant Admin in v1. Tenant roles
> do not gain platform authority. The provisioning persona is not a separate role.
> The existing contracts have passed design-time parser validation; implementation
> and release still require the independent gates and evidence in `plan.md`.

## Format

- Every task uses `- [ ] T### [P?] [US#?] Description ... in \`path\``.
- `[P]` means the task can run in parallel with other ready tasks in its phase.
- User-story tasks carry their `[US#]` label; setup, foundational, and polish tasks do not.
- Data-model field citations identify the canonical field constraints in
  `specs/001-platform-core-foundation/data-model.md`; API and event shape citations
  identify `specs/001-platform-core-foundation/contracts/`.

## Phase 1: Setup

**Purpose**: Establish the Node.js project, shared tooling, local dependencies, and test runners.

- [ ] T001 Initialize the Node.js 22+ / TypeScript 5+ npm project with NestJS, Fastify, build/start scripts, and the planned `src/main.ts` composition root in `package.json` and `src/main.ts`.
- [ ] T002 [P] Configure the Constitution's `strict`, `strictNullChecks`, `noImplicitAny`, `noImplicitThis`, `alwaysStrict`, `noFallthroughCasesInSwitch`, `noUncheckedIndexedAccess`, `exactOptionalPropertyTypes`, and `useUnknownInCatchVariables`, plus the requested additional `noImplicitReturns`, in `tsconfig.json`; apply them to generated and test code without weakening them unless the Constitution expressly permits it. Add negative compilation fixtures for implicit any, nullability, unchecked indexed access, exact optional properties, an unintended switch fallthrough and a missing return in `test/architecture/typescript-compiler-options.test.ts`; T004 must run them in CI and retain evidence of expected compiler failures.
- [ ] T003 [P] Add Docker build and local PostgreSQL, Redis, and RabbitMQ service definitions in `infra/Dockerfile` and `infra/docker-compose.yml`.
- [ ] T004 Configure independent CI coverage gates for Domain >=85%, critical Domain >=95%, Application >=85%, critical Application >=95%, Infrastructure >=70%, Presentation >=60%, and unit tests for each generated feature >=85% in `jest.config.ts`, `package.json`, and `.github/workflows/ci.yml`; emit and retain machine-readable reports identifying each scope, metric, threshold and pass/fail, and fail each missed scope even if aggregate coverage passes. Run the T002 compiler-negative fixtures, including fallthrough, and require unit, contract, architecture, integration, end-to-end, security and authorization boundary tests independently of coverage percentages; run T115/T116 source-version and stale-documentation checks in CI. Do not impose a blanket 95% target on all security code (FR-121; SC-073; Constitution testing and TypeScript gates).

## Phase 2: Foundational

**Purpose**: Implement cross-cutting prerequisites that user stories depend on.

- [ ] T005 Create the bounded-context and channel composition skeleton from `plan.md` in `src/contexts/tenant/index.ts`, `src/contexts/identity-access/index.ts`, `src/contexts/audit/index.ts`, `src/contexts/eventing/index.ts`, `src/contexts/module-catalog/index.ts`, `src/contexts/configuration/index.ts`, `src/contexts/governance/index.ts`, and `src/channels/index.ts`.
- [ ] T006 Implement shared typed application, domain, authorization, validation, integration, and infrastructure error classes plus canonical problem mapping in `src/shared/application/errors/platform-error.ts` and `src/shared/application/problem/problem.mapper.ts`.
- [ ] T007 [P] Establish Prisma PostgreSQL connectivity, migration conventions, transaction-scoped tenant session setup/cleanup, and row-level-security policy scaffolding in `prisma/schema.prisma` and `src/shared/infrastructure/persistence/tenant-session.ts`; do not provision module-private persistence before T073.
- [ ] T008 [P] Add request validation, response serialization, and canonical OpenAPI 3.1 plus JSON Schema 2020-12 validation scripts in `src/shared/presentation/validation/request-validation.pipe.ts`, `src/shared/presentation/encoding/context-output-encoder.ts`, `scripts/validate-contracts.ps1`, and `package.json`. Enforce applicable allowlists or bounded schemas for enums, module/capability/provider identifiers, event types, contract versions, filters, sorts, query operators, Gateway metadata, manifests, URLs/redirects, paths, content types and character sets; encode output for its actual JSON, header, structured-log, audit, HTML, CLI, documentation, error or telemetry sink without exposing secrets. T061 verifies rejection or safe handling before exposure (FR-077, FR-090; SC-044).
- [ ] T009 Implement the shared immutable audit write port and persistence adapter with seven-year retention for `AuditRecord.id`, `AuditRecord.tenant_id`, `AuditRecord.actor_type`, `AuditRecord.actor_id`, `AuditRecord.action`, `AuditRecord.target_type`, `AuditRecord.target_id`, `AuditRecord.occurred_at`, `AuditRecord.reason`, `AuditRecord.correlation_id`, `AuditRecord.effective_tenant_id`, `AuditRecord.parent_tenant_id`, `AuditRecord.parent_actor_id`, `AuditRecord.delegation_grant_id`, and redacted details from `data-model.md` in `src/contexts/audit/domain/audit-record.ts` and `src/contexts/audit/infrastructure/audit-repository.ts`.
- [ ] T010 [P] Bootstrap structured logging, OpenTelemetry traces/metrics, W3C trace propagation, and correlation-ID middleware in `src/shared/observability/otel-bootstrap.ts` and `src/channels/api/correlation.middleware.ts`.
- [ ] T011 [P] Define reusable timeout, retry, circuit-breaker, and bulkhead ports/policies for external adapters in `src/shared/application/resilience/resilience-policy.ts` and `src/shared/infrastructure/resilience/resilience-executor.ts`.
- [ ] T012 Add architecture tests that enforce context-first dependencies, inward-only Clean Architecture dependencies, pure domain layers, and no Prisma/framework/broker imports in domain/application code in `test/architecture/clean-architecture.test.ts` and `test/architecture/module-boundaries.test.ts`.
- [ ] T013 Add database-backed integration fixtures for PostgreSQL, RLS, Redis transient state, and RabbitMQ adapter tests without sharing tenant state across test runs in `test/integration/support/platform-fixtures.ts`.

**Checkpoint**: Shared project, architecture, persistence, audit, validation, observability, and test foundations are ready.

## Phase 3: User Story 1 - Platform Operator Provisions and Tenant Admin Manages Tenant (Priority: P1)

**Goal**: Provision and manage isolated tenants under the clarified platform and tenant authority boundaries, and support explicit direct-parent delegated administration.

**Independent Test**: As Platform Operator create root and child tenants, suspend/reactivate and bootstrap; deny tenant-scoped actors, then verify isolation, suspended-tenant background rules, and scoped, non-transitive delegated access.

- [ ] T014 [P] [US1] Add failing tenant API and isolation contract tests for Platform Operator-only root/child creation and suspension/reactivation, denial of tenant roles including hierarchy/grant cases, case-insensitive slug uniqueness under concurrency, authorized suspended-tenant background work, child-context execution, and explicit delegation in `test/contract/tenant/tenant.contract.test.ts` and `test/integration/tenant/tenant-isolation.test.ts`.
- [ ] T015 [US1] Implement explicit Platform Operator provisioning and lifecycle authorization, denying tenant roles and any implied authority from hierarchy or child administration in `src/contexts/tenant/application/tenant-provisioning-policy.ts`.
- [ ] T016 [P] [US1] Implement the `Tenant` domain entity and repository port for `Tenant.id`, `Tenant.name`, `Tenant.slug`, `Tenant.status`, `Tenant.parent_tenant_id`, `Tenant.isolation_root`, `Tenant.created_at`, and `Tenant.updated_at` as defined in `data-model.md` in `src/contexts/tenant/domain/tenant.ts` and `src/contexts/tenant/application/ports/tenant.repository.ts`.
- [ ] T017 [P] [US1] Implement verified tenant-context resolution, suspended-tenant denial, and child-context selection in `src/contexts/tenant/application/tenant-context.ts` and `src/contexts/tenant/presentation/tenant-context.guard.ts`.
- [ ] T018 [US1] Implement tenant-aware Prisma repositories, tenant predicates, RLS transaction context, and pooled-connection cleanup for the `Tenant` model in `src/contexts/tenant/infrastructure/prisma-tenant.repository.ts` and `src/contexts/tenant/infrastructure/tenant-transaction.ts`.
- [ ] T019 [US1] Implement tenant lifecycle and settings/member query use cases and canonical HTTP adapters using the resolved tenant context and identity/configuration ports, applying T015, in `src/contexts/tenant/application/tenant-lifecycle.handlers.ts`, `src/contexts/tenant/application/tenant-resource.handlers.ts`, and `src/contexts/tenant/presentation/tenant.controller.ts`.
- [ ] T020 [US1] Implement explicit child-owned grants for `TenantDelegatedAdministrationGrant.id`, `TenantDelegatedAdministrationGrant.child_tenant_id`, `TenantDelegatedAdministrationGrant.parent_tenant_id`, `TenantDelegatedAdministrationGrant.allowed_operations`, `TenantDelegatedAdministrationGrant.status`, `TenantDelegatedAdministrationGrant.created_by`, `TenantDelegatedAdministrationGrant.created_at`, `TenantDelegatedAdministrationGrant.revoked_by`, `TenantDelegatedAdministrationGrant.revoked_at`, and `TenantDelegatedAdministrationGrant.revocation_reason` from `data-model.md` in `src/contexts/tenant/domain/delegated-admin-grant.ts` and `src/contexts/tenant/application/delegated-admin-grant.handlers.ts`.
- [ ] T021 [US1] Implement grant create/list/revoke APIs and per-request authorization that checks direct parent, actor authority, exact operation scope, grant status, hierarchy changes, and child effective context in `src/contexts/tenant/presentation/delegated-admin-grants.controller.ts` and `src/contexts/tenant/application/delegated-tenant-authorizer.ts`.
- [ ] T022 [US1] Add tenant, grant-revocation, denied-cross-tenant, hierarchy-change, audit-attribution, and pooled-connection end-to-end tests in `test/e2e/tenant/tenant-lifecycle.e2e.ts` and `test/integration/tenant/delegated-administration.test.ts`.

## Phase 4: User Story 2 - Identity Administrator Creates Users and Assigns Roles (Priority: P1)

**Goal**: Manage tenant users and roles, authenticate with JWT/refresh tokens, and enforce deny-by-default authorization.

**Independent Test**: Create users with distinct roles, authenticate and refresh, verify tenant/role claims and membership, and prove unauthorized operations are denied.

- [ ] T023 [P] [US2] Add failing identity unit tests for tenant membership, role assignment invariants, denial of Tenant Admin attempts to grant platform authority to itself or another tenant role, password verification, JWT claims, refresh behavior, and deny-by-default RBAC in `test/unit/identity-access/identity-and-rbac.test.ts`.
- [ ] T024 [P] [US2] Implement `User.id`, `User.tenant_id`, `User.email`, `User.password_hash`, `User.display_name`, `User.created_at`, `User.updated_at`, `User.last_login_at`; `Role.id`, `Role.name`, `Role.permissions`, `Role.scope`, `Role.tenant_id`; and `UserRole.user_id`, `UserRole.role_id`, `UserRole.tenant_id`, `UserRole.assigned_at`, `UserRole.assigned_by` from `data-model.md` in `src/contexts/identity-access/domain/user.ts`, `src/contexts/identity-access/domain/role.ts`, and `src/contexts/identity-access/domain/user-role.ts`.
- [ ] T025 [US2] Implement user create/list/update, role replacement that cannot grant platform authority, tenant-qualified login, refresh, session-scoped immediate logout, and Platform Operator-only initial Tenant Admin bootstrap when no Tenant Admin exists, including tenants with non-admin users, with audit-port calls in `src/contexts/identity-access/application/user.handlers.ts` and `src/contexts/identity-access/application/session.handlers.ts`.
- [ ] T026 [P] [US2] Implement tenant-aware identity repositories, bcrypt-equivalent password hashing, JWT signing/validation, and secure refresh-cookie/session adapters for `AuthenticationSession.session_id`, `AuthenticationSession.status`, `AuthenticationSession.user_id`, and `AuthenticationSession.tenant_id` from `data-model.md`, with separately scoped platform sessions and fail-closed status checks, in `src/contexts/identity-access/infrastructure/user.repository.ts` and `src/contexts/identity-access/infrastructure/token.adapter.ts`.
- [ ] T027 [US2] Implement canonical session and tenant-user HTTP operations, guards, and role policy enforcement from `contracts/openapi.yaml` in `src/contexts/identity-access/presentation/identity-access.routes.ts` and `src/channels/api/identity-access.controller.ts`.
- [ ] T028 [P] [US2] Add real-PostgreSQL identity integration tests for tenant-qualified case-insensitive email uniqueness under concurrency, token membership revalidation, immediate session-only logout and fail-closed session-status outage, bootstrap with no users or non-admin users, denial to tenant roles or with an existing Tenant Admin, concurrent bootstrap, and audit redaction in `test/integration/identity-access/identity.persistence.test.ts` and `test/integration/identity-access/session-flow.test.ts`.
- [ ] T029 [US2] Add identity OpenAPI contract and end-to-end tests for create-user/assign-role/login/refresh/denied-operation flows, including role restrictions and safe errors, in `test/contract/identity-access.contract.test.ts` and `test/e2e/identity-access/identity-flow.e2e.ts`.

## Phase 5: User Story 3 - Developer Scaffolds a New Module Using Platform Templates (Priority: P1)

**Goal**: Scaffold standards-compliant modules and statically validate governed event/synchronous contracts and forbidden dependencies.

**Independent Test**: Run the scaffold command, inspect generated files, and verify manifests and architecture rules accept valid declarations and reject forbidden dependencies and cycles.

- [ ] T030 [P] [US3] Add failing scaffold, manifest, and architecture tests for generated structure, versioned contract discovery, forbidden imports, and synchronous dependency cycles in `test/unit/module-catalog/module-scaffold.test.ts` and `test/architecture/module-boundaries.test.ts`.
- [ ] T031 [P] [US3] Define module manifest and scaffold template files for `ModuleDefinition.id`, `ModuleDefinition.description`, `ModuleDefinition.current_version`, `ModuleDefinition.manifest_reference`, `ModuleDefinition.created_at`, `ModuleDefinition.updated_at`, manifest name/version/dependencies/permissions, and `EventContract.event_type`, `EventContract.schema_version`, and `EventContract.source_module_id` from `data-model.md` in `templates/module/module.sdd.json.hbs` and `src/contexts/module-catalog/domain/module-manifest.ts`.
- [ ] T032 [US3] Implement `sdd-cli module:scaffold --name` as a presentation adapter that invokes the governed scaffold use case and propagates validation/correlation results in `src/channels/cli/module-scaffold.command.ts`.
- [ ] T033 [US3] After T148, implement deterministic module structure/manifest generation in `src/contexts/module-catalog/application/scaffold-module.handler.ts` and `src/contexts/module-catalog/infrastructure/template-renderer.ts`; obtain the current applicable standards version, put it in newly scaffolded manifests, and run T034 static standards checks without registration, approval, or install side effects. T070/T105 automatically assess generated modules before activation, T173 completes template validation, and T038 verifies compliant generation and rejection of non-compliant output (FR-026–FR-027, FR-034–FR-036; SC-003, SC-019).
- [ ] T034 [US3] Implement static parsing and discoverability checks for published/required event, query, permission, and canonical synchronous contracts in `src/contexts/module-catalog/application/module-contract-validator.ts`.
- [ ] T035 [US3] Implement synchronous-contract dependency graph construction and cycle rejection in `src/contexts/module-catalog/application/synchronous-contract-graph.ts`.
- [ ] T036 [P] [US3] Add architecture fixtures and rules in `test/architecture/forbidden-imports.test.ts` rejecting cross-module repositories, schemas/databases, persistence, infrastructure/providers, internal domains, private services, publication of cross-module asynchronous messages outside the Platform Event Bus, direct Domain/Application broker clients, undeclared Integration Events, unregistered exchange/queue shortcuts, webhook/background-job substitutions for governed cross-module asynchronous communication, synchronous wrappers disguising asynchronous integration, and bypasses of registry, tenant, trace/correlation, schema version, certification, Outbox or idempotency controls. Accept local Domain Events translated explicitly to Integration Events through the platform-owned Event Bus port, broker clients only in Infrastructure, and approved synchronous calls only for inherent immediate-result needs; T070/T133 enforce certification (FR-055–FR-056, FR-063, FR-066; SC-020–SC-021, SC-028).
- [ ] T037 [US3] Implement approved synchronous application-port invocation that preserves tenant/auth context, authorization, policy, validation, audit, idempotency, concurrency, correlation, and tracing in `src/contexts/module-catalog/application/synchronous-module-port.ts`.
- [ ] T038 [US3] Add CLI, template completeness, manifest discovery, architecture, and synchronous-port contract/integration tests in `test/integration/module-catalog/module-scaffold.test.ts` and `test/contract/module-catalog/module-scaffold.contract.test.ts`.

## Phase 6: User Story 4 - Module Developer Communicates Through the Platform Event Bus (Priority: P1)

**Goal**: Publish and consume versioned Integration Events through a tenant-safe, at-least-once Event Bus with transactional outbox and idempotent effects.

**Independent Test**: Publish a valid event with no subscriber dependency, then verify durable acceptance, authorized delivery, duplicate-safe effects, retry/dead-letter/replay, correlation, and no historical backfill to new subscriptions.

- [ ] T039 [P] [US4] Add failing envelope, registry, tenant-filter, outbox atomicity, delivery retry, no-backfill, ordering, and duplicate-consumption tests in `test/contract/eventing/event-envelope.contract.test.ts`, `test/integration/eventing/outbox-and-delivery.test.ts`, and `test/architecture/eventing-boundaries.test.ts`.
- [ ] T040 [P] [US4] Implement canonical event envelope and registry validation for `DomainEvent.event_id`, `DomainEvent.aggregate_id`, `DomainEvent.tenant_id`, `DomainEvent.timestamp`, `DomainEvent.event_type`, `DomainEvent.data`, `DomainEvent.metadata`, `DomainEvent.schema_version`, `DomainEvent.source_module_id`, `DomainEvent.correlation_id`, `EventContract.event_type`, `EventContract.schema_version`, and `EventContract.source_module_id` from `data-model.md`, including the contract's compatibility metadata, in `src/contexts/eventing/domain/integration-event.ts` and `src/contexts/eventing/domain/event-contract.ts`, conforming to `contracts/integration-events-v1.yaml`.
- [ ] T041 [US4] Implement the explicit internal Domain Event to Integration Event mapping boundary in `src/contexts/eventing/domain/domain-event-mapper.ts` and `src/contexts/eventing/application/publish-integration-event.handler.ts`.
- [ ] T042 [US4] Implement `OutboxEntry.id`, `OutboxEntry.event_id`, `OutboxEntry.tenant_id`, `OutboxEntry.created_at`, `OutboxEntry.status`, `OutboxEntry.attempt_count`, `OutboxEntry.published_at`, and redacted error metadata; plus `EventInbox/ProcessedEvent.subscription_id`, `EventInbox/ProcessedEvent.subscriber_module_id`, `EventInbox/ProcessedEvent.event_id`, `EventInbox/ProcessedEvent.tenant_id`, `EventInbox/ProcessedEvent.processed_at`, and effect reference from `data-model.md` in `src/contexts/eventing/infrastructure/persistence/outbox-entry.repository.ts` and `src/contexts/eventing/infrastructure/persistence/event-inbox.repository.ts`.
- [ ] T043 [US4] Implement application-owned publish/subscribe/acknowledgment ports without broker SDK types in `src/contexts/eventing/application/ports/event-bus.port.ts`.
- [ ] T044 [US4] Implement durable RabbitMQ publication, tenant-qualified routing, acknowledgments, retry topology, and retained dead-letter delivery behind the port in `src/contexts/eventing/infrastructure/rabbitmq/rabbitmq-event-bus.adapter.ts`.
- [ ] T045 [US4] Implement transactional publication orchestration that atomically records business state and pending outbox work, preserving stable event identity and at-least-once semantics; use US12 command protection for applicable request retries in `src/contexts/eventing/application/publish-event.handler.ts` and `src/contexts/eventing/domain/outbox-coordinator.ts`.
- [ ] T046 [US4] Implement EventSubscription operations and tenant/event/aggregate filtering for `EventSubscription.id`, `EventSubscription.subscriber_module_id`, `EventSubscription.event_type`, `EventSubscription.handler_id`, `EventSubscription.status`, and tenant assignment/filter from `data-model.md` in `src/contexts/eventing/domain/event-subscription.ts` and `src/contexts/eventing/application/subscription.handlers.ts`.
- [ ] T047 [US4] Implement EventDelivery assignment, bounded retry, dead-letter, alert, and authorized replay for `EventDelivery.id`, `EventDelivery.event_id`, `EventDelivery.subscription_id`, `EventDelivery.subscriber_module_id`, `EventDelivery.tenant_id`, `EventDelivery.status`, `EventDelivery.attempt_count`, `EventDelivery.next_attempt_at`, `EventDelivery.last_error`, `EventDelivery.assigned_at`, and `EventDelivery.processed_at` from `data-model.md` in `src/contexts/eventing/application/delivery.handlers.ts` and `src/contexts/eventing/infrastructure/delivery-worker.ts`. Distinguish pausing delivery from stopping new assignments during drain/withdrawal, coordinate closure and assignment so accepted active-subscription work cannot fall between them, and preserve accepted obligations during subscriber disablement, suspension, uninstall and contract-version changes. Define and test new-assignment behavior while disabled consistently with subscription status and T147 policy; allow authorized retry/maintenance and replay after reactivation, and activate new versions only after compatibility validation. Retain tenant, event, correlation and trace identity and expose pending/dead-letter outcomes without loss or historical backfill; verify disabled/paused/withdrawn subscribers, incompatible versions and replay in `test/integration/eventing/delivery-lifecycle.test.ts` (FR-014, FR-064, FR-068–FR-069; SC-030, SC-034).
- [ ] T048 [US4] Implement atomic inbox deduplication by the `EventInbox/ProcessedEvent.subscription_id`, `EventInbox/ProcessedEvent.tenant_id`, and `EventInbox/ProcessedEvent.event_id` unique identity, committing the subscriber's local effect atomically as defined in `data-model.md` in `src/contexts/eventing/application/idempotent-event-handler.ts` and `src/contexts/eventing/infrastructure/persistence/event-inbox.repository.ts`.
- [ ] T049 [US4] Revalidate authoritative tenant context and authorization in publisher, router, retry, dead-letter, replay, and consumer paths; audit denied/successful operations through the shared audit port in `src/contexts/eventing/application/event-authorization.ts`.
- [ ] T050 [US4] Reject duplicate active registrations and ensure new subscriptions receive no pre-activation events while assigned obligations remain retryable/replayable in `src/contexts/eventing/application/register-subscription.handler.ts`.
- [ ] T051 [US4] Implement the configurable per-tenant event archive policy with its specified default while preserving pending, in-flight, retrying and dead-letter obligations and replay data in `src/contexts/eventing/application/event-archive-policy.ts`.
- [ ] T052 [US4] Validate declared event ordering requirements and prevent out-of-order consumer effects from violating them in `src/contexts/eventing/domain/event-ordering-policy.ts` and `src/contexts/eventing/application/ordered-event-consumer.ts`.
- [ ] T053 [US4] Add real-broker, outbox recovery, concurrency, tenant-isolation, audit/policy, retry/dead-letter/replay, schema compatibility, ordering, tracing, and publisher-independence tests in `test/integration/eventing/rabbitmq-event-bus.test.ts`, `test/contract/eventing/event-registry.contract.test.ts`, and `test/e2e/eventing/event-delivery.e2e.ts`.

## Phase 7: User Story 11 - Platform Operator Governs External API Publication (Priority: P1)

**Goal**: Govern publication and lifecycle of canonical Core and module APIs through a product-neutral Gateway boundary.

**Independent Test**: Publish a certified supported API, reject invalid declarations and missing gates, then disable its capability and verify withdrawal or denial, including control-plane outage and recovery.

- [ ] T054 [P] [US11] Add failing contract and integration tests in `test/contract/gateway/publication.contract.test.ts` and `test/integration/gateway/publication-lifecycle.test.ts` for an owning module's correct inbound adapter, wrong-module targets, missing contracts, contract-version mismatches, routes to private persistence/provider adapters, stale or orphaned routes, invalidation/withdrawal reconciliation, retained auditable route-to-contract evidence, valid last-known-good routes during control-plane outage and denial of new or changed routes during outage (FR-072, FR-075, FR-078, FR-090; SC-040, SC-042, SC-051).
- [ ] T055 [US11] The platform architecture owner records a Gateway product-selection ADR against the constitutional criteria, including operational endpoints and control/data-plane behavior, in `docs/adr/gateway-selection.md`; retain evaluated product evidence and block product-specific T057/T140 until approved.
- [ ] T056 [US11] Implement validation of module-owned canonical declarations and publication metadata against `contracts/module-api-declarations.schema.json` and `data-model.md` for `CanonicalApiDeclaration.id`, `CanonicalApiDeclaration.module_id`, `CanonicalApiDeclaration.contract_name`, `CanonicalApiDeclaration.contract_version`, `CanonicalApiDeclaration.machine_readable_contract`, `CanonicalApiDeclaration.compatibility_rule`, `CanonicalApiDeclaration.request_semantics`, `CanonicalApiDeclaration.response_semantics`, `CanonicalApiDeclaration.business_error_semantics`, `CanonicalApiDeclaration.authentication_requirement`, `CanonicalApiDeclaration.authorization_requirement`, `CanonicalApiDeclaration.tenant_requirement`, `CanonicalApiDeclaration.observability_requirement`, `PublishableOperation.id`, `PublishableOperation.canonical_api_declaration_id`, `PublishableOperation.operation_name`, `PublishableOperation.availability_scope`, `PublishableOperation.compatibility_rule`, `PublishableOperation.authentication_requirement`, `PublishableOperation.authorization_requirement`, `PublishableOperation.tenant_requirement`, and `PublishableOperation.observability_requirement` in `src/contexts/gateway/application/api-declaration.validator.ts`; certify each route/version against an approved machine-readable contract and its owning module's inbound adapter, never another module's internal adapter, repository or provider, and retain auditable correspondence evidence for T054 (FR-072–FR-073, FR-090; SC-040).
- [ ] T057 [US11] Implement the inward-owned Gateway management port and product-specific adapter selected by T055; apply declared edge authentication, traffic, quota, request-size, abuse, CORS, logging, metrics, and trace policy without encoding business authorization in `src/contexts/gateway/application/ports/gateway-management.port.ts` and `src/contexts/gateway/infrastructure/gateway.adapter.ts`.
- [ ] T058 [US11] Implement publication state and lifecycle for `GatewayRoutePublication.id`, `GatewayRoutePublication.module_id`, `GatewayRoutePublication.module_installation_id`, `GatewayRoutePublication.canonical_api_declaration_id`, `GatewayRoutePublication.publishable_operation_id`, `GatewayRoutePublication.supported_contract_version`, `GatewayRoutePublication.route_publication_metadata_id`, `GatewayRoutePublication.status`, `GatewayRoutePublication.validation_evidence`, `GatewayRoutePublication.last_validated_configuration`, `GatewayRoutePublication.last_validated_at`, `GatewayRoutePublication.data_plane_status`, `GatewayRoutePublication.control_plane_status`, `GatewayRoutePublication.discrepancy_reason`, and `GatewayRoutePublication.correlation_id` from `data-model.md` in `src/contexts/gateway/domain/route-publication.ts` and `src/contexts/gateway/application/route-publication.handlers.ts`.
- [ ] T059 [US11] Gate route creation, publication, activation, updates and supported versions using current applicable evidence from US12 and T054/T056; reject undeclared, stale, mismatched, orphaned or wrong-owner routes, reconcile eligibility on contract invalidation/withdrawal, retain auditable route-to-contract evidence, and keep Gateway configuration free of business behavior in `src/contexts/gateway/application/route-lifecycle.ts`. Report incomplete operations; during control-plane outage allow only last validated available routes and reject new or changed routes (FR-072, FR-075, FR-078; SC-040, SC-042, SC-051).
- [ ] T060 [US11] Verify managed-only business ingress, module-owned inbound adapters, no direct Gateway persistence access, narrowly governed non-mutating health exceptions, application fail-closed authorization, and contract-preserving external route lifecycle in `test/architecture/gateway-boundaries.test.ts` and `test/e2e/gateway/publication.e2e.ts`. Add `test/e2e/gateway/context-propagation.e2e.ts` proving validated principal and tenant, correlation, request and trace context reach the owning inbound adapter and Application capability; reject or ignore spoofed client identity/tenant headers and verify secret redaction and cross-tenant isolation (FR-062, FR-072, FR-076–FR-077, FR-091; SC-040, SC-043–SC-044).

## Phase 8: User Story 12 - External Consumer Uses a Topology-Independent API (Priority: P1)

**Goal**: Preserve canonical capability semantics across deployment topologies and every implemented channel.

**Independent Test**: Exercise the same supported contract before and after a topology change, then demonstrate safe retries, conflicting updates, channel conformance, and fail-closed exposure gates.

- [ ] T061 [P] [US12] Add failing contract and cross-channel tests for matching and different-fingerprint concurrent retries, in-progress asynchronous protection and deployment-defined retention, concurrent stale updates, unsafe retry errors, canonical authorization, and MCP compositions where MCP exists in `test/contract/channels/canonical-semantics.test.ts` and `test/integration/channels/concurrency-and-retry.test.ts`. In `test/contract/security/input-output-safety.contract.test.ts`, verify applicable allowlists and sink-specific encoding reject or safely handle out-of-list values, header/log injection, script/markup injection, unsafe URL schemes, path traversal, overlong values, malformed Unicode and encoded bypass attempts across implemented channels without requiring absent UI (FR-077, FR-090; SC-044).
- [ ] T062 [P] [US12] Add failing channel exposure tests for missing, failed, expired, and stale mandatory evidence, material-change invalidation, revalidation, absent channels, and outage restrictions in `test/integration/channels/exposure-gates.test.ts`.
- [ ] T063 [US12] Implement application-owned command idempotency and concurrency ports for `IdempotencyRecord.tenant_id`, `IdempotencyRecord.principal_id`, `IdempotencyRecord.operation`, `IdempotencyRecord.idempotency_key`, `IdempotencyRecord.request_fingerprint`, and `IdempotencyRecord.status` from `data-model.md`, with deployment-defined retention covering retries and asynchronous completion, no expiry while in progress, and no universal duration in `src/shared/application/idempotency/idempotency.port.ts` and `src/shared/infrastructure/idempotency/idempotency.repository.ts`.
- [ ] T064 [US12] Apply contract-specific operation identity, replay/conflict outcomes, conditional writes and stale-state errors across applicable state-changing capabilities without requiring keys for naturally idempotent operations in `src/shared/application/idempotency/command-protection.ts` and `test/contract/channels/state-change.contract.test.ts`.
- [ ] T065 [US12] Implement capability/version/channel exposure evidence and revalidation using `ChannelExposureGateEvidence` in `data-model.md`; fail closed before activation for missing, failed, expired or stale applicable contract, architecture, security, tenancy, policy, governance and channel-compatibility gates, including applicable allowlist/encoding and route-to-contract evidence exercised by T061/T054, and reconcile existing exposure when invalidated in `src/contexts/governance/application/channel-exposure-gate.ts` (FR-077–FR-078, FR-090; SC-040, SC-044).
- [ ] T066 [US12] Integrate the gates with Gateway publication and each implemented MCP, CLI, GUI, SDK or automation channel; absent channels require no implementation, and MCP compositions retain canonical semantics in `src/channels/exposure/channel-activation.ts` and `test/contract/channels/channel-gates.contract.test.ts`.
- [ ] T067 [US12] Verify topology-independent API compatibility, equivalent controls across implemented channels, no provider-administration bypass, propagated context, and blocked new or changed exposure during Gateway control-plane outage in `test/e2e/channels/topology-and-governance.e2e.ts`.

## Phase 9: User Story 13 - Module Developer Applies Dependency Inversion (Priority: P1)

**Goal**: Enforce inward-owned capability ports and vendor-independent Domain and Application policies uniformly across Core and modules.

**Independent Test**: Certify compliant in-process and standalone modules with inward-owned ports and reject each forbidden concrete framework, persistence, broker, Gateway, or provider dependency.

- [ ] T068 [P] [US13] Add architecture fixtures and tests for allowed port/adapter directions and disallowed Domain SDK/framework imports, concrete Application adapters, vendor-owned ports and unmanaged routes, without requiring artificial pure-domain interfaces in `test/architecture/dependency-inversion.test.ts`.
- [ ] T069 [US13] Implement discoverable module capability declarations for `OutboundCapabilityRequirement.id`, `OutboundCapabilityRequirement.module_id`, `OutboundCapabilityRequirement.required_capability`, `OutboundCapabilityRequirement.required_provider_kind`, `OutboundCapabilityRequirement.authentication_requirement`, `OutboundCapabilityRequirement.tenant_requirement`, `OutboundCapabilityRequirement.observability_requirement`, `CapabilityPort.id`, `CapabilityPort.owner_inner_layer`, `CapabilityPort.owner_bounded_context_id`, `CapabilityPort.capability_semantics`, `CapabilityPort.operation_contract`, and `CapabilityPort.error_contract` from `data-model.md` in `src/contexts/module-catalog/domain/capability-declaration.ts`.
- [ ] T070 [US13] Extend scaffold and certification to validate inward port ownership, module-owned inbound adapters and acceptable adapter calls across Core, partner, in-process and standalone modules; reject T036 Event Bus bypass fixtures and undeclared/stale/wrong-owner routes while allowing governed event and synchronous paths in `src/contexts/governance/application/dependency-inversion-certifier.ts`, `src/contexts/governance/application/module-communication-certifier.ts`, and `templates/module/`. Retain attributable certification evidence; T054/T133 test rejection and acceptance (FR-063, FR-072, FR-082, FR-088; SC-020, SC-040, SC-045–SC-048).
- [ ] T071 [US13] Verify persistence, messaging, Gateway and provider adapters implement application-owned contracts without leaking concrete models or SDK types, including a compliant pure-domain collaborator, in `test/contract/architecture/port-adapters.contract.test.ts`.

## Phase 10: User Story 14 - Module Developer Owns and Integrates Private State (Priority: P1)

**Goal**: Preserve private authoritative ownership, owner-managed persistence, and consumer-owned projections across in-process and extracted modules.

**Independent Test**: Validate two logically isolated modules sharing physical infrastructure, exchange data only through governed contracts/events, and preserve supported contracts after an extraction simulation.

- [ ] T072 [P] [US14] Add failing tests for direct cross-module database/repository/ORM/migration access, duplicate ownership, projection misclassification, duplicate/out-of-order events, and extraction compatibility in `test/architecture/data-sovereignty.test.ts` and `test/integration/data-sovereignty/projection.test.ts`.
- [ ] T073 [US14] The platform architecture and persistence owners record a physical persistence isolation ADR before provisioning in `docs/adr/module-persistence-isolation.md`; retain ownership, tenant-isolation and least-privilege evidence, and block dependent T018/T080 provisioning until approved without mandating a separate server or cluster.
- [ ] T074 [US14] Implement `ModulePersistenceBoundary` and `DataOwnershipDeclaration` as defined in `data-model.md`, rejecting unresolved or shared authoritative ownership while identifying owner-controlled persistence, migrations, local transactions and lifecycle in `src/contexts/module-catalog/domain/data-ownership.ts` and `src/contexts/governance/application/data-ownership.validator.ts`.
- [ ] T075 [US14] Implement consumer-owned `DerivedProjection` as defined in `data-model.md` in `src/contexts/eventing/application/derived-projection.ts` and `src/contexts/eventing/application/projection-recovery.ts`: retain source contract/version, tenant and event identity and checkpoint; fail closed for absent/mismatched tenant, source-aggregate tenant or checkpoint tenant; preserve idempotent and declared ordering behavior, reject unsupported versions without corruption, and make lag and reconciliation health observable. Never use stale derived state for a decision requiring current authoritative state; use an authorized canonical synchronous capability only when its inherent immediate-result contract permits, fail closed when that required source is unavailable, and use declared degraded behavior only for operations explicitly permitting it. Rebuild/replay preserve tenant isolation and checkpoints; T179 retains test evidence (FR-101–FR-102, FR-119; SC-060, SC-069).
- [ ] T076 [US14] Extend event and persistence boundaries so publisher Outbox and consumer Inbox remain owner-controlled, cross-boundary work uses governed contracts and local transactions, and distributed transactions require an explicit ADR in `src/contexts/eventing/application/ownership-policy.ts` and `test/integration/data-sovereignty/local-transactions.test.ts`.
- [ ] T077 [US14] Verify public contracts do not leak private persistence models, projections never become undeclared authority, shared infrastructure does not permit foreign access, and supported contracts survive extraction in `test/contract/data-sovereignty/extraction.contract.test.ts`.

## Phase 11: User Story 15 - Platform Operator Certifies Module Data Boundaries (Priority: P1)

**Goal**: Certify ownership, least-privilege persistence, sensitive-data protection and module-specific lifecycle before availability.

**Independent Test**: Certify compliant shared-infrastructure modules and reject ambiguous ownership, cross-module access, unsafe credentials and unprotected sensitive persisted copies.

- [ ] T078 [P] [US15] Add failing certification and integration tests for ambiguous ownership, foreign private reads/writes or migrations, shared authoritative tables, overprivileged runtime credentials, unsafe lifecycle copies, and AI-agent prohibited-design refusal in `test/architecture/data-certification.test.ts` and `test/integration/data-sovereignty/access-boundaries.test.ts`.
- [ ] T079 [US15] Implement certification of discoverable ownership, migration, projection source, capability and lifecycle declarations in `src/contexts/governance/application/data-boundary-certifier.ts`, accepting compliant shared physical infrastructure. Require each persistence-owning module or governing deployment policy to define compatible/incompatible upgrades, owner-controlled transformations, partial failure and rollback/recovery, backup before destructive transformation, restore validation, archive/retention/deletion, uninstall, tenant isolation, privacy/classification and applicable AES-256 for primary, derived projection, Outbox/Inbox, analytics, observability, audit, dead-letter, export and restore copies; T081/T082 and T182 subsequently verify evidence (FR-105, FR-111–FR-112, FR-114; SC-062, SC-067–SC-068).
- [ ] T080 [US15] Implement per-owner runtime and separately governed migration identity enforcement and attributable tenant-aware persistence access through infrastructure adapters in `src/shared/infrastructure/persistence/module-access-policy.ts` and `test/integration/data-sovereignty/persistence-credentials.test.ts`.
- [ ] T081 [US15] The security and data owners approve an encryption/key-management approach with AES-256, classification, isolation and key-lifecycle evidence in `docs/adr/sensitive-data-protection.md` before implementing protection in `src/shared/infrastructure/security/persisted-data-protection.ts`; block dependent sensitive persistence until approved and protect primary data and applicable projections, Outbox/Inbox, backups, restores, exports, archives, analytics, observability, audit and dead-letter copies. T082/T182 verify applicable representations (FR-105, FR-112; SC-067).
- [ ] T082 [US15] Verify AES-256 and inherited classification, tenant/access, retention and deletion controls across applicable persisted representations and separately auditable migration access in `test/integration/data-sovereignty/sensitive-copies.test.ts` and `test/contract/data-sovereignty/reporting.contract.test.ts`. Cover reporting, search, analytics, observability and audit integrations: use governed contracts or explicitly classified derived products, never query private foreign persistence or become undeclared operational authority, and verify derived products are rebuildable/reconcilable where applicable (FR-105, FR-112, FR-114; SC-067–SC-068).
- [ ] T083 [US15] Add certification fixtures for AI engineering agents and automation that reject and report unresolved or prohibited ownership, persistence leakage, privileged credentials and tenant bypass in `test/architecture/agent-data-governance.test.ts` and `docs/architecture/agent-data-governance.md`.

## Phase 12: User Story 5 - Extension Developer Discovers and Installs Available Extensions (Priority: P2)

**Goal**: Submit, review, approve, publish, discover, install, upgrade, and safely remove only approved exact-digest modules.

**Independent Test**: Submit a partner artifact, verify separate digest-bound review/approval under both separation-policy modes, publish and install it, then prove dependency/lifecycle and delivery-drain rules.

- [ ] T084 [P] [US5] Add failing contract/unit tests for partner submission, digest binding, review/approval separation, catalog visibility, dependency cycles, install denial, and uninstall drain in `test/contract/module-catalog/module-lifecycle.contract.test.ts` and `test/unit/module-catalog/module-review-approval.test.ts`.
- [ ] T085 [US5] Implement `ModuleSubmission.id`, `ModuleSubmission.tenant_id`, `ModuleSubmission.submitted_by`, `ModuleSubmission.submitted_at`, and `ModuleSubmission.status` from `data-model.md` in `src/contexts/module-catalog/domain/module-submission.ts`, `src/contexts/module-catalog/infrastructure/module-submission.repository.ts`, and `src/contexts/module-catalog/infrastructure/module-artifact-store.ts`: map the allowed `pending_review`, `approved`, `rejected`, `published`, `revoked` values to persistence, initially `pending_review`; enforce the valid transition matrix approved by T164 and the active exact-digest approval prerequisite for publication, reject invalid transitions without mutation and record observable audited outcomes; use T165 for valid/invalid tests.
- [ ] T086 [US5] Implement append-only review and approval decisions bound to the same submission, module version, and immutable `artifact_digest`; record `ModuleReviewDecision.reviewer_identity`, `ModuleReviewDecision.reviewed_at`, `ModuleReviewDecision.result`, review evidence, `ModuleApprovalDecision.approver_identity`, `ModuleApprovalDecision.approved_at`, `ModuleApprovalDecision.result`, `ModuleApprovalDecision.effective_policy_version`, and approval evidence from `data-model.md` in `src/contexts/module-catalog/domain/module-approval.ts` and `src/contexts/module-catalog/application/review-approval.handlers.ts`.
- [ ] T087 [US5] Implement approved publication and catalog lookup for `ModuleDefinition.id`, `ModuleDefinition.description`, `ModuleDefinition.current_version`, `ModuleDefinition.created_at`, `ModuleDefinition.updated_at`, `ApprovedCode.module_id`, `ApprovedCode.version`, and `ApprovedCode.artifact_digest` from `data-model.md` in `src/contexts/module-catalog/application/publish-module.handler.ts` and `src/contexts/module-catalog/infrastructure/module-catalog.repository.ts`.
- [ ] T088 [US5] Implement manifest validation, declared version resolution, and acyclic module dependency resolution in `src/contexts/module-catalog/domain/module-manifest.ts` and `src/contexts/module-catalog/application/module-dependency-resolver.ts`.
- [ ] T089 [US5] Implement `ModuleInstallation.id`, `ModuleInstallation.module_id`, `ModuleInstallation.version`, `ModuleInstallation.approved_artifact_digest`, `ModuleInstallation.status`, `ModuleInstallation.installed_at`, `ModuleInstallation.updated_at`, `ModuleInstallation.failure_reason`, and optional `ModuleInstallation.standards_grace_id` with exact-digest and enforced-standard checks from `data-model.md` in `src/contexts/module-catalog/domain/module-installation.ts` and `src/contexts/module-catalog/application/install-module.handler.ts`.
- [ ] T090 [US5] Implement tenant-owned `TenantModuleEnablement.tenant_id`, `TenantModuleEnablement.module_installation_id`, `TenantModuleEnablement.status`, and `TenantModuleEnablement.version` plus timestamps from `data-model.md` while preserving shared deployments used by other tenants in `src/contexts/module-catalog/application/tenant-module-enablement.handlers.ts` and `src/contexts/module-catalog/infrastructure/tenant-module-enablement.repository.ts`.
- [ ] T091 [US5] Implement upgrade compatibility, failed-module/dependent unavailability, and lifecycle outcomes through US3 validation, US4 delivery, US7 standards and owner-controlled migration ports in `src/contexts/module-catalog/application/module-lifecycle.handlers.ts`. Distinguish stopping new assignment from retaining accepted obligations and authorized maintenance during disablement, withdrawal, suspension, uninstall, incompatible consumer versions and activation of new event-contract versions; never silently lose pending/dead-letter work or its tenant/event/correlation/trace identity. Apply T079 upgrade/backup/rollback policy and verify with T047/T182 (FR-023, FR-064, FR-112; SC-030, SC-034, SC-067).
- [ ] T092 [US5] Implement drain/pending uninstall and block unregister until every assigned delivery is processed, including dead-lettered work, through the US4 delivery-obligation port in `src/contexts/module-catalog/application/uninstall-module.handler.ts`.
- [ ] T093 [US5] Expose submission, review, approval, publication, catalog, install, upgrade, uninstall, and lifecycle-operation contracts with idempotency, ETags, audit, and tenant authorization in `src/contexts/module-catalog/presentation/module-catalog.controller.ts`; verify partner-to-install and failure/drain flows in `test/integration/module-catalog/module-lifecycle.integration.test.ts` and `test/e2e/module-catalog/module-lifecycle.e2e.ts`.

## Phase 13: User Story 6 - Configuration Manager Updates Environment-Specific Settings (Priority: P2)

**Goal**: Resolve and change configuration deterministically, preserve last-valid values, stage database URLs, and never expose secret material.

**Independent Test**: Exercise environment/file/database precedence and scope specificity, hot reload, invalid updates, secret redaction, and restart activation of a database URL candidate.

- [ ] T094 [P] [US6] Add failing unit/contract tests for precedence, scope resolution, invalid updates, hot reload, secret handling, idempotency, and restart staging in `test/unit/configuration/configuration-resolution.test.ts` and `test/contract/configuration/configuration.contract.test.ts`.
- [ ] T095 [P] [US6] Implement `ConfigurationValue.id`, `ConfigurationValue.key`, `ConfigurationValue.source`, `ConfigurationValue.scope_type`, `ConfigurationValue.tenant_id`, `ConfigurationValue.module_id`, `ConfigurationValue.environment`, `ConfigurationValue.version`, `ConfigurationValue.value`, `ConfigurationValue.secret_reference`, `ConfigurationValue.secret`, `ConfigurationValue.valid_from`, and `ConfigurationValue.updated_at` from `data-model.md` plus source/scope resolution in `src/contexts/configuration/domain/configuration-value.ts` and `src/contexts/configuration/domain/configuration-resolver.ts`.
- [ ] T096 [US6] Implement tenant-aware PostgreSQL configuration repositories and enforce tenant predicates/RLS in `src/contexts/configuration/infrastructure/prisma-configuration.repository.ts`.
- [ ] T097 [US6] Implement tenant/platform configuration list/get/update commands with authorization, delegation, idempotency, concurrency, and invalid-candidate preservation in `src/contexts/configuration/application/configuration.handlers.ts`.
- [ ] T098 [US6] Implement external secret-reference resolution and non-critical hot reload without storing recoverable secret values in `src/contexts/configuration/infrastructure/secrets/secret-reference.adapter.ts` and `src/contexts/configuration/infrastructure/reload/configuration-reloader.ts`.
- [ ] T099 [US6] Implement database URL candidate validation and staged-until-restart activation that leaves the active connection unchanged on failure in `src/contexts/configuration/infrastructure/restart/database-url-activation.ts`.
- [ ] T100 [US6] Implement tenant/platform configuration HTTP adapters and DTOs from `contracts/openapi.yaml`, including secret redaction and preconditions, in `src/contexts/configuration/presentation/configuration.controller.ts`.
- [ ] T101 [US6] Implement `ConfigurationChange.id`, `ConfigurationChange.tenant_id`, and `ConfigurationChange.module_id` and the key, scope, actor, reason, timestamp, validation-result and version history described in `data-model.md`, with non-secret before/after values and redacted secret references; verify real-adapter, concurrency, cross-channel, and restart behavior in `src/contexts/configuration/infrastructure/configuration-audit.repository.ts` and `test/integration/configuration/configuration-persistence.test.ts`.

## Phase 14: User Story 7 - Governance Officer Audits Module Compliance and Standards Evolution (Priority: P2)

**Goal**: Publish standards, assess module compliance, manage grace for already-installed modules, and enforce expired standards without disrupting the core.

**Independent Test**: Publish a version, assess/report violations, verify grace behavior for existing versus new installations, and verify expiry disables only non-compliant modules and dependents.

- [ ] T102 [P] [US7] Add failing governance unit/contract tests for publication/history, compliance statuses, grace boundaries, new-install denial, and dependent-module enforcement in `test/unit/governance/standards-and-compliance.test.ts` and `test/contract/governance/governance.contract.test.ts`.
- [ ] T103 [P] [US7] Implement `StandardsVersion.version`, `StandardsVersion.release_date`, `StandardsVersion.breaking_changes`, `StandardsVersion.migration_guide`, and `StandardsGrace.id`, `StandardsGrace.standards_version`, `StandardsGrace.started_at`, `StandardsGrace.expires_at`, and its covered pre-existing installations from `data-model.md` in `src/contexts/governance/domain/standards-version.ts` and `src/contexts/governance/domain/standards-grace.ts`.
- [ ] T104 [US7] Implement standards publication/list/get use cases with platform authorization and immutable governance history in `src/contexts/governance/application/standards.handlers.ts`; version and expose migration guidance, and reject enforcement of a breaking standard without an available migration path. Assume no exceptions; if an approved future governing policy explicitly permits them, require explicit authorization, expiry and audit without waiving constitutional security or tenant controls. T108 verifies missing guidance and rejects invalid exceptions (FR-034, FR-038–FR-039; SC-019).
- [ ] T105 [US7] Implement compliance assessment and `ComplianceReport.id`, `ComplianceReport.module_installation_id`, `ComplianceReport.standards_version`, `ComplianceReport.assessed_at`, and `ComplianceReport.violations`, plus compliance status and transition history as described in `data-model.md`, in `src/contexts/governance/domain/compliance-report.ts` and `src/contexts/governance/application/compliance-assessment.handler.ts`; automatically evaluate certification against applicable standards, preserve permitted grace, and never mark a failed migration compliant (FR-027, FR-037–FR-039; SC-019).
- [ ] T106 [US7] Implement tenant-authorized compliance report create/list/get operations, remediation guidance, and audit integration from `contracts/openapi.yaml` in `src/contexts/governance/presentation/compliance.controller.ts`.
- [ ] T107 [US7] Implement grace evaluation for pre-existing ModuleInstallation records, reject non-compliant new installs, and request governed disable transitions for expired non-compliant modules/dependents through US5 ports in `src/contexts/governance/application/standards-enforcement.handler.ts`.
- [ ] T108 [US7] Verify authorization, append-only transition history, audit and standards enforcement with PostgreSQL integration and end-to-end tests in `test/integration/governance/standards-persistence.test.ts` and `test/e2e/governance/standards-enforcement.e2e.ts`: current compliant module, older permitted version, grace expiry and automatic disablement of non-compliant modules and dependents, breaking update without a migration path, successful and failed owner-controlled migrations, and rejection of invalid, unauthorized or expired exceptions (FR-027, FR-034–FR-039; SC-019).

## Phase 15: User Story 8 - Developer Accesses Developer Portal for Documentation and Examples (Priority: P2)

**Goal**: Provide searchable documentation, API/event/module examples, marketplace information, and secure credential self-service; meet WCAG 2.2 AA before release.

**Independent Test**: Search documentation, follow tutorials and module-template links, view marketplace/install status, and create/revoke credentials within the caller's authority; evaluate complete portal flows for accessibility.

- [ ] T109 [P] [US8] Add failing portal contract/e2e and automated accessibility tests for search, references, marketplace, credentials, keyboard use, focus, reflow, forms, errors, dialogs, and navigation in `test/contract/portals/portal-contract.test.ts` and `test/accessibility/developer-portals.test.ts`.
- [ ] T110 [P] [US8] Implement API credential fields `API credential.id`, `API credential.tenant_id`, `API credential.owner_user_id`, `API credential.label`, `API credential.status`, `API credential.created_at`, `API credential.expires_at`, `API credential.last_used_at`, `API credential.revoked_at`, and one-way `API credential.secret_verifier` or external secret-manager reference from `data-model.md` in `src/contexts/identity-access/domain/api-credential.ts` and `src/contexts/identity-access/application/api-credential.handlers.ts`.
- [ ] T111 [US8] Implement credential persistence, authentication/scope intersection, ownership checks, revocation, and no-secret-recovery behavior in `src/contexts/identity-access/infrastructure/api-credential.repository.ts`.
- [ ] T112 [US8] Expose canonical credential issue/list/get/revoke APIs with one-time secret disclosure, idempotency, concurrency, audit, and redaction in `src/contexts/identity-access/presentation/api-credentials.controller.ts`.
- [ ] T113 [P] [US8] Implement authorized searchable documentation generation, Markdown overrides and context-safe rendering in `src/contexts/documentation/application/documentation-search.ts` and `src/channels/documentation-portal/documentation.page.tsx`. Include architecture, bounded contexts/module boundaries, API-first channels and canonical contracts, Event Bus, tenants, authorization, data sovereignty, provider ports, troubleshooting/failure/recovery/security, extension development, examples and migration/versioning. Extract applicable source/version information from code docstrings/JSDoc, OpenAPI, Integration Event schemas, manifests, SDK declarations, architecture-test rules and CLI help; preserve protected-document authorization and use T115/T116 for freshness, links and search evidence (FR-040–FR-044; SC-010).
- [ ] T114 [P] [US8] Implement developer portal marketplace filters, installed-module status, CLI download instructions, and credential management using canonical APIs only in `src/channels/developer-portal/marketplace.page.tsx`.
- [ ] T115 [US8] Add runnable examples, quickstart, module-development and operational troubleshooting content in `docs/developer-guide.md`; validate links, authoritative source versions and generated-content freshness in `test/contract/documentation/runnable-examples.test.ts`, failing CI through T004 for stale content while preserving the T168 example pass threshold (FR-040–FR-044; SC-010–SC-011).
- [ ] T116 [US8] Add portal end-to-end tests for search, tutorials, marketplace, credential flows, denied scopes and one-time secret presentation in `test/e2e/portals/developer-portals.e2e.ts`; verify expected sections are indexed, each maintained acceptance query returns its expected relevant results, troubleshooting queries find the correct operational guidance, links work, and unauthorized documentation remains protected. Use SC-010's existing relevance criterion and T134 latency threshold without inventing a relevance percentage (FR-040–FR-041; SC-010).
- [ ] T117 [US8] Record automated regression results and representative human WCAG 2.2 AA evaluation, including scope, pages/flows, assistive technologies, findings, and remediation, in `docs/portal-accessibility-evidence.md`; block release if criteria fail.

## Phase 16: User Story 9 - SDK Consumer Implements Standalone Extension Outside Core Repository (Priority: P3)

**Goal**: Publish a type-safe standalone SDK that consumes canonical contracts and routes event work only through governed platform capabilities.

**Independent Test**: Build an external sample consumer against the published SDK types and verify event, tenant-context, schema/version, idempotency, configuration, and observability behavior without importing broker clients or core implementation.

- [ ] T118 [US9] Add SDK type/runtime tests and external-consumer contract fixtures for valid/invalid schemas, tenant mismatch, duplicate handling, application routing, metadata propagation, and secret redaction in `packages/extension-sdk/test/sdk-contract.test.ts` and `test/contract/extension-sdk/external-consumer.contract.test.ts`.
- [ ] T119 [P] [US9] Create an independently publishable TypeScript npm workspace package with build, declarations, and package exports in `packages/extension-sdk/package.json`, `packages/extension-sdk/tsconfig.json`, and `packages/extension-sdk/src/index.ts`.
- [ ] T120 [P] [US9] Define SDK public types from the canonical OpenAPI and event schema contracts in `packages/extension-sdk/src/contracts/openapi-types.ts` and `packages/extension-sdk/src/events/domain-event.ts`, including `DomainEvent.event_id`, `DomainEvent.aggregate_id`, `DomainEvent.tenant_id`, `DomainEvent.timestamp`, `DomainEvent.event_type`, `DomainEvent.data`, `DomainEvent.metadata`, `DomainEvent.schema_version`, `DomainEvent.source_module_id`, and `DomainEvent.correlation_id` from `data-model.md`.
- [ ] T121 [US9] Implement governed event publish/subscribe client adapters with tenant, correlation, and trace propagation and no RabbitMQ/Kafka client exposure in `packages/extension-sdk/src/events/event-client.ts`.
- [ ] T122 [US9] Implement compile-time/runtime event and version validation, including `EventContract.event_type`, `EventContract.schema_version`, `EventSubscription.status`, and tenant assignment/filter rules from `data-model.md`, in `packages/extension-sdk/src/validation/event-contract.validator.ts`.
- [ ] T123 [US9] Implement idempotent consumer and authoritative application-capability routing helpers using the `EventInbox/ProcessedEvent.subscription_id`, `EventInbox/ProcessedEvent.tenant_id`, and `EventInbox/ProcessedEvent.event_id` unique identity from `data-model.md` in `packages/extension-sdk/src/consumers/idempotent-consumer.ts`.
- [ ] T124 [US9] Implement configuration, secret redaction, structured logging, tracing, metrics, and telemetry helpers using `ConfigurationValue.source`, `ConfigurationValue.scope_type`, `ConfigurationValue.secret_reference`, and `ConfigurationChange` redaction rules from `data-model.md` in `packages/extension-sdk/src/configuration/configuration-client.ts` and `packages/extension-sdk/src/observability/telemetry.ts`.

## Phase 17: User Story 10 - System Administrator Monitors Platform Health and Module Telemetry (Priority: P3)

**Goal**: Expose actionable health, metrics, traces, and module/event delivery telemetry through external observability tools without leaking secrets or tenant data.

**Independent Test**: Inspect platform metrics and a slow-request trace, identify an affected module, and observe event delivery attempts/outcomes while verifying tenant-safe redaction.

- [ ] T125 [P] [US10] Add failing contract/integration tests for health, readiness, telemetry ingestion, trace correlation, event attributes, alerts, and redaction in `test/contract/observability/observability.contract.test.ts` and `test/integration/observability/telemetry-export.test.ts`.
- [ ] T126 [US10] Implement liveness/readiness application capabilities and HTTP endpoints that report dependency-safe status for database, broker, and module health in `src/shared/application/health/health.handlers.ts` and `src/channels/api/health.controller.ts`.
- [ ] T127 [P] [US10] Export CPU, memory, database connection, request-latency, and module telemetry metrics with bounded non-sensitive labels in `src/shared/observability/metrics/metrics-registry.ts` and `src/shared/infrastructure/metrics/prometheus-exporter.ts`.
- [ ] T128 [US10] Instrument request and synchronous-module spans plus event publication/delivery/retry/dead-letter processing in `src/shared/observability/tracing/module-span.instrumentation.ts` and `src/contexts/eventing/infrastructure/telemetry.ts`, recording applicable `EventDelivery.attempt_count`, `EventDelivery.next_attempt_at`, `EventDelivery.last_error`, `EventDelivery.assigned_at`, and `EventDelivery.processed_at` from `data-model.md`. Define and enforce the governed operational attribute profile in `src/shared/observability/telemetry-attribute-profile.ts` without trusting caller-supplied identity: propagate trace ID, span ID, correlation ID, request ID, operation ID, tenant ID, user or service principal ID, session ID, module ID, capability ID, route ID, canonical contract and version, event ID, event type and version, source module, consumer/subscriber identity, provider identity, result/status, error category and latency/duration where applicable, authorized and classification permits. Scrub sensitive payloads and credentials and bound metric-label cardinality; T060/T130 verify Gateway and async continuity and tenant-safe queries (FR-062, FR-091, FR-118; SC-030, SC-043, SC-070).
- [ ] T129 [P] [US10] Implement external metric/trace/log export and alerting adapters behind ports with timeout/retry/circuit-breaker behavior and no secret or cross-tenant attributes in `src/shared/infrastructure/observability/export/otel-export.adapter.ts` and `src/shared/infrastructure/observability/alert/alert.adapter.ts`.
- [ ] T130 [US10] Verify health, external metric visibility, slow-request traces, module degradation alerts, applicable T128 telemetry dimensions, event attempt/retry/dead-letter correlation and asynchronous propagation in `test/e2e/observability/observability.e2e.ts`; prove credentials/secrets are absent, metric cardinality is bounded, and cross-tenant telemetry queries cannot leak data. Use T060 for validated Gateway principal/tenant propagation and spoofed-header rejection (FR-062, FR-091, FR-118; SC-030, SC-043, SC-070).

## Final Phase: Polish and Cross-Cutting Concerns

**Purpose**: Verify the assembled foundation against the full specification and release gates.

- [ ] T131 [P] Add cross-channel conformance tests for implemented REST, MCP, CLI, portals, SDK, and automation channels, proving canonical authorization, tenant scope, validation, idempotency, audit, errors, and tracing without requiring absent channels in `test/contract/channel-conformance.test.ts`.
- [ ] T132 Run OpenAPI 3.1 and JSON Schema 2020-12 parsing/linting, request/response fixtures, and supported-version compatibility checks in `scripts/validate-contracts.ps1` and `test/contract/contract-compatibility.test.ts`.
- [ ] T133 Add architecture certification tests in `test/architecture/module-certification.test.ts` for module contracts, forbidden cross-module dependencies, broker leakage, cyclic synchronous dependencies and T036 Event Bus bypass cases; verify T070 certification rejects unregistered exchanges/queues, undeclared events, webhook/job substitutes and registry/context/schema/Outbox/idempotency bypasses while accepting local Domain Events, governed Event Bus publication and only justified synchronous interactions (FR-063, FR-066, FR-088; SC-020–SC-021, SC-028).
- [ ] T134 Benchmark SC-001 tenant provisioning <10s, SC-002 login-to-API <500ms, SC-003 scaffolding <5s, SC-004 durable event acceptance p95 <100ms local and <500ms externally deployed, SC-005 startup with 10+ modules <30s, SC-009 checks for 50+ modules <10s, SC-010 every maintained search acceptance query <1s, and SC-017 scaffold-to-first accepted event <2h; measure applicable deployment-defined throughput, module registration/activation and Gateway objectives without inventing numerical thresholds, recording workload, environment, measured results, PASS/FAIL and retained evidence in `test/performance/platform-core/platform-core.benchmark.ts` and `docs/performance-results.md` after implementation and TLS validation T143.
- [ ] T135 After T147 and T182, run a deployment-specific recovery exercise for database, outbox/broker state, access controls, tenant isolation, event obligations and applicable upgrade/restore policies; retain measured outcomes against that deployment's own targets in `test/integration/recovery/recovery-exercise.test.ts` and `docs/operations/recovery-evidence.md` (FR-112; SC-036, SC-067).
- [ ] T136 Complete and record automated plus representative human WCAG 2.2 AA evaluation for documentation/developer portal release candidates in `test/accessibility/wcag-release-evaluation.test.ts` and `docs/portal-accessibility-evidence.md`.
- [ ] T137 Verify immutable seven-year audit retention, 30-day-default event archive behavior, secret redaction, and preservation of pending/in-flight/dead-letter delivery obligations in `test/integration/platform-core/retention-and-audit.test.ts`.
- [ ] T138 Update implementation guidance, architecture documentation, and runnable validation scenarios to match delivered contracts and actual commands in `docs/architecture/platform-core.md` and `specs/001-platform-core-foundation/quickstart.md`.

## Incremental Tasks by Original Phase

These tasks retain sequential IDs after T138; their phase association and explicit
prerequisites, not their position after the original tasks, govern execution.
Do not expose a capability until T139–T143 and its applicable T065/T066 gates pass.

### Phase 2 — Shared security and deployment decisions

- [ ] T139 Define transport-security configuration and validation for TLS 1.2+ with trusted CAs, hostname verification, externally managed certificate/key references, and redacted failure telemetry in `src/shared/infrastructure/security/transport-security.ts`; reject invalid, expired, untrusted or mismatched certificates and protocols below 1.2, permit plaintext only in an explicitly governed local-test context, and verify policy unit tests in `test/unit/security/transport-security.test.ts` (FR-077, FR-091; SC-043, SC-044; Constitution Security).
- [ ] T140 After T055 and T139, configure HTTPS for the selected Gateway adapter and Platform Core inbound HTTP using managed certificate/key references in `src/contexts/gateway/infrastructure/gateway-tls.adapter.ts` and `src/channels/api/tls-options.ts`; retain the T143 positive/negative evidence and never treat TLS as identity, tenant or application authorization (FR-071, FR-076–FR-078; SC-039, SC-043–SC-044).
- [ ] T141 After T139, configure verified TLS 1.2+ for PostgreSQL, Redis and RabbitMQ connections in `src/shared/infrastructure/persistence/postgres-tls.ts`, `src/shared/infrastructure/cache/redis-tls.ts`, and `src/contexts/eventing/infrastructure/rabbitmq/rabbitmq-tls.ts`; honor CA, hostname and managed secret policy and prove each adapter with T143 (FR-012, FR-084–FR-085, FR-105; SC-025, SC-043, SC-063).
- [ ] T142 After T139, configure verified TLS 1.2+ for applicable module/provider outbound HTTP through an infrastructure adapter in `src/shared/infrastructure/http/secure-http.adapter.ts`; preserve application-owned ports and verify certificate, hostname, protocol and redacted failure behavior with T143 (FR-086, FR-091; SC-043, SC-048).
- [ ] T143 After T140–T142 and before external integration or activation, test each applicable transport boundary in `test/integration/security/transport-tls.integration.test.ts`: TLS 1.2+ succeeds; older TLS, invalid/expired/untrusted/mismatched certificates and non-governed plaintext fail; certificate material is not logged; missing tenant or authorization remains denied despite valid TLS (FR-077, FR-090–FR-091; SC-043–SC-044).
- [ ] T144 The identity and tenant owners document slug and email normalization/storage comparison and atomic uniqueness enforcement plus suspended-tenant background authorization in `docs/adr/tenant-identity-and-background-authorization.md`; retain collision, concurrency and authorized-worker test evidence, stop on unresolved policy, and block dependent T018/T026/T049 implementation (FR-003–FR-006, FR-061; SC-001–SC-002, SC-006, SC-025).
- [ ] T145 The identity/security owners decide session-revocation persistence, consistency, outage and recovery behavior in `docs/adr/session-revocation.md`; retain multi-instance immediate-revocation and fail-closed evidence, stop if current status cannot be established, and block dependent T025–T027 implementation (FR-008–FR-010; SC-002, SC-007).
- [ ] T146 The platform/security and deployment owners decide idempotency storage, concurrency control and deployment retention in `docs/adr/command-protection.md`; retain retry, asynchronous completion, concurrent conflict and recovery evidence, prohibit expiry before completion and stop on an insufficient policy, blocking dependent T063/T064 (FR-065, FR-090; SC-044).
- [ ] T147 The deployment owner records workload, active-tenant capacity, concurrency, throughput, service objectives, a versioned retry/dead-letter policy, and deployment-specific recovery objectives with test inputs and evidence in `docs/operations/deployment-profile.md`; block T044/T047 until delivery policy approval, stop release when objectives or evidence are missing or failing, and block T134/T135/T166 release claims without imposing universal numbers (FR-014, FR-091; SC-014, SC-030, SC-036).

### Phase 5 — User Story 3 standards refresh

- [ ] T148 [US3] Implement authenticated Application capabilities for current scaffold standards and versioned template retrieval through `src/contexts/module-catalog/application/scaffold-standards.handlers.ts`, preserving the existing `contracts/openapi.yaml` operations and verifying response/error contracts in `test/contract/module-catalog/scaffold-standards.contract.test.ts` before T155/T156 (FR-028, FR-034; SC-003, SC-019).

### Phase 6 — User Story 4 Event API

- [ ] T149 [US4] After T040/T043/T046/T047, provide application query/command ports for registered event-type discovery, tenant event listing/publication, subscription create/list/get/pause/resume/drain, failure listing and authorized replay in `src/contexts/eventing/application/event-api.handlers.ts`; validate tenant-scoped filters and obligations and verify use cases in `test/unit/eventing/event-api.test.ts` (FR-012–FR-017, FR-061, FR-064, FR-067–FR-069; SC-022, SC-025–SC-026, SC-032, SC-034).
- [ ] T150 [US4] After T149, implement only the event-type, tenant-event, subscription and failure/replay HTTP operations defined in `contracts/openapi.yaml` in `src/contexts/eventing/presentation/event-api.controller.ts`; map request/response/problem DTOs, audit, correlation and trace via Application capabilities only, never RabbitMQ or repositories, and pass T151 before exposure (FR-012, FR-061, FR-065, FR-090; SC-025, SC-032–SC-033, SC-044).
- [ ] T151 [US4] After T150 and T143, validate OpenAPI requests/responses, roles, tenant and delegated scope, filter rejection, safe replay, no historical backfill, pause/drain obligations, idempotency, errors and trace/audit propagation in `test/contract/eventing/event-api.contract.test.ts` and `test/integration/eventing/event-api-authorization.test.ts` (FR-014–FR-017, FR-061, FR-064–FR-069, FR-090; SC-023, SC-025–SC-026, SC-032, SC-034, SC-044).

### Phase 3/4 — User Stories 1 and 2 audit-query capability

- [ ] T152 [US2] After T009 and T145, define an Application-owned audit query port and authorized tenant/platform query handlers with pagination and only contract-defined actor/action/time/tenant filters over `AuditRecord.tenant_id`, `AuditRecord.actor_id`, `AuditRecord.action`, and `AuditRecord.occurred_at` from `data-model.md` in `src/contexts/audit/application/ports/audit-query.port.ts` and `src/contexts/audit/application/audit-query.handlers.ts`; implement the port in `src/contexts/audit/infrastructure/audit-query.repository.ts` and verify scoped query behavior in `test/unit/audit/audit-query.test.ts` (FR-007, FR-011, FR-033; SC-006–SC-007, SC-015).
- [ ] T153 [US2] After T152, implement the canonical tenant and Platform Operator audit-query HTTP operations from `contracts/openapi.yaml` using only Application capabilities and secure DTOs in `src/contexts/audit/presentation/audit-query.controller.ts`; enforce pagination, contract-defined filters and date boundaries, exclude secrets and unauthorized tenant evidence, and pass T154 before exposure (FR-007, FR-011, FR-077, FR-090; SC-006–SC-007, SC-015, SC-044).
- [ ] T154 [US2] After T153 and T143, validate both audit-query OpenAPI operations, allowed roles, platform scope, tenant/delegated isolation, pagination, contract-defined filters, date boundaries and redaction in `test/contract/audit/audit-query.contract.test.ts` and `test/integration/audit/audit-query-isolation.test.ts` (FR-007, FR-011, FR-033, FR-090; SC-006–SC-007, SC-015, SC-044).

### Phase 5/14 — User Stories 3 and 7 standards refresh

- [ ] T155 [US3] After T148, T103–T107 and the approved T183 canonical contract, implement the authorized Application capability that refreshes existing module templates from governed platform standards in `src/contexts/module-catalog/application/update-standards.handler.ts`: validate transitions, make side-effect-free dry-run/impact output available identifying affected modules, dependent modules and contracts, preserve applicable grace, expose versioned migration guidance before breaking enforcement, and audit results. Verify impact, refresh, successful/failed migrations, invalid transitions and expiry consequences in `test/integration/module-catalog/update-standards.test.ts`; never treat failure as compliance (FR-027–FR-028, FR-034–FR-039; SC-019).
- [ ] T156 [US3] After T155 and T183, implement `sdd-cli module:update-standards` in `src/channels/cli/module-update-standards.command.ts` as an inbound adapter to the governed capability and approved versioned canonical contracts, not an independent authorization or business path; verify dry-run/impact output, authorization, refresh results, audit and invalid/grace-expiry behavior in `test/contract/module-catalog/update-standards-cli.contract.test.ts` before channel activation (FR-027–FR-028, FR-038–FR-039, FR-065; SC-019, SC-044).

### Phase 13 — User Story 6 secret rotation

- [ ] T157 [US6] After T098 and T144, define Application-owned secret-rotation policy/ports and handlers in `src/contexts/configuration/application/ports/secret-rotation.port.ts` and `src/contexts/configuration/application/secret-rotation.handlers.ts`; govern version creation/ingestion, activation, policy-defined overlap, consumer refresh, retirement, rollback/failure, tenant/module isolation and redacted audit without choosing a vendor; verify policy decisions in `test/unit/configuration/secret-rotation.test.ts` (FR-030–FR-033, FR-086; SC-008, SC-015, SC-048).
- [ ] T158 [US6] After T157, implement a vendor-neutral infrastructure adapter with tenant/module-keyed cache invalidation and consumer refresh in `src/contexts/configuration/infrastructure/secrets/secret-rotation.adapter.ts`; apply policy-governed rollback or fail closed without silently retaining revoked material, and never emit secret values in logs, events, errors or audit, as verified by T159 (FR-031–FR-033, FR-086; SC-008, SC-015, SC-048).
- [ ] T159 [US6] After T158, exercise fake/local secret-provider version creation/ingestion, activation, overlap when configured, retirement, refresh, cache invalidation, rollback, failure, isolation and redaction in `test/integration/configuration/secret-rotation.integration.test.ts` (FR-030–FR-033; SC-008, SC-015).

### Phase 16 — User Story 9 SDK contracts and templates

- [ ] T160 [US9] After T031/T069/T074/T075 and T148, implement SDK scaffold helpers for canonical API, Integration Event and synchronous contract declarations, application/provider/persistence ports, Gateway publication metadata, projection, Outbox/Inbox, lifecycle, certification and architecture-test templates in `packages/extension-sdk/src/templates/module-template.helpers.ts`; verify generated artifacts and contract references in `packages/extension-sdk/test/module-template.helpers.test.ts` (FR-026–FR-028, FR-051, FR-087–FR-089, FR-108–FR-110; SC-003, SC-026, SC-048, SC-066).
- [ ] T161 [US9] After T056–T059/T065/T069 and T119, expose platform-owned SDK abstractions for canonical API declaration and publication requests/status, identity/tenant/correlation/trace context, application and provider capability ports, lifecycle, certification and applicable Gateway gate evidence in `packages/extension-sdk/src/capabilities/platform-capabilities.ts`; verify canonical semantics and no provider-administration bypass in `packages/extension-sdk/test/platform-capabilities.contract.test.ts` (FR-065, FR-079, FR-089–FR-090; SC-044, SC-048).
- [ ] T162 [US9] After T042/T048/T074–T076 and T119, expose tenant-aware SDK persistence-port integration, owner-local Outbox/Inbox integration, projection ingestion and source/checkpoint metadata, lifecycle and ownership-validation hooks in `packages/extension-sdk/src/persistence/module-data-boundaries.ts`; verify owner-local processing and no cross-module persistence shortcuts in `packages/extension-sdk/test/module-data-boundaries.contract.test.ts` (FR-060, FR-084, FR-104–FR-105, FR-109; SC-033, SC-048, SC-060–SC-061, SC-066).
- [ ] T163 [US9] After T160–T162, add compile-time, runtime, contract and architecture fixtures in `packages/extension-sdk/test/sdk-boundaries.contract.test.ts` and `test/architecture/extension-sdk-boundaries.test.ts` rejecting Kong, RabbitMQ, Prisma, PostgreSQL, provider SDK and foreign persistence models from authoritative SDK contracts while validating event/context and gate semantics (FR-050, FR-065, FR-088–FR-090, FR-109; SC-028, SC-044–SC-048, SC-066).

### Phase 12 — User Story 5 submission lifecycle

- [ ] T164 [US5] After T084 and before T085/T086/T093, confirm and implement the already-approved `ModuleSubmission.status` matrix from `data-model.md`, `spec.md` FR-019 and `contracts/openapi.yaml` in `src/contexts/module-catalog/domain/submission-status.ts`, `src/contexts/module-catalog/application/submission-transition.policy.ts`, and `src/contexts/module-catalog/infrastructure/submission-status.mapper.ts`, with the revocation HTTP adapter invoking the Application capability in `src/contexts/module-catalog/presentation/module-catalog.controller.ts`. Persist/map exactly `pending_review`, `approved`, `rejected`, `published`, and `revoked`; an authorized partner creates a new submission in `pending_review`. Only an authorized Platform Operator may transition `pending_review` to `approved` (positive review and separate positive approval of the immutable digest under the separation policy), `rejected` (negative review or approval), or `revoked`; `approved` to `published` (validated manifest and active exact-digest positive review and approval) or `revoked`; and `published` to `revoked`. `rejected` and `revoked` are terminal; rejected submissions cannot become active; deny and audit every other or unauthorized change without mutation. Resubmission after rejection or revocation and any changed approved artifact require a new `pending_review` submission with fresh review and approval, never inherited decisions. Positive review leaves status unchanged but advances the submission version; every accepted review or transition advances that version. Require the current submission strong ETag in `If-Match` and an `Idempotency-Key` for review, approval, publication, and revocation: missing precondition yields 428, stale yields 412, invalid transition yields 409 `lifecycle_conflict`, and differing-request key reuse yields 409 `idempotency_key_reused`; after reauthentication and reauthorization, resolve an exact retry with its original request/key/ETag before stale-precondition evaluation, returning the recorded outcome without another transition. The PlatformJWT-only revocation contract requires a matching `artifactDigest` and nonempty `reason`, and returns the updated submission and ETag; do not activate the route before T065/T066 and applicable pre-exposure gates pass. Record immutable, attributable, secret-free creation and transition audit evidence with submission and tenant IDs, actor, time, previous/new status (no previous status on creation), digest, reason, decision or supporting-evidence reference, correlation context, and applicable policy version. Keep submission status distinct from certification, installation/lifecycle, publication eligibility/status, and channel exposure: approval does not bypass certification, certification does not bypass mandatory applicable exposure gates, and publication does not install, activate, or expose; revocation invalidates applicable approval/availability eligibility and triggers governed exposure/lifecycle reconciliation without discarding pending delivery obligations. Verify the complete matrix, persistence mapping, authorization, versioning, retry/error behavior, audit and state separation in `test/unit/module-catalog/submission-status.test.ts` and `test/contract/module-catalog/submission-revocation.contract.test.ts` using Application-port test doubles; T165 verifies real persistence and transitions after T085/T086 (FR-019, FR-023, FR-033, FR-090; SC-015, SC-018, SC-037, SC-044).
- [ ] T165 [US5] After T164/T085/T086, verify initial `pending_review`, every approved transition, invalid-transition rejection without mutation, immutable digest binding, persisted status and auditable observable outcomes in `test/integration/module-catalog/submission-transitions.test.ts` using `ModuleSubmission.status` from `data-model.md` (FR-019, FR-023; SC-015, SC-018, SC-037).

### Phase 17 and release evidence

- [ ] T166 [US10] After T143–T147 and relevant implementation, scale beyond one application instance and add/remove instances without code changes in `test/performance/platform-core/horizontal-scaling.test.ts`; verify stateless requests, shared session revocation, cross-instance idempotency, event-consumer/projection coordination, cache behavior, Gateway routing and tenant isolation, then record inputs, measurements and PASS/FAIL against the deployment profile in `docs/performance-results.md` (FR-002, FR-009, FR-014, FR-065, FR-078, FR-102; SC-006, SC-014, SC-044, SC-060).

### Phase 16 — User Story 9 telemetry

- [ ] T167 [US9] After T124/T161, implement automatic module logging, tracing and metrics instrumentation without manual module instrumentation in `packages/extension-sdk/src/observability/auto-instrumentation.ts`; prove a scaffolded module emits correlated telemetry without custom instrumentation in `packages/extension-sdk/test/automatic-telemetry.test.ts` (FR-050, FR-062, FR-091; SC-016, SC-030).

### Phase 15 — User Story 8 documentation evidence

- [ ] T168 [US8] After T115, measure all published runnable documentation examples in `test/contract/documentation/runnable-examples.test.ts` and record the numerator, denominator and PASS/FAIL for the required >=95% in `docs/performance-results.md` (FR-041, FR-044; SC-011).

### Phase 5 — User Story 3 ownership declarations

- [ ] T169 [US3] After T031/T070/T074 and T160, extend module manifest/scaffold ownership declarations in `templates/module/module.sdd.json.hbs` and `src/contexts/module-catalog/domain/module-manifest.ts` for applicable owner, persistence/migration capability, projection source, Outbox/Inbox, lifecycle/retention and extraction-readiness metadata; prove absence of secrets and foreign persistence dependencies in `test/contract/module-catalog/data-ownership-manifest.contract.test.ts` (FR-018, FR-087, FR-108, FR-110; SC-052, SC-065–SC-066).

### Phase 11 — User Story 15 agent governance

- [ ] T170 [US15] After T074/T079/T083, define agent/automation governance instructions in `.github/instructions/data-sovereignty.instructions.md` and verify applicable engineering-tool entry points refuse unresolved ownership, unauthorized cross-module access/mutation/migration, private-model leakage, shared privileged credentials, tenant bypass, undeclared projection/analytical authority and physical co-location used to justify coupling; report the missing contract or ADR decision in `test/architecture/agent-data-governance.test.ts` (FR-096, FR-115–FR-116, FR-120; SC-053, SC-065, SC-072).

### Phase 4 — User Story 2 session policy

- [ ] T171 [US2] After T025/T026/T145, enforce 15-minute JWT access expiry, seven-day refresh expiry and httpOnly refresh cookies, explicit valid tenant resolution before account lookup, and audit of login, logout, refresh and failed attempts in `src/contexts/identity-access/application/session.handlers.ts` and `src/contexts/identity-access/presentation/auth.controller.ts`; verify expiry boundaries, missing/invalid tenant denial, redacted audit and independent sessions in `test/integration/identity-access/session-policy.test.ts` (FR-008–FR-011; SC-002, SC-007, SC-015).

### Phase 13 — User Story 6 configuration validation

- [ ] T172 [US6] After T095/T097, validate configuration candidates against their applicable schema before application, preserving the previous active value on rejection, in `src/contexts/configuration/application/configuration-schema.validator.ts`; verify valid, malformed and incompatible candidates in `test/unit/configuration/configuration-schema.test.ts` (FR-031–FR-032; SC-008).

### Phase 5 — User Story 3 scaffold validation

- [ ] T173 [US3] After T031/T033/T034, add the query-interface scaffold template and require a declared platform standards version in the manifest, then validate naming conventions with the existing governance checks in `templates/module/query-interface.ts.hbs`, `templates/module/module.sdd.json.hbs` and `src/contexts/governance/application/module-naming.validator.ts`; verify missing/invalid versions, naming violations and generated query interfaces in `test/contract/module-catalog/scaffold-governance.contract.test.ts` (FR-026–FR-027, FR-035–FR-036; SC-003, SC-009).

### Phase 15 — User Story 8 module references

- [ ] T174 [US8] After T040/T113, expose event-registry contract documentation with source, schema version and compatibility and render module query-interface documentation in `src/contexts/documentation/application/module-reference.ts` and `src/channels/documentation-portal/module-reference.page.tsx`; verify registry-to-portal consistency and versioned query references in `test/contract/documentation/module-reference.contract.test.ts` (FR-016, FR-041–FR-042; SC-026).

### Phase 5 — User Story 3 interaction governance

- [ ] T175 [US3] After T034/T037 and before certification, enforce and document the communication decision in `src/contexts/governance/application/interaction-semantics.validator.ts`: accept synchronous contracts only for an inherent immediate-result need and prefer governed asynchronous events for independently handled occurrences; verify accepted and rejected examples in `test/architecture/interaction-semantics.test.ts` (FR-055, FR-057, FR-066; SC-020, SC-027).

### Phase 12 — User Story 5 partner approval

- [ ] T176 [US5] After T086/T093/T164, enforce deployment-configured reviewer/approver separation in `src/contexts/module-catalog/application/review-approval.handlers.ts`, rejecting same-identity approval when required and retaining both attributable identities; verify in `test/e2e/module-catalog/partner-approval.e2e.ts` that an external partner without core-repository access can submit and reach operator-reviewed publication (FR-019; SC-018, SC-037).

### Phase 16 — User Story 9 type-safety evidence

- [ ] T177 [US9] After T118/T122/T163, validate compile-time rejection and caught runtime validation failures for representative type violations in `packages/extension-sdk/test/type-safety.test.ts`, proving zero uncaught errors from type violations under the supported SDK boundaries (FR-049, FR-052; SC-012).

### Phase 7 — User Story 11 non-public modules

- [ ] T178 [US11] After T034/T060/T070, certify a valid module with no externally consumable synchronous capability without requiring an artificial public API and reject unmanaged external business routes in `test/contract/gateway/non-public-module-certification.test.ts` (FR-074–FR-075, FR-088; SC-041).

### Phase 10 — User Story 14 projection evidence

- [ ] T179 [US14] After T075/T080/T128, verify source contract/version, event identity and checkpoint persistence in `test/integration/data-sovereignty/projection-evidence.test.ts`: missing required tenant, tenant mismatch, event/source-aggregate mismatch and another tenant's checkpoint all fail closed; duplicate delivery is idempotent, out-of-order events follow declared policy, and unsupported versions do not corrupt state. Prove stale projections cannot authorize a current-state decision, synchronous authoritative fallback occurs only when permitted, unavailable authoritative sources fail closed for current-state decisions and degraded behavior occurs only where explicitly permitted, lag and reconciliation health are observable, and rebuild/replay preserve tenant isolation and checkpoints. Retain missing-tenant and stale-state results and module/tenant/migration-attributable telemetry evidence in `docs/operations/projection-evidence.md` (FR-101–FR-102, FR-118–FR-119; SC-057, SC-060, SC-069–SC-070).

### Phase 11 — User Story 15 ownership evidence

- [ ] T180 [US15] After T074/T079/T169, certify fixtures proving every state-owning module identifies exactly one persistence/migration owner and classifies each representation, rejecting unresolved/shared authority and forbidden private access while accepting enforceably isolated shared infrastructure in `test/architecture/ownership-certification-evidence.test.ts`; verify scaffold/SDK ownership declarations remain discoverable (FR-092, FR-096–FR-098, FR-108–FR-110, FR-115; SC-052–SC-053, SC-058, SC-065–SC-066).

### Phase 10 — User Story 14 contract evolution evidence

- [ ] T181 [US14] After T075/T077/T175, verify authoritative cross-module reads and mutations use the owner's canonical capability, independent reactions use versioned events, and private schema evolution does not silently alter public API/event contracts or require consumers to import migrations in `test/contract/data-sovereignty/private-evolution.contract.test.ts` (FR-093–FR-095, FR-111, FR-117; SC-056, SC-059, SC-064).

### Phase 11 — User Story 15 upgrade and restore evidence

- [ ] T182 [US15] After T073/T075/T079/T081/T091/T147 and the applicable owner-controlled migration adapters, exercise successful and failed/partial migration, rollback, module extraction, restore with projection lag, retained versus deleted uninstall data, and cross-tenant restore rejection in `test/integration/data-sovereignty/module-upgrade-recovery.test.ts`; verify policy-declared backup before destructive transformation, restore validation, classification/access/tenant controls and reconciled derived copies, and retain results in `docs/operations/module-upgrade-evidence.md` before T135 release recovery evidence (FR-112, FR-114; SC-067–SC-068).

### Phase 14 — User Story 7 standards impact contract

- [ ] T183 [US7] Before T155/T156, obtain platform/governance owner approval for a side-effect-free standards-update impact capability, including candidate/version semantics, affected modules, dependent modules and contracts, authorization and errors, in `docs/adr/standards-impact-contract.md`; establish its versioned canonical API contract in `specs/001-platform-core-foundation/contracts/openapi.yaml` and validate the schema and request/response fixtures independently of the future handler in `test/contract/governance/standards-impact.contract.test.ts`. The existing standards and compliance-report operations do not define a candidate preview: do not infer one or activate a new channel before the approved contract and applicable gates exist; stop if approval is unavailable (FR-027, FR-034–FR-039, FR-090; SC-019, SC-044).

## Semantic Requirements and Evidence Map

Mappings describe planned task coverage, not completed implementation or test
results. A decision-gated mapping is not permission to implement before approval.
Task IDs identify the responsible outcome or validation, not mere keyword matches.

| Requirement | Implementing or governing task outcome |
|---|---|
| FR-001 | T015 provisioning authority; T025 bootstrap |
| FR-002 | T017 tenant context; T020–T022 explicit grants |
| FR-003 | T016/T018 slug ownership; T144 uniqueness decision |
| FR-004 | T019 suspension/reactivation; T144 background authorization |
| FR-005 | T017–T019 scoped context and tenant operations |
| FR-006 | T023–T029 tenant-owned users and identity |
| FR-007 | T025/T027 tenant RBAC and platform-role denial |
| FR-008 | T025/T026 sessions; T171 token expiry and cookies |
| FR-009 | T026/T028 immediate session revocation and failure handling |
| FR-010 | T025/T171 tenant-qualified login and invalid-tenant denial |
| FR-011 | T025/T171 authentication-event audit |
| FR-012 | T043–T045 governed Event Bus and durable dispatch |
| FR-013 | T040 canonical envelope |
| FR-014 | T044/T047 delivery; T147 versioned retry/dead-letter policy |
| FR-015 | T046/T049 tenant, event and aggregate filters |
| FR-016 | T040/T174 registry contracts and documentation |
| FR-017 | T040/T053 version/compatibility validation |
| FR-018 | T031/T034 declarations; T169 ownership metadata |
| FR-019 | T164/T085–T087/T165/T176 submission transitions, artifact review and approval |
| FR-020 | T087/T089/T090 catalog and installation status |
| FR-021 | T035/T088 dependency graph and cycles |
| FR-022 | T036/T072/T077 module boundaries and extraction |
| FR-023 | T164/T165 submission-state separation and revocation; T091/T092 lifecycle and delivery drain |
| FR-024 | T091/T093 failure isolation and dependent unavailability |
| FR-025 | T032 scaffold command |
| FR-026 | T031/T033/T173 generated manifest and templates |
| FR-027 | T033/T034/T038/T070/T105/T107/T108/T148/T155/T156/T173/T183 current scaffold standards, automatic certification, migration, impact and grace evidence |
| FR-028 | T148/T155/T156/T183 governed standards-refresh contract, capability and CLI |
| FR-029 | T095 source precedence |
| FR-030 | T095/T097 scoped configuration |
| FR-031 | T172 schema validation before activation |
| FR-032 | T098/T099 reload and staged infrastructure activation |
| FR-033 | T101/T164 immutable audit; T157–T159 secret rotation |
| FR-034 | T103/T104/T148/T155/T183 versioned standards, migration guidance, publication and governed impact contract |
| FR-035 | T173 required manifest standards version |
| FR-036 | T034/T036/T105/T173 contract, boundary and naming checks |
| FR-037 | T105/T106 compliance assessment and reporting |
| FR-038 | T104/T105 standards and compliance history |
| FR-039 | T104/T107/T108/T155/T156/T183 migration, impact, grace and dependent disablement |
| FR-040 | T113/T115/T116/T117/T134 architecture/troubleshooting content, searchable results and accessibility |
| FR-041 | T004/T113/T115/T116/T168/T174 source-derived documentation, freshness, references and example validation |
| FR-042 | T113/T174 module, event and query documentation |
| FR-043 | T104/T113 standards history |
| FR-044 | T115 quickstart, tutorial and runnable examples |
| FR-045 | T110–T112/T114 credential self-service |
| FR-046 | T114 marketplace filters |
| FR-047 | T114 installation/version status |
| FR-048 | T114 CLI download instructions |
| FR-049 | T002/T119/T120/T177 strict TypeScript, npm SDK and typings |
| FR-050 | T121–T124 SDK event, context and telemetry |
| FR-051 | T160 SDK template helpers |
| FR-052 | T002/T122/T177 compiler and SDK schema/version validation |
| FR-053 | T121/T123 authoritative tenant propagation |
| FR-054 | T118/T119 standalone external consumer |
| FR-055 | T036/T070/T133/T175 enforced interaction decision |
| FR-056 | T036/T041/T133 explicit local-domain-to-integration event mapping |
| FR-057 | T034/T037 governed synchronous contracts |
| FR-058 | T037 policy-preserving in-process invocation |
| FR-059 | T042/T045 atomic state and Outbox |
| FR-060 | T121/T123 governed SDK subscriber entry |
| FR-061 | T049/T149 tenant-aware event authorization |
| FR-062 | T010/T047/T053/T060/T125/T128/T130/T167 context propagation and correlated event delivery evidence |
| FR-063 | T036/T041/T043/T044/T070/T133/T175 platform Event Bus enforcement, approved translation and bypass certification |
| FR-064 | T046/T047/T050/T051/T091/T092/T149/T151 lifecycle, assignment, retained delivery, retry and replay |
| FR-065 | T063–T066 canonical protections and gates |
| FR-066 | T036/T037/T039/T040/T045/T047–T049/T053/T070/T131–T133 schema, envelope, tenant, delivery, authorization, synchronous-contract and forbidden-coupling evidence |
| FR-067 | T050 duplicate subscription denial |
| FR-068 | T052 declared ordering behavior |
| FR-069 | T050/T051 no backfill and retained obligations |
| FR-070 | T020–T022 explicit child-context grants |
| FR-071 | T057/T060 managed Gateway ingress |
| FR-072 | T054/T056/T058–T060/T065/T070/T132 module-owned adapter and approved route-to-contract correspondence, lifecycle and evidence |
| FR-073 | T056 declaration and operation metadata |
| FR-074 | T178 certification without artificial API |
| FR-075 | T054/T056–T060/T065/T067/T070/T178 managed contract routes, health exceptions, certification and topology independence |
| FR-076 | T010/T057/T060/T128/T130 validated edge-to-Application context propagation |
| FR-077 | T008/T027/T060/T061/T065/T066/T131/T139/T143 bounded input, sink-safe encoding, application authorization and pre-exposure evidence |
| FR-078 | T054/T058/T059/T065/T066 lifecycle, invalidation and outage handling |
| FR-079 | T066 canonical semantics across implemented channels |
| FR-080 | T055 architecture-owned Gateway product ADR |
| FR-081 | T055/T057 product-neutral Gateway port and adapter |
| FR-082 | T068/T070/T071 uniform dependency certification |
| FR-083 | T069/T071 inward-owned capability ports |
| FR-084 | T068/T074/T080 persistence ports and private ownership |
| FR-085 | T043/T044 application Event Bus port and broker adapter |
| FR-086 | T011/T068–T071/T133/T142/T157–T158/T160–T163 capability-owned ports, infrastructure adapters, scaffolding/SDK and boundary evidence |
| FR-087 | T033/T070/T160 scaffold responsibilities |
| FR-088 | T068/T070/T133 architecture certification |
| FR-089 | T161/T162 SDK ports and platform context |
| FR-090 | T008/T054/T056/T059–T066/T070/T131–T133/T143/T164/T183 canonical contracts, exposure gates and concurrency |
| FR-091 | T010/T047/T060/T125–T130 redacted, bounded, tenant-safe telemetry and context propagation |
| FR-092 | T073/T074/T079 identifiable persistence ownership |
| FR-093 | T078/T080 owner-only mutation and migration |
| FR-094 | T072/T078 direct foreign access rejection |
| FR-095 | T037/T045/T075 canonical calls and event projections |
| FR-096 | T074/T079 ownership declaration |
| FR-097 | T074/T079 ambiguous owner rejection |
| FR-098 | T073/T080 logical isolation on shared infrastructure |
| FR-099 | T073/T080 tenant and least-privilege separation |
| FR-100 | T077 extraction compatibility |
| FR-101 | T075 consumer-owned projections |
| FR-102 | T075 checkpoint, source and recovery metadata |
| FR-103 | T076 local transaction boundaries |
| FR-104 | T045/T048/T076 local Outbox and Inbox |
| FR-105 | T075/T078–T082/T179/T182 tenant isolation, AES-256 and sensitive-copy controls |
| FR-106 | T068/T071/T080 inward persistence boundaries |
| FR-107 | T057/T060 Gateway has no module database ownership |
| FR-108 | T169 ownership manifest declarations |
| FR-109 | T162 SDK persistence, projection and event support |
| FR-110 | T033/T074/T160 scaffold sovereignty support |
| FR-111 | T074/T078–T080/T180/T181 unique migration ownership and independent contract evolution |
| FR-112 | T074/T078–T082/T091/T135/T147/T169/T180/T182 lifecycle, upgrade and deployment recovery evidence |
| FR-113 | T080 least-privilege runtime and migration credentials |
| FR-114 | T075/T077/T079/T082/T182 governed reporting, analytical, observability and audit derived copies |
| FR-115 | T078/T079/T170 prohibited ownership patterns |
| FR-116 | T036/T133 automated architecture checks |
| FR-117 | T077/T181 extraction, canonical model and contract-evolution tests |
| FR-118 | T080/T128/T130 attributable persistence telemetry |
| FR-119 | T075/T128/T179 tenant-safe projection, staleness, recovery and retained evidence |
| FR-120 | T083/T170 agent governance refusal |
| FR-121 | T002/T004/T061/T071/T131–T133/T143/T163/T177 independent compiler, coverage and mandatory boundary evidence |

| Criterion | Planned test, benchmark or evidence task |
|---|---|
| SC-001 | T014/T028 authority and uniqueness; T134 provisioning time |
| SC-002 | T028/T171 session/tenant tests; T134 login latency |
| SC-003 | T038 scaffold completeness; T134 elapsed time |
| SC-004 | T053 durable acceptance; T134 local/deployed p95 |
| SC-005 | T134 startup with 10+ modules |
| SC-006 | T014/T022 suspension and tenant isolation |
| SC-007 | T014/T028/T029 unauthorized authority denial |
| SC-008 | T094/T101/T172 configuration and reload |
| SC-009 | T108 compliance enforcement; T134 50-module timing |
| SC-010 | T113/T115/T116/T134 searchable source-derived content, troubleshooting, query relevance and timing |
| SC-011 | T168 measured example pass threshold |
| SC-012 | T002/T177 compiler and SDK type-error validation |
| SC-013 | T093/T108 failed-module/dependent isolation |
| SC-014 | T147 deployment profile; T166 horizontal scale |
| SC-015 | T137 audit retention; T164 submission audit; T171 authentication audit |
| SC-016 | T167 automatic module telemetry test |
| SC-017 | T134 scaffold-to-event elapsed time |
| SC-018 | T164/T165 submission lifecycle evidence; T176 external partner end-to-end publication |
| SC-019 | T033/T038/T103–T108/T148/T155/T156/T173/T183 current standards, automatic assessment, migration, impact and grace evidence |
| SC-020 | T036/T041/T043/T044/T053/T070/T133/T175 governed asynchronous interactions and bypass rejection |
| SC-021 | T036/T053/T070/T072/T133 forbidden dependencies and cycles |
| SC-022 | T053 event envelope/schema contract test |
| SC-023 | T053 duplicate-safe business effects |
| SC-024 | T053 durable acceptance without subscribers |
| SC-025 | T053/T151 event-path tenant isolation |
| SC-026 | T038/T053/T151 version discovery and uniqueness |
| SC-027 | T036/T037/T070/T133/T175 immediate-result justification and enforcement |
| SC-028 | T036/T043/T044/T070/T133/T163 vendor-free business boundaries |
| SC-029 | T053 atomic state/Outbox evidence |
| SC-030 | T010/T047/T053/T125/T128/T130/T167 correlated event delivery outcomes and asynchronous propagation |
| SC-031 | T053 ordered-consumption cases |
| SC-032 | T053/T151 event authorization and audit |
| SC-033 | T123/T131 governed subscriber entry |
| SC-034 | T047/T050/T051/T053/T091/T092/T151 activation and retained obligations |
| SC-035 | T022 delegated child-context tests |
| SC-036 | T135/T147 deployment recovery objectives |
| SC-037 | T164/T165 submission transition audit; T176 reviewer/approver separation |
| SC-038 | T117/T136 WCAG automated and human evidence |
| SC-039 | T060 governed-only external ingress |
| SC-040 | T054/T056/T058–T060/T065/T070/T132 module-owned adapters, approved canonical contracts and route-correspondence evidence |
| SC-041 | T178 unmanaged-route denial and no-API certification |
| SC-042 | T054/T058/T059/T060/T065 route invalidation, withdrawal and outage tests |
| SC-043 | T010/T060/T125/T128/T130/T143 validated Gateway and async context, telemetry isolation and transport verification |
| SC-044 | T008/T027/T060/T061/T064–T066/T131/T143/T164/T183 validation, encoding, canonical semantics and pre-exposure gates |
| SC-045 | T068/T071 dependency-direction fixtures |
| SC-046 | T068/T133 forbidden Domain imports |
| SC-047 | T071/T133 prohibited Application dependencies |
| SC-048 | T033/T036/T043/T044/T057/T068–T071/T074/T080/T133/T142/T160–T163 ports, infrastructure adapters, scaffolding, certification and SDK evidence |
| SC-049 | T055 Gateway selection ADR and evidence |
| SC-050 | T067 topology-independent contract test |
| SC-051 | T054/T058–T060 observable route lifecycle and outage reconciliation |
| SC-052 | T180 state-owner declaration certification |
| SC-053 | T170/T180 unique ownership validation |
| SC-054 | T072/T078/T080 foreign private-access denial |
| SC-055 | T072/T078 SQL, ORM and migration rejection |
| SC-056 | T181 canonical calls and independent event reactions |
| SC-057 | T179 projection source and checkpoint evidence |
| SC-058 | T080/T082 logical isolation on shared infrastructure |
| SC-059 | T077 extraction compatibility |
| SC-060 | T075/T077/T166/T179 idempotent, tenant-safe multi-instance projection handling |
| SC-061 | T076/T162 owner-local Outbox/Inbox |
| SC-062 | T074/T078–T080/T180/T181 discoverable exclusive migration owner and stable public contracts |
| SC-063 | T080 least-privilege and tenant isolation |
| SC-064 | T077 canonical versus private ORM models |
| SC-065 | T078/T180 forbidden and accepted ownership fixtures |
| SC-066 | T160/T180 scaffold/SDK ownership evidence |
| SC-067 | T074/T078–T082/T091/T135/T147/T169/T180/T182 owner lifecycle policy, classified AES-256 copies and upgrade/recovery evidence |
| SC-068 | T075/T077/T079/T082/T182 governed reporting, analytical, observability and audit products |
| SC-069 | T075/T128/T179 missing/mismatched tenant, stale state, ordering, recovery and retained evidence |
| SC-070 | T179 attributable persistence/projection telemetry |
| SC-071 | T076 local transactions and governed exceptions |
| SC-072 | T083/T170 automation refusal fixtures |
| SC-073 | T002/T004 per-scope machine-readable CI and compiler evidence; T061/T071/T131–T133/T143/T163/T177 mandatory independent contract, architecture, security and type boundaries |

## Dependencies and Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No feature dependency; T001 precedes project-level tooling and service setup.
- **Foundational (Phase 2)**: Depends on project setup; provides context composition, persistence/RLS, shared errors, audit, observability, resilience, contract validation, and architecture gates.
- **P1 stories (US1–US4, US11–US15)**: Start after foundational work and the specific story dependencies below. Gateway product and physical persistence decisions precede their dependent adapters/provisioning.
- **P2 stories (US5–US8)**: US5 consumes US3 manifest validation and US4 delivery-obligation ports; US6 consumes tenant/authorization/audit capabilities; US7 consumes US3 validation and US5 lifecycle ports; US8 consumes identity/credential, module catalog, and documentation APIs.
- **P3 stories (US9–US10)**: US9 consumes US3 contracts and US4 Event Bus capabilities; US10 consumes Phase 2 observability plus US4 event instrumentation and US5 health/lifecycle states.
- **Polish**: Depends on the stories and channels selected for release; T135 and T136 remain deployment/release evidence gates.

### User Story Dependencies

- **US1 (P1)**: Tenant context and isolation depend on Phase 2; provisioning handlers use T015, applicable state changes use US12 command protection, private persistence provisioning follows T073, and member workflows depend on US2 identity capabilities.
- **US2 (P1)**: Depends on shared persistence, tenant-context, audit, and error capabilities; bootstrap tests use platform/operator fixtures.
- **US3 (P1)**: Can proceed after setup and architecture foundations; shares module-catalog context with US5 but supplies static manifest/template validation. T148 precedes T033; the later standards-refresh capability T155/T156 follows US7 standards work and the T183 contract decision, without blocking independent initial scaffolding.
- **US4 (P1)**: Depends on tenant context, identity/authorization ports, audit, and shared messaging foundations; apply US12 command protection to applicable request retries.
- **US11 (P1)**: Depends on US3 declarations and certification contracts, US12 exposure evidence, and T055 before a product-specific adapter. Lifecycle integration uses US5 module availability ports; test with compliant fixtures until those ports are implemented.
- **US12 (P1)**: Idempotency and gate policies depend on canonical contracts and Phase 2 foundations; Gateway integration and topology end-to-end tests follow US11. Implement the gate port before US11 publication integration rather than creating a circular dependency.
- **US13 (P1)**: Builds on US3 scaffolding and Phase 2 architecture boundaries; its Gateway adapter fixtures use the US11 management port.
- **US14 (P1)**: Depends on US3 manifest declarations and US4 event contracts; T073 precedes dependent persistence provisioning, and projection verification uses US4 inbox semantics.
- **US15 (P1)**: Depends on US14 ownership declarations, T073 and Phase 2 persistence/audit; implement T079 owner-policy certification independently before T091 lifecycle integration, then run T182 after applicable migrations and lifecycle work and before T135 recovery evidence.
- **US5 (P2)**: Depends on US3 manifest validation and US4 event registry/delivery-obligation capabilities; integrates with US7 standards enforcement.
- **US6 (P2)**: Depends on US1 tenant context, US2 authorization, and Phase 2 audit/persistence capabilities.
- **US7 (P2)**: Depends on US3 validation and US5 module/install lifecycle ports.
- **US8 (P2)**: Credential presentation follows the US8 credential capability; portal marketplace and templates consume US5/US3 APIs; accessible release evaluation follows a complete portal candidate.
- **US9 (P3)**: Depends on US3 canonical module contracts and US4 event contracts/semantics.
- **US10 (P3)**: Depends on Phase 2 OpenTelemetry bootstrap, US4 event telemetry, and US5 lifecycle/readiness states.

### Parallel Opportunities

- After T001, setup configuration, Docker infrastructure, and test-runner setup can proceed independently.
- Within Phase 2, persistence setup, contract validation, OpenTelemetry bootstrap, and architecture tests can proceed in parallel once the project skeleton exists.
- P1 story work can proceed concurrently after shared foundations and the required ports identified above are ready.
- US5–US8 have cross-story integration dependencies listed above; independent domain tests, templates, UI/static content, and adapters can proceed in parallel after their required ports/contracts exist.
- Write the relevant failing tests before implementation. Tasks marked `[P]` may run concurrently only after their explicit test, file and port prerequisites are complete; examples below distinguish test and implementation waves.
- T139 precedes T140–T142; T143 follows those tasks and precedes external tests/activation. T144–T147 are owner-approved decision gates; T164 implements the approved submission matrix before T085/T086/T093, with T165 verifying it after T085/T086. T055, T073 and T081 gate their respective adapters or provisioning. Contract and Application ports precede adapters; T065/T066 and applicable security tests precede channel activation. T134/T135/T166/T168 follow the measured implementation and precede release evidence.
- T183's approved canonical contract precedes the T155 Application capability and T156 CLI adapter; no new standards-impact channel activates before applicable gates. T079's policy certification precedes T091 lifecycle integration, and T182 follows the applicable owner-controlled migrations and T091 before T135.

## Parallel Execution Examples

- **US1**: Write T014 first; then T016 and T017 may proceed on distinct files. T018 follows tenant context; T019 follows T015 and the model.
- **US2**: Write T023 first; T024 and T026 can proceed on separate files once their test and port prerequisites exist.
- **US3**: Write T030 and T036 first; T031 and independent scaffolding components follow their fixtures.
- **US4**: Write T039 first; event model, archive policy and independent port work can proceed on separate files after required interfaces exist.
- **US11**: Write T054 first; T055 and declaration validation can proceed independently, then the adapter and lifecycle follow their ADR and gate port.
- **US12**: Write T061 and T062 together; idempotency and exposure-gate implementations can then proceed on separate files.
- **US13**: Write T068 first; capability declaration and independent architecture fixtures can proceed after their required contracts exist.
- **US14**: Write T072 first; T073 and ownership declaration work can proceed independently, followed by projection and extraction tests.
- **US15**: Write T078 first; credential enforcement and encryption design can proceed independently once ownership boundaries exist.
- **US5**: Write T084 first; submission models and independent certification fixtures can follow on separate files.
- **US6**: Write T094 first; repository, secret resolution, reload, and restart work follows the domain resolver.
- **US7**: Write T102 first; report APIs and grace enforcement follow standards and assessment ports.
- **US8**: Write T109 first; credential APIs and portal UI can proceed separately after identity/authorization contracts exist.
- **US9**: Write T118 first; T119 and T120 can then proceed on separate files; event and observability modules follow stable public types.
- **US10**: Write T125 first; health, tracing, and exporter work can proceed on separate files after observability bootstrap.

## Implementation Strategy

### MVP First

1. Complete Phase 1 and Phase 2, the persistence ADR T073, and the US12 command-protection prerequisites for applicable state changes.
2. Implement and independently test **US1** as the first product increment; its tenant-admin/member journey requires the minimal US2 identity bootstrap and RBAC capabilities.
3. Stop at the US1 checkpoint and verify tenant isolation, delegated access, audit, and actor authority before expanding the platform. Use internal test fixtures until US11/US12 and all applicable pre-exposure gates permit external activation.

### Incremental Delivery

1. Deliver the shared foundation and P1 stories (US1–US4 and US11–US15), validating each independently.
2. Add P2 module lifecycle, configuration, governance, and developer portals (US5–US8) with their explicit cross-story ports.
3. Add P3 external SDK and monitoring/telemetry (US9–US10).
4. Complete contract, architecture, security, performance, accessibility, recovery, and end-to-end release gates before claiming readiness.

## Notes

- `[P]` tasks use separate files and have no incomplete prerequisite within their current phase.
- CI independently enforces Domain >=85%, critical Domain >=95%, Application >=85%, critical Application >=95%, Infrastructure >=70%, Presentation >=60%, and generated-feature unit tests >=85%; security/authorization code receives 95% only when in a critical Domain or Application scope.
- Every constrained model field implemented by a task is cited to `data-model.md`; do not duplicate or contradict its canonical constraints.
- Business modules, billing behavior, a general administrative dashboard, and a hostile-code sandbox are out of scope.
- Product-selection and physical-isolation ADRs, deployment-defined policies, implementation, and applicable test evidence remain prerequisites for dependent work or release; tenant authority and design-time contract validation are resolved.
