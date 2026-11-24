# Feature Specification: Platform Core Foundation

**Feature Branch**: `001-platform-core-foundation`

**Created**: 2026-11-22

**Status**: Draft

**Input**: Platform Core Foundation — foundational platform hosting all future business modules

## Vision

The Platform Core Foundation establishes the architectural and operational backbone for an extensible, modular SaaS system. This release focuses **exclusively** on core infrastructure, governance, and extension mechanisms — business modules (Billing, Subscriptions, etc.) are excluded from v1 and delivered as optional extensions.

The foundation must enable autonomous module development, strong isolation guarantees, and versioned standards evolution without requiring changes to the core platform.

Every module owns its private state, and only its owner may authoritatively mutate that state. Logical data ownership is mandatory; physical database infrastructure may be shared only when enforceable ownership, access, migration, and tenant-isolation boundaries remain intact.

## Clarifications

### Session 2026-11-22

- Q: Which interfaces should the first release include for documentation and developers? → A: Include both portals; exclude the general administrative dashboard.
- Q: May the first release install modules whose code has not been reviewed and approved by the platform operator? → A: Only operator-reviewed and approved module code may be installed, including partner code.
- Q: What should happen if an optional installed module fails validation or startup? → A: Keep the core and unaffected modules available; disable the failed module and its dependents.
- Q: What delivery guarantee should the platform provide for accepted events when a subscriber is temporarily unavailable? → A: Deliver at least once; duplicates may occur, but repeated business effects are prevented.
- Q: How should a grace period for new platform standards apply to modules that do not yet meet those standards? → A: Grace applies only to already-installed modules; new installations must meet enforced standards.

### Planning decision 2026-11-22

- Q: Should developer API credential management be included in this release? → A: Include it in v1.
- Q: How should audit records handle secret-valued configuration settings? → A: Record redacted references or versions, never secret values; retain before/after values for non-secret settings.
- Q: What should happen when the database URL changes? → A: Validate and stage the change; apply it on restart.
- Q: What happens when a module is uninstalled with undelivered events assigned to its subscriber? → A: Uninstall remains pending until those events are processed.
- Q: How do partners publish extensions without access to the core repository? → A: Submit releases through the platform; an operator reviews and approves the exact artifact before publication or installation.
- Q: What is the initial role-permission policy? → A: Tenant admins manage tenant capabilities; developers use documentation, scaffolding, event tooling, partner submissions, and their own API credentials; governance officers inspect tenant compliance and audit; users read their own profile and tenant settings; billing managers receive no billing privileges until a billing module exists. Platform authority is separate; unspecified access is denied.
- Q: What happens when an installed module still violates upgraded standards after its grace period expires? → A: Disable the non-compliant module and its dependent modules; keep the core and unaffected modules available.

### Session 2026-11-23

- Q: May the same email address identify separate user accounts in different tenants? → A: Allow one account per tenant for the same email, with tenant-qualified sign-in and case-insensitive uniqueness within each tenant.
- Q: After logout, should an access token already issued to that session remain usable until it expires? → A: Reject access tokens from the logged-out session immediately.
- Q: When a user logs out, which refresh-token sessions should be invalidated? → A: Revoke refresh tokens for the current session only.
- Q: Within a deployment, how should tenant slugs be unique when tenants have parent-child relationships? → A: Each slug is unique across the deployment, ignoring case.
- Q: What should happen to tenant access and pending background work while a tenant is suspended? → A: Deny tenant business access while allowing authorized background processing and maintenance.
- Q: When a module subscribes after an event was published, should it receive earlier retained events? → A: No historical replay for new subscriptions.
- Q: Should v1 support parent-child tenant relationships, or must every tenant remain an independent organization boundary? → A: Parent tenants may administer child tenants under explicitly governed delegated access.
- Q: After a production outage, what maximum data loss and service restoration time should v1 promise? → A: No platform-wide numeric target in v1; define targets per deployment.
- Q: Should the same platform operator be allowed to both review and approve a partner module, or must those actions be performed by different people? → A: The deployment policy determines whether reviewer and approver must differ.
- Q: What accessibility standard should the in-scope documentation and developer portals meet? → A: WCAG 2.2 AA.
- Q: If the Gateway control plane is unavailable while data-plane routes remain active, how should external traffic behave? → A: Continue routing with the last successfully validated configuration for capabilities that remain available; pause route changes until control-plane recovery, and retain application-level fail-closed checks for disabled or unauthorized capabilities.
- Q: What maximum number of active tenants should v1 be designed and tested to support? → A: Deployment-specific, no global limit.
- Q: Does private persistence ownership require a separate physical database server or cluster per module? → A: No. Logical ownership and enforceable isolation are mandatory; physical topology is a planning/deployment decision, and shared PostgreSQL infrastructure is permitted when those boundaries are preserved.
- Q: How may a module use information owned by another module? → A: Use a canonical synchronous contract when current authoritative information or an immediate authoritative result is required; consume a versioned Integration Event into a consumer-owned derived projection when eventual consistency is acceptable.
- Q: Which policy governs root and child tenant provisioning, suspension/reactivation, initial Tenant Admin bootstrap, and the Organization Administrator persona? → A: The Platform Operator creates root and child tenants in v1, suspends and reactivates tenants, and bootstraps the initial Tenant Admin. A Tenant Admin may request child provisioning only through a future explicitly governed capability but may not create a child in v1; an explicit delegation policy after v1 may grant scoped child-creation permission. Organization Administrator is a persona mapped to Platform Operator for provisioning, not a separate role; tenant-scoped management uses Tenant Admin. Parent-child relationships alone grant no authority.
- Q: When may initial Tenant Admin bootstrap occur, and how does the provisioning persona apply? → A: A Platform Operator may bootstrap the initial Tenant Admin when no Tenant Admin exists; other non-admin users do not by themselves prevent bootstrap. Organization Administrator is the Platform Operator persona for provisioning, suspension/reactivation, and initial bootstrap. In v1, the Platform Operator authorizes child creation; a Tenant Admin may request it only through a future explicitly governed capability.
- Q: What is the authoritative ModuleSubmission.status lifecycle? → A: An authorized partner creates a pending_review submission; a Platform Operator makes only the FR-019 transitions, with rejected and revoked terminal. Resubmission creates a new submission with fresh review and approval. Submission, certification, installation, publication eligibility, and exposure remain distinct; every accepted transition is authorized and audited.

## User Scenarios & Testing

### User Story 1 - Platform Operator Provisions and Tenant Admin Manages Tenant (Priority: P1)

The Organization Administrator is a user-story persona mapped in v1 to the platform-global Platform Operator for tenant provisioning, suspension/reactivation, and initial Tenant Admin bootstrap, not a separate role. The Platform Operator provisions isolated tenants and bootstraps their initial Tenant Admin; a Tenant Admin manages authorized tenant-scoped settings and members.

**Why this priority**: Tenant provisioning is the absolute prerequisite for any multi-tenant operation. Without this, no business can be conducted.

**Independent Test**: Can provision root and child tenants through the authorized actor, bootstrap a Tenant Admin, verify denied unauthorized actions and data isolation, and configure tenant settings end-to-end.

**Acceptance Scenarios**:

1. **Given** an empty Platform Core installation, **When** a Platform Operator creates a root tenant, **Then** the tenant is provisioned with unique isolation boundaries and no data leakage to other tenants
2. **Given** a provisioned tenant, **When** its Tenant Admin retrieves tenant settings and members, **Then** they see only their tenant's configuration and member list
3. **Given** multiple tenants in the system, **When** data queries execute within one tenant's context, **Then** results contain zero data from other tenants
4. **Given** a parent tenant administrator has an explicit delegated grant for a child tenant, **When** they perform a child-tenant operation, **Then** access is limited to that grant and the child tenant's authoritative context; without the grant, the operation is denied
5. **Given** a provisioned tenant, **When** a Platform Operator suspends it, **Then** tenant-initiated business operations are denied, its data is retained for the applicable compliance period, and isolation is preserved; a tenant-scoped role cannot suspend it.
6. **Given** a suspended tenant has pending background work, **When** authorized background processing or maintenance runs, **Then** it may continue under the tenant's context and applicable authorization, isolation, audit, and delivery controls; a Platform Operator may reactivate the tenant, but a tenant-scoped role cannot.
7. **Given** a tenant slug already exists in the deployment, **When** a tenant is created or its slug is changed to the same value with different letter casing, **Then** the change is rejected regardless of parent-child relationships and the existing tenant remains unchanged.
8. **Given** a Tenant Admin, **When** they attempt to create a root tenant, **Then** the operation is denied without creating a tenant.
9. **Given** a Tenant Admin and a future explicitly governed child-provisioning request capability, **When** they submit an authorized request for a child tenant, **Then** the request does not itself create the child or authorize its creation.
10. **Given** a parent-child relationship or a grant to administer an existing child, **When** a Tenant Admin attempts to create a child tenant in v1, **Then** the attempt is denied; an authorized Platform Operator can create the child.
11. **Given** a tenant has non-admin users but no Tenant Admin, **When** initial bootstrap is attempted, **Then** a Platform Operator can bootstrap the initial Tenant Admin when otherwise valid, and a tenant-scoped role cannot perform the bootstrap.
12. **Given** a newly provisioned tenant has no users or Tenant Admin, **When** a Platform Operator performs otherwise valid initial bootstrap, **Then** the initial Tenant Admin is created.
13. **Given** a tenant already has a Tenant Admin, **When** initial Tenant Admin bootstrap is attempted, **Then** the bootstrap is denied without creating another initial Tenant Admin.

**Traceability**: Scenario 1 → FR-001, FR-003, FR-005; SC-001, SC-006. Scenario 2 → FR-003, FR-005, FR-007; SC-006–SC-007. Scenario 3 → FR-002, FR-005; SC-006. Scenario 4 → FR-002, FR-070; SC-035. Scenarios 5–6 → FR-004–FR-005, FR-007; SC-006–SC-007. Scenario 7 → FR-003; SC-001. Scenario 8 → FR-001, FR-007; SC-001, SC-007. Scenarios 9–10 → FR-001, FR-007, FR-070; SC-001, SC-007, SC-035. Scenarios 11–13 → FR-001, FR-007; SC-001, SC-007.
---

### User Story 2 - Identity Administrator Creates Users and Assigns Roles (Priority: P1)

A tenant's identity administrator must create users, assign roles (admin, user, billing manager), and enforce role-based access control.

**Why this priority**: IAM is critical for security and operational governance. Without user management and RBAC, the platform cannot enforce multi-tenancy boundaries or authorization.

**Independent Test**: Can create users with different roles, verify role-based access restrictions, and test permission enforcement independently.

**Acceptance Scenarios**:

1. **Given** a provisioned tenant with an existing Tenant Admin, **When** that Tenant Admin creates another user with the "admin" role, **Then** that user can manage the tenant capabilities permitted by the tenant-admin policy
2. **Given** a user with "user" role, **When** they attempt to access billing settings, **Then** access is denied with clear error message
3. **Given** a user logged in, **When** they request an access token, **Then** the token contains correct role and tenant information
4. **Given** an authentication attempt, **When** it succeeds or fails, **Then** the applicable authentication event is recorded in the audit trail.
5. **Given** a user has two active sessions, **When** they log out of one session, **Then** that session's refresh tokens can no longer obtain access tokens, its already-issued access tokens are rejected immediately for subsequent requests, the other session remains usable, and logout is audited.
6. **Given** separate tenants have accounts with the same email address, **When** a user signs in with an explicit tenant and valid credentials, **Then** only that tenant's account is authenticated; a duplicate email within the same tenant is rejected ignoring case, and sign-in without a valid tenant is denied.
7. **Given** a Tenant Admin, **When** they attempt to grant platform-global authority to themselves or another tenant role, **Then** the grant is denied and no platform-global authority is acquired.

**Traceability**: Scenario 1 → FR-006–FR-007, FR-010; SC-007, SC-015. Scenario 2 → FR-007; SC-007. Scenario 3 → FR-008–FR-010; SC-002, SC-007. Scenario 4 → FR-011; SC-015. Scenario 5 → FR-008–FR-009, FR-011; SC-002, SC-015. Scenario 6 → FR-005–FR-006, FR-010; SC-002, SC-007. Scenario 7 → FR-007; SC-007.
---

### User Story 3 - Developer Scaffolds a New Module Using Platform Templates (Priority: P1)

A developer needs to quickly scaffold a new module that follows platform standards, inherits governance rules, and integrates with the core platform without manual setup.

**Why this priority**: Module scaffolding accelerates development and enforces architectural consistency. This directly enables the promise of "autonomous module development."

**Independent Test**: Can execute module scaffolding command, verify generated structure matches platform standards, and confirm module passes governance validation.

**Acceptance Scenarios**:

1. **Given** the platform CLI installed, **When** developer runs `sdd-cli module:scaffold --name analytics`, **Then** a new module is created with all required directories, templates, and governance files
2. **Given** a scaffolded module, **When** validation runs, **Then** all governance rules pass and module is ready for development
3. **Given** a scaffolded module, **When** developer reviews generated files, **Then** module manifest, Integration Event contracts, and synchronous contract declarations are pre-populated
4. **Given** Module A requires information owned by Module B, **When** a developer attempts to access Module B's repository directly, **Then** module architecture validation rejects the dependency and reports the violation
5. **Given** Module B owns a persistence boundary, **When** Module A attempts to access Module B's database or schema, including through shared persistence, **Then** module architecture validation rejects the dependency and reports the violation
6. **Given** Module A inherently requires an immediate result from a capability owned by Module B, **When** Module B exposes a canonical versioned synchronous contract, **Then** Module A may use that contract without accessing Module B's implementation, and any in-process invocation preserves the same governance controls without requiring loopback HTTP
7. **Given** canonical synchronous contracts between modules form a dependency cycle, **When** module validation runs, **Then** the cycle is rejected
8. **Given** modules declare Integration Events and canonical synchronous contracts in their manifests, **When** module validation runs, **Then** those versioned contract dependencies are statically discoverable and validated without exposing implementation dependencies
9. **Given** Module A imports Module B's infrastructure implementation, provider adapter, internal domain model, or private service, **When** module architecture validation runs, **Then** the dependency is rejected and the violation is reported
10. **Given** a developer scaffolds a module, **When** the generated module is inspected and architecture validation runs, **Then** it supports distinct Domain, Application, inbound-adapter, outbound-port, and infrastructure-adapter responsibilities and validates dependency direction without requiring specific directory names
11. **Given** a module has no externally consumable synchronous capability, **When** the module is registered and certified, **Then** it can pass without declaring or exposing an artificial public API
12. **Given** a module exposes an external synchronous capability, **When** its manifest is validated, **Then** its canonical API contract, version, publishable operations, and applicable security and tenant requirements are declared without vendor-specific Gateway dependencies

13. **Given** a developer scaffolds a module that owns private state, **When** the generated responsibilities and certification rules are inspected, **Then** the module has an identifiable persistence owner, inward-owned persistence port, owner-controlled migrations, and projection support where applicable without prescribed directory names
14. **Given** updated platform standards, **When** a developer refreshes module templates with the standards-update command, **Then** the templates are updated under the applicable version and migration policy.

**Traceability**: Scenario 1 → FR-025–FR-026; SC-003. Scenario 2 → FR-027, FR-036; SC-009. Scenario 3 → FR-018, FR-026; SC-003, SC-026. Scenario 8 → FR-018, FR-036; SC-026. Scenarios 4–5, 7–9 → FR-022, FR-021, FR-036, FR-063; SC-021. Scenario 6 → FR-055, FR-057–FR-058; SC-027–SC-028. Scenario 10 → FR-087–FR-088; SC-045, SC-048. Scenario 11 → FR-074, FR-087; SC-041, SC-048. Scenario 12 → FR-072–FR-073, FR-081; SC-040. Scenario 13 → FR-108, FR-110, FR-115–FR-116; SC-066. Scenario 14 → FR-028, FR-034; SC-019.

---

### User Story 4 - Module Developer Communicates Through the Platform Event Bus (Priority: P1)

A developer authoring a module must publish and consume governed, versioned Integration Events through the Platform Event Bus without coupling to publisher or subscriber implementations.

**Why this priority**: Event publishing is the foundational communication mechanism between modules. Without standardized events, loose coupling (a core principle) cannot be achieved.

**Independent Test**: Can publish a conforming Integration Event once and verify independent subscribers receive it under the platform's tenant, compatibility, idempotency, and observability rules.

**Acceptance Scenarios**:

1. **Given** a module maps an internal Domain Event to a cross-context occurrence, **When** the publication boundary creates an Integration Event, **Then** the Domain Event remains internal and the independently versioned Integration Event uses the governed envelope and required metadata
2. **Given** Module A publishes an Integration Event and Module B is temporarily unavailable, **When** the event is durably accepted, **Then** Module A can complete the originating operation without Module B being synchronously available and the event remains eligible for retry
3. **Given** Module A publishes one Integration Event and Modules B and C subscribe to compatible versions, **When** the event is delivered, **Then** each subscriber can process it independently without Module A knowing either subscriber
4. **Given** the same accepted Integration Event is delivered more than once, **When** a subscriber processes the deliveries, **Then** its corresponding business effect occurs only once
5. **Given** an Integration Event belongs to Tenant A, **When** it is routed, retried, dead-lettered, or consumed, **Then** its authoritative tenant context, not a payload-provided tenant claim, governs processing and an unauthorized Tenant B subscriber cannot observe or act on Tenant A data
6. **Given** a module publishes or consumes an Integration Event, **When** its module contract and dependencies are validated, **Then** valid Event Bus contract use passes and a RabbitMQ/Kafka client dependency in domain/application business logic is rejected
7. **Given** a business occurrence has completed and other modules need only react, **When** architecture validation evaluates the interaction, **Then** the publisher uses an Integration Event and direct synchronous calls to interested modules are rejected as an Event Bus bypass
8. **Given** a valid Integration Event has no current subscribers, **When** it is durably accepted, **Then** publication does not require subscriber discovery and the originating operation can complete
9. **Given** a publisher becomes unavailable after durable event acceptance, **When** subscribers are available later, **Then** the accepted event remains eligible for eventual delivery without the publisher's availability
10. **Given** an event contract has a supported ordering requirement, **When** a consumer receives events in an order that violates that contract, **Then** the consumer does not apply effects in a way that violates the declared ordering requirement
11. **Given** an event envelope is malformed, names an unknown event type, lacks required tenant context, or uses an unsupported schema version, **When** it is validated, **Then** no business effect is applied and the validation failure is observable under platform policy
12. **Given** a business operation commits state and requires an Integration Event, **When** the operation succeeds, **Then** the business state and pending publication are durably coordinated and eventual publication follows at-least-once semantics without a generic exactly-once promise
13. **Given** an Integration Event triggers an operation requiring authorization or policy evaluation, **When** the subscriber enters the application capability, **Then** the authoritative controls and audit outcome are preserved
14. **Given** a subscriber is exposed through MCP, CLI, GUI, SDK, or automation, **When** it handles an Integration Event, **Then** it enters the governed application capability and does not publish directly to broker infrastructure or mutate domain/persistence state through a shortcut
15. **Given** a publication and delivery crosses module boundaries, **When** an operator inspects observability, **Then** the originating operation can be correlated with the domain occurrence, event, publication, delivery attempt, and subscriber outcome using applicable event, tenant, correlation, and trace metadata
16. **Given** an Integration Event is published, **When** an authorized user queries the Event Registry, **Then** its version, source module, compatibility information, and documentation are discoverable
17. **Given** a consumer repeatedly fails to process an event, **When** governed retry handling reaches dead-letter handling, **Then** the failure and dead-letter outcome are observable and are not reported as successful business processing
18. **Given** platform event and module contracts are validated, **When** contract tests run, **Then** they verify schema/version compatibility, required metadata, tenant isolation, duplicate idempotency, correlation/trace propagation, publisher independence, retry/dead-letter behavior, authorization/policy/audit preservation, synchronous contract boundaries, and forbidden implementation coupling
19. **Given** a module registers the same event subscription more than once for the same tenant scope and contract version, **When** registration is validated, **Then** the duplicate active registration is rejected or prevented and its outcome is observable
20. **Given** subscribers declare compatible event-type, tenant, and aggregate/resource filters, **When** an Integration Event is routed, **Then** only matching authorized subscriptions receive it
21. **Given** an Integration Event was accepted before a subscriber registered, **When** that new subscription becomes active, **Then** it receives no historical event automatically
22. **Given** an Application capability publishes or consumes an Integration Event, **When** its dependencies are certified, **Then** it depends on an inward-owned Event Bus port while broker-specific clients and topology remain in infrastructure adapters
23. **Given** a completed business occurrence is intended for asynchronous propagation, **When** module contracts are validated, **Then** it uses the Platform Event Bus rather than the API Gateway, and agent adapters do not use Gateway administration to bypass platform governance
24. **Given** a consumer needs eventually consistent information owned by another module, **When** it consumes a versioned Integration Event, **Then** it may update a tenant-aware, idempotent local projection that remains derived and does not mutate the source module's authoritative state
25. **Given** the local-development and externally deployed profiles, **When** valid event publication is measured from the application request to durable acceptance, **Then** p95 latency meets the applicable SC-004 threshold.

**Traceability**:
- Scenario 1 → FR-013, FR-056; SC-022, SC-026
- Scenario 10 → FR-068; SC-031
- Scenario 11 → FR-013, FR-017, FR-052–FR-053, FR-061; SC-022, SC-025
- Scenario 2 → FR-012, FR-014; SC-020, SC-024
- Scenario 3 → FR-012, FR-014; SC-020, SC-024
- Scenario 8 → FR-012, FR-014; SC-020, SC-024
- Scenario 9 → FR-012, FR-014, FR-059; SC-020, SC-024, SC-029
- Scenario 4 → FR-014; SC-023
- Scenario 5 → FR-015, FR-053, FR-061; SC-025
- Scenarios 6–7, 14 → FR-012, FR-055, FR-063, FR-065; SC-020, SC-027–SC-028
- Scenario 12 → FR-059, FR-104; SC-029, SC-061
- Scenario 13 → FR-060–FR-061; SC-032
- Scenario 14 → FR-060, FR-065; SC-028, SC-033
- Scenario 15 → FR-062; SC-030
- Scenario 16 → FR-016; SC-026
- Scenario 17 → FR-014, FR-062; SC-030
- Scenario 18 → FR-036, FR-066; SC-022–SC-030, SC-032
- Scenario 19 → FR-067; SC-026
- Scenario 20 → FR-015; SC-020, SC-025
- Scenario 21 → FR-069; SC-034
- Scenario 22 → FR-085, FR-088; SC-046
- Scenario 23 → FR-079; SC-020
- Scenario 24 → FR-095, FR-101, FR-104–FR-105, FR-117; SC-056, SC-060–SC-061, SC-064
- Scenario 25 → FR-012; SC-004

---

### User Story 5 - Extension Developer Discovers and Installs Available Extensions (Priority: P2)

A developer or administrator needs to discover available extensions (modules) in the marketplace, review documentation, and install them with one command.

**Why this priority**: Extension discovery and installation are essential for extensibility but can be delivered after core foundation. Users can manually manage extensions initially.

**Independent Test**: Can query extension registry, view extension details and documentation, and install an extension with automatic dependency resolution.

**Acceptance Scenarios**:

1. **Given** the platform CLI, **When** developer runs `sdd-cli extension:list`, **Then** output shows all available extensions with version, description, and requirements
2. **Given** an extension in the registry, **When** developer runs `sdd-cli extension:install analytics@2.1.0`, **Then** extension is downloaded, dependencies are resolved, and installation completes without errors
3. **Given** an installed extension, **When** developer runs `sdd-cli extension:info analytics`, **Then** detailed documentation is displayed (readme, event contracts, API endpoints)
4. **Given** a module whose code has not been reviewed and approved by the platform operator, **When** installation is attempted, **Then** installation is denied
5. **Given** a partner without access to the core repository, **When** they submit an extension release through the platform and an operator approves its exact artifact, **Then** the release can be published in the extension catalog
6. **Given** module removal or subscription deactivation is requested while governed deliveries remain pending, **When** lifecycle validation runs, **Then** deactivation/removal remains pending until those delivery obligations are safely resolved and the outcome is observable
7. **Given** a module upgrade changes supported event schema versions, **When** compatibility validation runs, **Then** the upgrade is rejected before activation if it would violate a governed event contract or pending delivery guarantee
8. **Given** a deployment requires separate review and approval, **When** the reviewer attempts to approve the same module artifact, **Then** approval is rejected and the review and approval identities are recorded
9. **Given** an optional module fails validation or startup, **When** installation or activation is evaluated, **Then** the failed module and its dependents remain unavailable while Core and unaffected modules continue operating.
10. **Given** at least ten installed modules, **When** the platform starts, **Then** startup completes within the SC-005 target.
11. **Given** an authorized partner submits an immutable artifact, **When** the submission is created, **Then** its status is `pending_review` and creation is audited; a positive review and separate positive approval of that exact digest by authorized Platform Operators transition it to `approved` under the deployment's separation policy.
12. **Given** a `pending_review` submission, **When** a Platform Operator records a negative review or approval decision, **Then** it becomes terminal `rejected` and cannot be activated; a partner resubmission creates a new `pending_review` submission with no inherited review or approval.
13. **Given** an `approved` submission with successful manifest validation and active exact-digest approval, **When** a Platform Operator publishes it to the catalog, **Then** it becomes `published` without automatically installing, activating, or exposing the module or any route.
14. **Given** a `pending_review`, `approved`, or `published` submission, **When** a Platform Operator revokes or withdraws it, **Then** it becomes terminal `revoked`; invalidated availability and exposure are reconciled under applicable lifecycle controls without discarding delivery obligations, and a resubmission is a new submission.
15. **Given** a requested status change outside the allowed matrix or by an unauthorized actor, **When** it is evaluated, **Then** it is denied without changing status and the denial is audited; an exact retry follows the existing idempotency rules rather than creating a new transition.
16. **Given** an approved or published submission, **When** certification, installation, or channel exposure is evaluated, **Then** the distinct applicable certification and pre-exposure gates remain mandatory, and each accepted submission transition has immutable, attributable, secret-free audit evidence.

**Traceability**: Scenarios 1–2 → FR-020–FR-021; SC-018. Scenario 3 → FR-042, FR-046; SC-010–SC-011. Scenarios 4–5 → FR-019; SC-018, SC-037. Scenarios 6–7 → FR-017–FR-018, FR-023, FR-064; SC-026, SC-030. Scenario 8 → FR-019; SC-037. Scenario 9 → FR-024; SC-013. Scenario 10 → FR-020, FR-023; SC-005. Scenarios 11–12 → FR-019, FR-023; SC-018, SC-037. Scenarios 13–14 → FR-019, FR-023, FR-078, FR-090; SC-018, SC-037, SC-044. Scenarios 15–16 → FR-019, FR-023, FR-033, FR-090; SC-015, SC-018, SC-037, SC-044.

---

### User Story 6 - Configuration Manager Updates Environment-Specific Settings (Priority: P2)

An operations engineer needs to manage environment-specific configuration (database URLs, API keys, feature flags) without code changes; critical infrastructure changes may require a restart.

**Why this priority**: Configuration management is important for operational flexibility but can use environment variables as an interim solution. Formal configuration system improves usability.

**Independent Test**: Can set configuration values, verify changes are applied to modules, and test feature flag toggles without restart.

**Acceptance Scenarios**:

1. **Given** the configuration management interface, **When** an engineer updates a database URL, **Then** the new value is validated and staged; modules use the new connection after restart
2. **Given** a feature flag disabled, **When** an engineer enables it, **Then** the feature is available immediately in the system
3. **Given** environment-specific configuration, **When** the platform starts in a different environment, **Then** correct configuration is loaded
4. **Given** a secret-valued setting changes, **When** its audit record is inspected, **Then** the record contains no secret value and identifies the change using redacted references or versions

**Traceability**: Scenario 1 → FR-030–FR-033; SC-008, SC-015. Scenarios 2–3 → FR-029, FR-032; SC-008. Scenario 4 → FR-033; SC-015.
---

### User Story 7 - Governance Officer Audits Module Compliance and Standards Evolution (Priority: P2)

A governance officer needs to verify that all modules comply with platform standards, track standards versions, and audit when standards were updated.

**Why this priority**: Governance and compliance are essential for large teams but can initially be managed through manual review. Automated compliance reporting improves scalability.

**Independent Test**: Can run compliance check on all modules, receive report showing standards versions used, and query compliance history.

**Acceptance Scenarios**:

1. **Given** multiple modules installed, **When** compliance check runs, **Then** report shows each module's platform standards version and any violations
2. **Given** platform standards updated to v2.0, **When** governance officer queries history, **Then** timeline shows when v2.0 was released and which modules have upgraded
3. **Given** a module violating standards, **When** compliance report is generated, **Then** specific violations are listed with remediation guidance
4. **Given** a standards upgrade with an active grace period, **When** an already-installed module has not yet migrated, **Then** the violation is reported without enforcing the new standard against it until the grace period expires
5. **Given** a standards upgrade with an active grace period, **When** a new module does not meet the standards enforced for new installations, **Then** its installation is rejected
6. **Given** an installed module that still violates upgraded standards when its grace period expires, **When** enforcement runs, **Then** that module and its dependents are unavailable while the core and unaffected modules remain available
7. **Given** a module has an undeclared external business route or a Domain/Application dependency on prohibited infrastructure, **When** certification runs, **Then** the module fails with the violated Gateway or Dependency Inversion boundary identified
8. **Given** the platform evaluates API Gateway products, **When** it records the selection decision, **Then** an ADR evaluates the applicable platform criteria, treats Kong as a candidate rather than a hard dependency, and records the selected product without introducing product-specific business contracts
9. **Given** a module declares a persistence owner and boundary, **When** certification evaluates its manifest and implementation, **Then** the owner, migration authority, access boundary, and any derived-state source are identifiable and foreign persistence dependencies are rejected
10. **Given** a generated feature has CI coverage results and required test results, **When** its quality gate runs, **Then** it rejects any constitutional coverage threshold or required contract, architecture, integration, or end-to-end test that fails, even when aggregate coverage is high.

**Traceability**: Scenario 1 → FR-035, FR-037; SC-009. Scenario 2 → FR-034, FR-038; SC-019. Scenario 3 → FR-037; SC-009. Scenarios 4–6 → FR-039; SC-019. Scenario 7 → FR-075, FR-087–FR-088; SC-041–SC-047. Scenario 8 → FR-080–FR-081; SC-049. Scenario 9 → FR-108, FR-111, FR-115–FR-116; SC-052, SC-062, SC-065–SC-066. Scenario 10 → FR-121; SC-073.
---

### User Story 8 - Developer Accesses Developer Portal for Documentation and Examples (Priority: P2)

A developer needs a central location for platform documentation, API references, module examples, and troubleshooting guides.

**Why this priority**: Developer experience is important for adoption but initial documentation can be in markdown files. Formal portal improves navigation.

**Independent Test**: Can navigate to portal, search for documentation, find API examples, and access module templates.

**Acceptance Scenarios**:

1. **Given** the developer portal, **When** developer searches for "event publishing", **Then** relevant documentation and code examples are returned
2. **Given** the API reference section, **When** developer views the Event Bus API, **Then** endpoints, schemas, and usage examples are documented
3. **Given** the portal, **When** developer clicks "Create New Module", **Then** step-by-step tutorial and template links are presented
4. **Given** an authorized developer, **When** they create or manage API credentials in the developer portal, **Then** the platform applies the change within their permitted tenant scope
5. **Given** the documentation and developer portals are ready for release, **When** they are evaluated against WCAG 2.2 Level AA, **Then** both portals conform to that standard
6. **Given** platform standards have changed, **When** a developer consults the portal, **Then** the standards documentation and its version history are available.
7. **Given** a developer uses portal search for installed modules or CLI downloads, **When** relevant results are returned, **Then** installed modules show their versions and status and CLI downloads and installation instructions are available.

**Traceability**: Scenarios 1–2 → FR-040–FR-042; SC-010–SC-011. Scenario 3 → FR-044; SC-003, SC-017. Scenario 4 → FR-045; SC-007. Scenario 5 → FR-040; SC-038. Scenario 6 → FR-034, FR-043; SC-019. Scenario 7 → FR-040, FR-047–FR-048; SC-010.
---

### User Story 9 - SDK Consumer Implements Standalone Extension Outside Core Repository (Priority: P3)

An external developer needs to build a standalone extension using the Extension SDK, ensuring it integrates seamlessly with the core platform without forking or modifying core code.

**Why this priority**: External extensibility is valuable for ecosystem growth but can be delivered after internal module patterns are established. P3 allows time to stabilize internal API contracts first.

**Independent Test**: Can create standalone extension using SDK, integrate with running platform, and verify event publishing/subscription works.

**Acceptance Scenarios**:

1. **Given** the Extension SDK npm package installed, **When** developer imports SDK and writes an extension, **Then** IDE provides autocomplete and type safety for platform APIs
2. **Given** a standalone extension using SDK, **When** the extension emits events, **Then** events are compatible with core platform event bus
3. **Given** multiple standalone extensions, **When** platform starts, **Then** all extensions load successfully and communicate via platform contracts
4. **Given** a module author uses the SDK to publish or consume events, **When** the module is validated, **Then** the SDK exposes Platform Event Bus contracts and tenant/correlation/trace metadata without exposing broker-specific clients
5. **Given** an Integration Event subscriber handles a business occurrence, **When** it executes the resulting operation, **Then** the SDK directs handling through the authoritative application capability rather than a domain or persistence shortcut
6. **Given** a standalone extension declares an external capability or provider dependency, **When** it uses the SDK, **Then** the SDK exposes platform-owned contracts and capability ports without exposing Gateway-product or provider-vendor models

7. **Given** a standalone extension uses persistence or consumes another module's information, **When** it uses the SDK, **Then** the SDK exposes only its own persistence capabilities and governed contracts/events, never another module's repository, ORM model, connection, or SQL helper

**Traceability**: Scenario 1 → FR-049, FR-054; SC-012, SC-018. Scenarios 2–5 → FR-050–FR-053, FR-060–FR-061, FR-065; SC-025, SC-028–SC-030; scenario 6 → FR-081–FR-086, FR-089; SC-045–SC-048. Scenario 7 → FR-109; SC-066.

---

### User Story 10 - System Administrator Monitors Platform Health and Module Telemetry (Priority: P3)

A system administrator needs to monitor platform health (uptime, performance), view module telemetry, and identify issues through external observability tools.

**Why this priority**: Observability improves operations but can initially use standard application logging. Formal dashboards are nice-to-have for v1.

**Independent Test**: Can use external observability tools to view platform telemetry and request traces and identify slow modules.

**Acceptance Scenarios**:

1. **Given** an external telemetry dashboard, **When** administrator views platform metrics, **Then** CPU, memory, database connections, and request latency are visible
2. **Given** a slow API request, **When** administrator traces the request, **Then** distributed trace shows which modules participated and where time was spent
3. **Given** module performance degradation, **When** telemetry alert fires, **Then** administrator receives notification with affected module and recommended actions
4. **Given** an event publication or delivery attempt, **When** an operator inspects telemetry, **Then** source/subscriber module, event identity/version, tenant context, correlation/trace identifiers, delivery attempt, and outcome are available where applicable
5. **Given** an external request passes through the Platform API Gateway, **When** an operator inspects its trace and access records, **Then** Gateway, inbound-adapter, application, and applicable downstream activity share propagated correlation and trace context without exposing credentials, secrets, or unauthorized cross-tenant data

6. **Given** a module performs persistence access or maintains a local projection, **When** an operator inspects applicable telemetry, **Then** access and projection health are attributable to the owning module and tenant without exposing credentials, secrets, or unauthorized cross-tenant data
7. **Given** a deployment's documented service objectives and capacity profile, **When** platform instances are added or removed, **Then** scaling requires no code changes and maintains those objectives.
8. **Given** a production deployment's documented data-loss and service-restoration objectives, **When** recovery is tested, **Then** the results verify those deployment-specific objectives.

**Traceability**: Scenarios 1–3 → FR-091; SC-016. Scenario 4 → FR-062; SC-030. Scenario 5 → FR-076, FR-091; SC-043. Scenario 6 → FR-102, FR-118–FR-119; SC-057, SC-069–SC-070. Scenario 7 → FR-091; SC-014. Scenario 8 → FR-112; SC-036.
---

### User Story 11 - Platform Operator Governs External API Publication (Priority: P1)

A platform operator needs to publish, update, and withdraw validated Platform Core and module APIs through one governed external entry point while preserving each module's ownership of its canonical business contract.

**Why this priority**: External API publication must be governed consistently across Core and modules without coupling business capabilities to Gateway administration.

**Independent Test**: Can register a declared module API, verify its governed route and lifecycle status, then disable the module and confirm its external business exposure is withdrawn or denied.

**Acceptance Scenarios**:

1. **Given** an active, certified module declares a supported versioned machine-readable API contract and publication metadata, **When** the operator approves external publication, **Then** the route is exposed through the Platform API Gateway and retains the module-owned request, response, and error semantics.
2. **Given** a module submits an invalid or undeclared business route, **When** publication validation runs, **Then** publication is rejected and the reason is observable.
3. **Given** a module API version or its authentication, authorization, tenant, compatibility, or observability requirements have not passed validation, **When** publication is requested, **Then** the route is not made externally available.
4. **Given** a published module is disabled, suspended, withdrawn, uninstalled, expired, unsupported, or non-compliant, **When** its lifecycle transition completes, **Then** its route is withdrawn or disabled and the outcome is observable; no route is reported active beyond the governed availability of its capability.
5. **Given** route activation or withdrawal fails or is only partially applied, **When** the operator inspects lifecycle status, **Then** the operation is not reported as successfully complete and any remaining exposure is identified for governed protection or reconciliation.
6. **Given** deployment architecture requires a directly reachable health, readiness, or liveness endpoint, **When** the exception is governed, **Then** it exposes no business operation, business-state mutation, business authority, or unauthorized tenant data.
7. **Given** the Gateway applies edge authentication and traffic policy, **When** an application capability lacks valid operation-specific authorization or tenant context, **Then** the capability fails closed rather than treating Gateway acceptance as authorization.
8. **Given** an API route is updated, **When** the Gateway publishes it, **Then** only supported versions that passed contract and compatibility checks are externally exposed and route, traffic, correlation, and trace outcomes are observable.
9. **Given** an external request targets a published API, **When** applicable edge policies are evaluated, **Then** authentication integration, traffic policy, rate limiting, quotas, request-size constraints, abusive-traffic protections, CORS, access logging, metrics, and context propagation are applied without embedding business rules in Gateway configuration.
10. **Given** the Gateway control plane is unavailable while data-plane routes remain active, **When** an external consumer calls a previously validated route for an available capability, **Then** the data plane may continue using its last successfully validated configuration, no new or changed route or contract version is published or activated, and the application denies operations for disabled or unavailable capabilities; the discrepancy and recovery are observable.
11. **Given** a module declares a new external API capability whose mandatory contract or architecture tests have not passed, **When** publication is requested, **Then** the Gateway does not create, publish, or activate its route and the failed or missing gate is observable.

**Traceability**: Scenario 1 → FR-071–FR-073; SC-039–SC-040. Scenario 2 → FR-072, FR-075, FR-088, FR-090; SC-040–SC-041. Scenario 3 → FR-073, FR-076, FR-078, FR-090; SC-040, SC-042. Scenarios 4–5 → FR-078, FR-088, FR-090; SC-042, SC-051. Scenario 6 → FR-075; SC-041. Scenario 7 → FR-077, FR-090; SC-043–SC-044. Scenario 8 → FR-076, FR-078, FR-090–FR-091; SC-043, SC-051. Scenario 9 → FR-076, FR-091; SC-043. Scenario 10 → FR-078, FR-091; SC-051. Scenario 11 → FR-078, FR-090; SC-044, SC-051.
---

### User Story 12 - External Consumer Uses a Topology-Independent API (Priority: P1)

An external consumer needs to access a supported Platform Core or module capability through a stable canonical contract without knowing where or how the module is deployed.

**Why this priority**: Consumers must remain independent of internal module locations as the platform evolves from a modular monolith toward independently deployed services.

**Independent Test**: Can call a published canonical capability before and after a supported module topology change without learning internal hosts, ports, service-discovery names, or process boundaries.

**Acceptance Scenarios**:

1. **Given** a module API is published through the Platform API Gateway, **When** an external consumer invokes it, **Then** the consumer uses the canonical contract and does not address an internal module route or hostname.
2. **Given** a module moves from an in-process deployment to an independently deployed service without a breaking contract change, **When** the consumer invokes the supported API version, **Then** the external contract and route remain usable without requiring knowledge of the new deployment topology.
3. **Given** the consumer uses MCP, CLI, GUI, SDK, or automation, **When** it invokes a capability, **Then** it enters the governed canonical application capability and cannot use Gateway-provider administration or Gateway acceptance to bypass application authorization.
4. **Given** a state-changing operation is contractually retry-safe, **When** the same request is retried according to that contract, **Then** its business effect is not repeated and the duplicate outcome follows the contract.
5. **Given** concurrent updates use conflicting resource versions or equivalent concurrency conditions, **When** both are submitted, **Then** the conflicting update does not silently overwrite the accepted update and its conflict or stale-state error follows the contract.
6. **Given** a duplicate request is defined as an error or a state-changing request cannot be retried safely without its required operation identity, **When** the request is evaluated, **Then** the applicable duplicate or unsafe-retry error is observable through the canonical error contract without an unintended business effect.
7. **Given** a capability is exposed through more than one applicable channel, **When** cross-channel governance tests exercise the same principal, tenant, operation, and context, **Then** no channel weakens the canonical idempotency, concurrency, retry, authorization, tenant, or policy controls or bypasses its authoritative application capability.
8. **Given** a capability is exposed through MCP, **When** its MCP contract tests exercise its applicable canonical operations, including compositions, **Then** the exposure preserves their security, tenant, policy, validation, error, idempotency, concurrency, retry, audit, correlation, trace, and authoritative state-change semantics without requiring one-to-one tool-to-endpoint correspondence.
9. **Given** a request contains invalid or malicious input, **When** a governed capability validates the request or renders its output, **Then** invalid input is rejected and context-appropriate output encoding prevents injection and cross-site scripting.
10. **Given** a capability with a canonical contract is intended for MCP exposure, **When** applicable MCP compatibility or governance tests have not passed, **Then** its MCP tools, resources, and prompts remain unavailable.
11. **Given** a capability is exposed through API and CLI but has no GUI, **When** its channel gates run, **Then** API and CLI are validated and no GUI implementation is required.
12. **Given** a channel attempts to expose a capability before applicable authorization, tenancy, idempotency, concurrency, or architecture gates pass, **When** certification runs, **Then** exposure through that channel is rejected without a privileged bypass.
13. **Given** a canonical capability and all mandatory applicable gates have passed, **When** an approved channel is activated, **Then** the capability becomes available through that channel with its canonical semantics preserved.
14. **Given** an exposed capability changes its canonical contract or governance requirements, **When** the change requires revalidation, **Then** the changed exposure is not activated until all applicable gates pass.
15. **Given** an exposed capability's eligibility is invalidated by a failed, missing, expired, or stale mandatory gate, **When** its governed lifecycle is evaluated, **Then** new publication or activation is denied, existing exposure is disabled, withdrawn, or reconciled under the lifecycle and outage rules, and the capability is not reported as successfully available while mandatory gates remain failed.

**Traceability**: Scenarios 1–2 → FR-071, FR-075, FR-079; SC-039, SC-050. Scenario 3 → FR-077, FR-079, FR-081; SC-044. Scenarios 4–6 → FR-065, FR-090; SC-044. Scenarios 7–9 → FR-065, FR-077, FR-090; SC-044. Scenarios 10–14 → FR-065, FR-078–FR-079, FR-088, FR-090; SC-044. Scenario 15 → FR-078, FR-088, FR-090; SC-042, SC-044, SC-051.
---

### User Story 13 - Module Developer Applies Dependency Inversion (Priority: P1)

A module developer needs to build persistence, messaging, Gateway, and provider integrations against inner-owned capability ports so business policies remain independent of infrastructure and vendors.

**Why this priority**: Uniform Dependency Inversion protects Platform Core and every module from technology coupling and enables future extraction without business-logic rewrites.

**Independent Test**: Can scaffold and certify an in-process or standalone module whose Application depends on inward-owned ports implemented by infrastructure adapters, while prohibited Domain and Application imports are rejected.

**Acceptance Scenarios**:

1. **Given** an application use case requires persistence, **When** the module is certified, **Then** the use case depends on an inner-owned repository port implemented by an infrastructure adapter and has no direct concrete Prisma repository dependency.
2. **Given** an application capability publishes or consumes Integration Events, **When** dependencies are validated, **Then** it uses a platform-owned messaging port and broker clients, topology, and message models remain in adapters.
3. **Given** a provider-dependent capability such as DNS, **When** the module integrates with a provider, **Then** the port expresses platform capability semantics and the vendor-specific API or SDK remains in its adapter.
4. **Given** the platform manages Gateway publication, **When** the capability is implemented, **Then** it depends on a Platform Core-owned Gateway-management port and product-specific APIs remain in the Gateway adapter.
5. **Given** Domain code imports a framework, ORM, broker, Gateway, provider, or vendor SDK, or Application business logic imports concrete infrastructure where a port is required, **When** certification runs, **Then** certification fails and identifies the dependency violation.
6. **Given** a new or future module is scaffolded, **When** its boundaries are validated, **Then** the same inward dependency rules apply regardless of repository, operator/partner ownership, extension status, process boundary, or deployment topology.
7. **Given** a pure domain collaborator has no external technology boundary, **When** architecture validation runs, **Then** it is not required to implement an artificial interface solely to claim Dependency Inversion compliance.
8. **Given** Domain imports NestJS, Prisma, a PostgreSQL client, RabbitMQ/Kafka clients, a Gateway SDK, or a provider/vendor SDK, or Application imports a concrete Prisma repository, broker adapter, Gateway Admin API/adapter, or provider adapter where an inward-owned port is required, **When** certification runs, **Then** each prohibited dependency fails with the offending boundary identified.
9. **Given** an Application capability defines an inward-owned port and Infrastructure implements that port, **When** architecture validation checks controllers, MCP adapters, and event consumers invoking application capabilities and Gateway adapters implementing the Gateway-management port, **Then** those dependency directions pass certification.

**Traceability**: Scenarios 1–4 → FR-081–FR-086, FR-088; SC-045–SC-048. Scenarios 5–8 → FR-082–FR-088; SC-045–SC-047. Scenario 9 → FR-083, FR-087–FR-089; SC-045, SC-048.

---

### User Story 14 - Module Developer Owns and Integrates Private State (Priority: P1)

A module developer needs to evolve the module's private data independently and use other modules' information without coupling to their persistence.

**Why this priority**: Explicit data ownership prevents persistence coupling and preserves independent bounded-context evolution and future extraction.

**Independent Test**: Can validate two modules that share physical database infrastructure but have separate logical persistence boundaries, exchange information only through contracts or events, and preserve supported contracts when one module is extracted.

**Acceptance Scenarios**:

1. **Given** Module A declares private persistent state, **When** it stores or changes an aggregate, **Then** its own persistence port and adapter control the state, model, invariants, schema evolution, migrations, and lifecycle.
2. **Given** Module A needs information owned by Module B, **When** it attempts direct SQL, cross-schema access, a view, database link, foreign-data wrapper, shared ORM model, repository, or persistence library, **Then** validation rejects the access and identifies the ownership boundary.
3. **Given** Module A attempts to insert, update, delete, or migrate Module B's private data or use credentials that grant such access, **When** certification runs, **Then** the attempt is rejected and Module B remains the only authoritative owner.
4. **Given** Module A requires current authoritative information from Module B, **When** an immediate result is inherent to the operation, **Then** Module A uses Module B's governed synchronous contract; a completed occurrence intended for independent reaction uses an Integration Event through the Platform Event Bus.
5. **Given** Module A consumes a versioned event from Module B, **When** it updates a local projection, **Then** the projection is owned by Module A, remains derived, preserves tenant and event context, and does not mutate Module B's authoritative state or repeat effects on duplicate delivery.
6. **Given** a projection is stale, incomplete, rebuilt, or receives an incompatible event, **When** its module contract is reviewed, **Then** the module defines applicable freshness expectations, failure behavior, replay, idempotency, reconciliation, rebuild, and health reporting without imposing a platform-wide numeric staleness target.
7. **Given** Modules A and B use one physical PostgreSQL cluster, **When** their persistence boundaries are certified, **Then** logical ownership, access control, migration authority, module identity, and access attribution remain distinct, and unauthorized cross-module access is denied.
8. **Given** Module A moves from the modular monolith to independent service and persistence deployments, **When** its supported business behavior is exercised, **Then** its Domain rules, Application use cases, canonical contracts, Integration Event contracts, and consumers remain usable without persistence knowledge.
9. **Given** the same authoritative business fact is represented in multiple modules, **When** ownership is validated, **Then** exactly one module is declared authoritative and each other copy is explicitly classified as derived state.
10. **Given** a business operation spans two private persistence boundaries, **When** its consistency requirements are specified, **Then** local transactions and governed synchronous or asynchronous contracts are used without requiring global ACID or two-phase commit by default; any exceptional distributed transaction requires an ADR and preserves ownership.
11. **Given** an AI engineering agent or other automated implementation tool that generates or modifies platform or module artifacts is asked to produce or approve a design with unresolved ownership, cross-module database or repository access, ORM-model imports or migration ownership violations, shared authoritative tables, persistence-model leakage into canonical APIs or Integration Events, derived state treated as authoritative without explicit ownership, or shared privileged runtime database credentials, **When** it evaluates each violating request, **Then** it refuses to produce or approve the implementation and reports the ownership or governance issue without inventing a persistence shortcut or tenant-boundary bypass.

**Traceability**: Scenario 1 → FR-092, FR-106, FR-110–FR-111; SC-052, SC-062, SC-066. Scenarios 2–3 → FR-093–FR-094, FR-111, FR-113, FR-115–FR-116; SC-054–SC-055, SC-062–SC-063, SC-065. Scenario 4 → FR-095; SC-056. Scenario 5 → FR-101, FR-104–FR-105, FR-117; SC-056, SC-060–SC-061, SC-064. Scenario 6 → FR-102, FR-119; SC-057, SC-069. Scenario 7 → FR-098–FR-099, FR-115; SC-058, SC-065. Scenario 8 → FR-100; SC-059. Scenario 9 → FR-096–FR-097; SC-053, SC-057. Scenario 10 → FR-103; SC-071. Scenario 11 → FR-096, FR-120; SC-053, SC-072.

---

### User Story 15 - Platform Operator Certifies Module Data Boundaries (Priority: P1)

A platform operator needs to verify authoritative ownership, least-privilege access, and module-specific data lifecycle rules before a module becomes available.

**Why this priority**: Certification makes data boundaries enforceable across in-process modules, standalone extensions, and future independently deployed services.

**Independent Test**: Can inspect ownership declarations and certify compliant modules while rejecting cross-module persistence access, ambiguous data ownership, and unsafe credentials.

**Acceptance Scenarios**:

1. **Given** Platform Core or a module declares authoritative data, **When** an operator reviews the declaration, **Then** platform metadata and module-private state have explicitly identified owners, and ambiguous ownership blocks implementation or certification.
2. **Given** a module manifest is submitted for certification, **When** its persistence boundary is evaluated, **Then** applicable ownership, migration, projection-source, lifecycle, backup/restore, and capability metadata are discoverable without secrets or dependencies on another module's persistence.
3. **Given** a module imports another module's ORM model, repository, or migration, shares authoritative business tables, directly connects to another module's database, or exposes persistence models in public contracts, **When** certification runs, **Then** it fails with the violated boundary identified.
4. **Given** several modules require reporting or search across bounded contexts, **When** the capability is certified, **Then** it uses governed contracts or explicitly derived reporting data rather than direct queries of operational private persistence.
5. **Given** a module is upgraded, uninstalled, backed up, restored, exported, archived, or deleted, **When** its lifecycle is approved, **Then** the applicable data handling is declared by the module or governing deployment policy and preserves ownership, tenant isolation, and auditability.
6. **Given** normal runtime or migration credentials are inspected, **When** access is tested, **Then** normal runtime credentials are limited to the owning module's authorized boundary and elevated migration credentials are separately governed and auditable.
7. **Given** the Platform API Gateway handles an external request, **When** the request reaches a module, **Then** the Gateway has no direct access to private module persistence and the application capability remains authoritative.
8. **Given** multiple modules share physical database infrastructure, **When** valid and violating certification fixtures are tested, **Then** compliant, separately owned logical boundaries pass and cross-boundary access or shared business ownership fails.
9. **Given** module-private or derived data has applicable security/privacy classification, retention, tenant isolation, and access controls, **When** it is projected, migrated, backed up, restored, exported, copied for analytics, archived, or placed into dead-letter handling, where applicable, **Then** the resulting data or artifact preserves those applicable requirements and is inaccessible to unauthorized modules, principals, and tenants.
10. **Given** sensitive Platform Core or module-owned data, including applicable personally identifiable information, is stored in a persistent representation, **When** it is persisted, projected, backed up, restored, exported, archived, copied for analytics, or stored in dead-letter handling, where applicable, **Then** the resulting sensitive data at rest is protected using AES-256 and preserves applicable classification, tenant isolation, and access controls.

**Traceability**: Scenario 1 → FR-096–FR-097; SC-053, SC-057, SC-070. Scenario 2 → FR-108, FR-112; SC-052, SC-066–SC-067. Scenario 3 → FR-094, FR-115–FR-117; SC-054–SC-055, SC-065. Scenario 4 → FR-114; SC-068. Scenario 5 → FR-112; SC-067. Scenario 6 → FR-099, FR-113, FR-118; SC-058, SC-063, SC-070. Scenario 7 → FR-107; SC-054, SC-065. Scenario 8 → FR-098–FR-099, FR-115; SC-058, SC-065. Scenarios 9–10 → FR-105, FR-112; SC-067.

---

### Edge Cases

- **What happens when an optional module fails validation or initialization?** System logs the error; the failed module and its dependent modules remain unavailable, while the core and unaffected modules continue operating.
- **What happens when a submission is rejected or revoked, an artifact changes, or an invalid transition is requested?** `rejected` and `revoked` are terminal, and no submission silently returns to review. A resubmission or changed approved artifact requires a new submission with fresh review and approval; unauthorized or otherwise invalid status changes are denied without mutation and audited. Exact retries follow applicable idempotency rules.
- **What happens when an approved or published submission is revoked or withdrawn?** It becomes `revoked`, loses applicable approval and availability eligibility, and is not reported available while affected exposure is disabled, withdrawn, or reconciled under governed lifecycle and pending-delivery controls. Catalog publication, certification, installation status, and route exposure are separate outcomes.
- **What happens when a tenant is suspended with pending background work?** Tenant-initiated business operations are denied; authorized background processing and maintenance may continue under the tenant's context and applicable controls. A Platform Operator may reactivate the tenant; tenant-scoped roles cannot suspend or reactivate tenants.
- **What happens when a Tenant Admin requests or attempts tenant provisioning?** A future explicitly governed child-provisioning request does not itself create a tenant or authorize creation; in v1, actual child creation requires a Platform Operator. A Tenant Admin cannot create a root tenant, and neither a parent-child relationship nor a child-administration grant confers provisioning or global administration authority.
- **What happens when initial Tenant Admin bootstrap is attempted?** A Platform Operator may bootstrap the initial Tenant Admin when none exists, including when non-admin users exist; an existing Tenant Admin prevents initial bootstrap, and tenant-scoped roles cannot perform it.
- **What happens when a tenant slug conflicts with an existing slug?** Creation or modification is rejected if the slugs match ignoring case anywhere in the deployment, regardless of tenant hierarchy.
- **What happens when a logged-out session attempts token refresh or a subsequent request?** Its refresh tokens and already-issued access tokens are rejected immediately; the user's other sessions remain usable.
- **What happens when the same email is used in multiple tenants?** Each tenant may have a separate account; sign-in requires a valid explicit tenant, and duplicate emails within one tenant are rejected ignoring case.
- **What happens when configuration is invalid?** System rejects configuration update with detailed validation error; existing configuration remains unchanged
- **What happens when two modules publish events with identical names?** Event registry enforces global uniqueness by namespace (module.EventName); collision detected at module registration
- **What happens when a module is uninstalled while events are pending or in flight?** Uninstallation remains pending until events already assigned to its subscriber are processed with at-least-once delivery; handlers then unregister gracefully.
- **What happens when a subscriber is unavailable?** Once an Integration Event is durably accepted, publication does not wait for the subscriber; delivery is retried and observable according to platform policy.
- **What happens when the publisher becomes unavailable after durable event acceptance?** The accepted Integration Event remains eligible for eventual delivery without requiring the publisher to remain available.
- **What happens when no subscriber exists at publication time?** The event can be durably accepted without subscriber discovery; the publisher does not depend on knowing its consumers, and the event is not automatically replayed to a subscriber registered later.
- **What happens when an Integration Event is delivered more than once?** Consumers assume duplicates are possible and prevent duplicate business effects through idempotent processing.
- **What happens when events arrive out of order?** No global ordering is implied; any ordering requirement MUST be declared by the applicable event contract, and consumers MUST NOT apply effects contrary to that declared requirement.
- **What happens when an envelope is malformed, lacks required tenant context, names an unknown event type, or uses an unsupported schema version?** The event is rejected from business processing, fails closed, and the validation outcome is observable.
- **What happens when a consumer repeatedly fails?** Retries and dead-letter handling follow observable platform policy; dead-lettering does not silently mark an event successfully processed.
- **What happens when a subscriber is disabled or removed while deliveries remain pending?** The subscriber's governed delivery obligation remains pending; deactivation/removal MUST NOT silently discard accepted events.
- **What happens when a module upgrade changes its supported event contracts?** Compatibility is validated before the upgraded module becomes active; unsupported required versions are rejected.
- **What happens when the same subscriber registers the same event contract more than once?** The Platform Event Bus prevents duplicate active registrations for the same module, tenant scope, and contract version.
- **What happens when an immediate synchronous contract is unavailable?** The caller receives an explicit failure; the platform MUST NOT silently replace an inherently synchronous result with an asynchronous event.
- **What happens when synchronous module contracts form a dependency cycle?** Module validation rejects the cycle.
- **What happens when a developer attempts direct cross-module repository, database, schema, private-service, infrastructure, provider, or internal-domain access?** Architecture validation rejects the dependency and identifies the violated module boundary.
- **What happens when module business logic imports a RabbitMQ or Kafka client?** Architecture validation rejects the broker-specific dependency outside the outbound infrastructure adapter boundary.
- **What happens when Tenant A's event is routed, retried, or dead-lettered under Tenant B's context?** The operation fails closed; no Tenant B principal or module can observe Tenant A's event or data.
- **What happens when a required event-triggered operation is unauthorized or fails policy validation?** The authoritative application capability denies it and records the applicable audit outcome; event delivery does not bypass governance.
- **What happens during standards version migration?** Governance reports non-compliant modules; already-installed modules have a grace period to upgrade, after which non-compliant modules and their dependents are disabled. The core and unaffected modules remain available; new installations must meet the standards enforced for new installations.
- **What happens when tenant isolation is misconfigured?** System detects and prevents writes; audit log captures all attempted violations
- **What happens when module activation succeeds but route publication fails?** Activation is not reported as externally available; the failed route outcome is observable and governed recovery is required before publication is considered complete.
- **What happens when route publication succeeds but module activation is rolled back?** The route is withdrawn or disabled; if withdrawal is incomplete, the application capability denies new business operations and the discrepancy remains observable.
- **What happens when a route-publication request is duplicated?** The platform prevents duplicate active route registrations or reports a governed conflict, and exposes the outcome.
- **What happens when two modules declare conflicting external routes?** Publication is rejected with the conflicting declarations identified; neither module gains an unmanaged alternate route.
- **What happens when a module submits an unsupported API version, invalid OpenAPI contract, or breaking contract change as compatible?** Validation rejects publication or update before the affected version is exposed.
- **What happens when a module is disabled while requests are in flight?** New requests follow the disabled capability's authorization and route-withdrawal controls; in-flight work follows the governed drain policy without extending external availability.
- **What happens when a module is removed while a route remains cached?** The cached route cannot grant business authority or bypass the unavailable application capability; stale route state is detected and observable.
- **What happens when the Gateway is temporarily unavailable?** The platform does not bypass Gateway governance through a module listener or report an unconfirmed publication or withdrawal as successful.
- **What happens when the Gateway control plane is unavailable while data-plane routes remain active?** The data plane continues routing with its last successfully validated configuration only for capabilities that remain available; route changes pause until control-plane recovery. Application capabilities fail closed for disabled or unavailable capabilities, and the discrepancy and recovery are observable.
- **What happens when route withdrawal is only partially applied?** The route remains in an observable incomplete state, the lifecycle transition is not reported complete, and authoritative application controls prevent use of a withdrawn capability.
- **What happens when identity context is missing or tenant context is missing or invalid after Gateway processing?** The application capability fails closed and records the applicable authorization outcome.
- **What happens when required correlation context is missing or trace context is malformed?** The platform applies its governed context-validation behavior, records the observability failure, and does not replace authoritative identity or tenant context with unvalidated data.
- **What happens when a directly reachable health, readiness, or liveness endpoint exposes business information or tenant data?** Validation rejects the endpoint exposure and the endpoint is not considered an allowed operational exception.
- **What happens when a module bypasses the Gateway through an alternate listener?** Architecture or certification validation rejects the unmanaged external business route.
- **What happens when Gateway configuration contains business authorization or domain rules?** Architecture validation rejects the configuration as an attempt to replace authoritative application controls.
- **What happens when Application imports a concrete persistence adapter or Domain imports a framework or vendor SDK?** Dependency Inversion validation rejects the dependency at module certification.
- **What happens when a provider adapter leaks vendor-specific models into a canonical API or Application contract?** Contract and architecture validation reject the leakage.
- **What happens when a dependency cycle forms between a port and its adapters, or Infrastructure defines a vendor-shaped port required by Application?** Architecture validation rejects the dependency direction or ownership violation.
- **What happens when a module has no externally consumable synchronous capability?** It may be registered and certified without a public API, using other governed non-public capabilities as applicable.
- **What happens when a module moves from a modular-monolith deployment to an independent service?** External consumers continue to use the supported canonical API contract and Gateway route without learning internal module locations.
- **What happens when a module's private persistence or shared physical database infrastructure is unavailable?** The affected capability reports an observable failure; another module cannot bypass the owner by accessing its storage directly.
- **What happens when a migration partially fails or references another module's state?** The owning module's migration and recovery policy applies; cross-module migration access is rejected and no other module's state is changed.
- **What happens when two modules share a physical cluster but one attempts cross-schema access or a shared business table?** Certification rejects unauthorized access or ambiguous ownership; physical co-location alone never grants access.
- **What happens when a projection receives duplicate, out-of-order, unsupported-version, or tenant-missing events?** The consumer applies only governed, tenant-aware, idempotent behavior; invalid context or incompatible versions do not create an unauthorized or authoritative effect.
- **What happens when a projection falls behind, becomes inconsistent, or its source contract is unavailable?** The module defines observable stale/unavailable behavior, replay, reconciliation, and rebuild handling; a need for current authoritative data uses the owner's synchronous contract.
- **What happens when two bounded contexts claim the same authoritative business datum?** Ownership remains unresolved and certification or specification review blocks implementation until one owner and any derived copies are declared.
- **What happens when a module is uninstalled or upgraded while its private data must be retained, exported, archived, anonymized, or deleted?** The module specification or deployment policy governs the action and preserves ownership, tenant isolation, and audit requirements; no universal lifecycle choice is implied.
- **What happens when a backup or restore covers one logical module boundary or restores stale projection state?** The restore preserves the boundary and tenant controls, and the module's projection/reconciliation policy identifies and repairs applicable lag.
- **What happens when normal runtime credentials can access another module's data or use a shared high-privilege account?** Certification rejects the access; elevated migration access remains separately governed and attributable.
- **What happens when reporting, search, or analytics requires data from several modules?** It consumes governed contracts or explicitly derived data and cannot become an undeclared operational source of truth.
- **What happens when a private schema changes but its published API and Integration Event contracts do not?** The private schema change remains owner-managed and does not silently change a consumer contract.
- **What happens when a design proposes a cross-module ACID transaction or two-phase commit?** The default design is rejected; any exception requires an explicit future ADR and cannot weaken module ownership.
- **What happens when a module attempts to write another module's Outbox or Inbox/idempotency records?** Certification rejects the write; Outbox state belongs to the publisher's local transaction and Inbox/idempotency state belongs to the consumer.

---

## Requirements

### Functional Requirements

#### Tenant Management

- **FR-001**: System MUST provision new tenants with guaranteed isolation boundaries (separate database schemas, Redis key prefixes, or equivalent). A platform-global Platform Operator MUST be the authoritative actor for root-tenant creation and initial Tenant Admin bootstrap; tenant-scoped roles MUST NOT perform either action. Initial bootstrap MUST be permitted when the tenant has no Tenant Admin and other applicable requirements are satisfied; the presence of non-admin users MUST NOT by itself prevent bootstrap. System MUST deny initial bootstrap when a Tenant Admin already exists. In v1, system MUST authorize only a Platform Operator to create a child tenant. A Tenant Admin MAY request child provisioning only through a future explicitly governed capability; the request MUST NOT itself create the child or authorize its creation. A future explicit delegated-authority policy MAY grant scoped child-creation permission after v1, but no such permission is implied by tenant membership, hierarchy, or an administrative grant for an existing child.
- **FR-002**: System MUST reject cross-tenant data access unless it is explicitly authorized through a governed parent-child tenant delegation; delegated access MUST remain within the granted scope and child tenant context.
- **FR-003**: System MUST maintain tenant metadata including name, slug, creation date, and status. Tenant slugs MUST be unique across the deployment, ignoring case, regardless of parent-child relationships; creation or modification with a conflicting slug MUST be rejected.
- **FR-004**: System MUST support tenant suspension (soft delete) with data retention for compliance periods. System MUST authorize only a platform-global Platform Operator to suspend or reactivate a tenant; tenant-scoped roles MUST NOT perform those actions. While suspended, tenant-initiated business operations MUST be denied; authorized background processing and maintenance MAY continue under the tenant's context and applicable authorization, isolation, audit, and delivery controls. Authorized management remains subject to those controls.
- **FR-005**: System MUST provide tenant context resolution middleware that extracts tenant identity from request and enforces it throughout request lifecycle

#### Identity & Access Management

- **FR-006**: System MUST support user creation with email, password (hashed with bcrypt or equivalent), and display name. Email addresses MUST be unique within each tenant ignoring case; separate tenants MAY have separate accounts with the same email address.
- **FR-007**: System MUST enforce deny-by-default role-based access control with roles Tenant Admin, User, Billing Manager, Developer, and Governance Officer. Tenant Admin manages authorized tenant-scoped capabilities; Developer uses documentation, scaffolding, event tooling, partner submissions, and their own API credentials; Governance Officer inspects tenant compliance and audit; User reads their own profile and tenant settings. Billing Manager has no billing privileges until a billing module exists. The Platform Operator has separate platform-global authority as specified in FR-001 and FR-004; tenant-scoped roles MUST NOT acquire that authority implicitly. A Tenant Admin MUST NOT grant platform-global authority to itself or another tenant role. Organization Administrator is a persona mapped in v1 to Platform Operator for tenant provisioning, suspension/reactivation, and initial Tenant Admin bootstrap, not a separate authoritative role.
- **FR-008**: System MUST issue JWT access tokens (15-minute expiry) and refresh tokens (7-day expiry, httpOnly cookies). Logout MUST invalidate refresh tokens for the current session so they cannot obtain new access tokens; the user's other sessions MUST remain usable.
- **FR-009**: System MUST validate all JWT tokens for signature, expiry, tenant membership, and applicable session status before allowing requests. After logout completes, already-issued access tokens for that session MUST be rejected immediately for subsequent requests, even if they have not expired.
- **FR-010**: System MUST support permission assignment at tenant level (users belong to exactly one tenant). Sign-in MUST resolve an explicit valid tenant before selecting the account and MUST deny attempts without a valid tenant; authentication bootstrap MUST NOT require a previously issued access token.
- **FR-011**: System MUST log all authentication events (login, logout, token refresh, failed attempts) to audit trail

#### Event Bus & Integration Events

- **FR-012**: Platform Core MUST provide the authoritative asynchronous inter-module communication mechanism through the Platform Event Bus. Its logical dependency MUST be Publishing Module → Integration Event Contract → Platform Event Bus → Messaging Infrastructure Adapter → Broker → Subscriber Module(s), never Publishing Module → Subscriber Implementation. Modules MUST publish and subscribe through the Event Bus contract rather than direct knowledge of one another; publishers MUST NOT need to know their subscribers, and subscriber availability MUST NOT be required after durable event acceptance. Modules MUST NOT depend directly on broker clients; broker-specific clients and configuration belong to infrastructure adapters. RabbitMQ is the expected initial broker; Kafka MAY be evaluated as a future alternative but MUST NOT be treated as transparently interchangeable.
- **FR-013**: Platform Core MUST enforce the existing Integration Event envelope with event identity (`event_id`, UUID), event type (`event_type`), schema version, source module, tenant identity (`tenant_id`) when tenant-scoped, aggregate/resource identity when applicable, timestamp (ISO 8601), payload (`data`), and metadata carrying correlation context and trace context. This envelope is the canonical event contract; implementations MUST NOT introduce a competing envelope.
- **FR-014**: Platform Core MUST provide at-least-once delivery for accepted events to applicable subscribers and retry delivery when subscribers are temporarily unavailable. Duplicate delivery MAY occur; consumers MUST assume duplicates and process idempotently so a duplicate does not repeat its business effect. The platform MUST NOT promise generic end-to-end exactly-once processing. Retry and terminal/dead-letter decisions MUST follow the documented, versioned event-delivery policy established for the deployment; each decision and outcome MUST be observable, and a dead-lettered event MUST NOT be reported as successfully processed. Retry thresholds and dead-letter topology are determined during planning.
- **FR-015**: System MUST support event filtering by event type, tenant, and aggregate/resource identity without weakening tenant isolation.
- **FR-016**: System MUST maintain an Event Registry documenting published Integration Event contracts with schema version, source module, compatibility information, and documentation.
- **FR-017**: System MUST enforce event versioning and compatibility validation as Integration Event schemas evolve.

#### Extension Framework & Module Registry

- **FR-018**: System MUST provide module manifest schema (module.sdd.json) specifying name, version, governed contract dependencies, permissions, Integration Events published and consumed with supported contract/schema versions, canonical synchronous contracts provided and required, and query contracts. Manifests MUST NOT expose internal implementation dependencies and MUST make cross-module contract dependencies statically discoverable and suitable for validation. Where applicable, the manifest MUST support the data-ownership declarations specified by FR-108 without exposing credentials or declaring another module's persistence as an integration dependency.
- **FR-019**: System MUST accept authorized partner extension release submissions through the platform and validate module manifests against platform standards during registration. Publication and installation MUST be rejected unless the Platform Operator has reviewed and approved the exact code artifact. The deployment MUST be able to require distinct reviewer and approver identities; when required, approval by the reviewer MUST be rejected.

  `ModuleSubmission.status` MUST be exactly `pending_review`, `approved`, `rejected`, `published`, or `revoked`. An authorized partner creates a submission in `pending_review`. The only permitted changes, each authorized by a Platform Operator through the applicable governed capability, are:
  - `pending_review → approved` after a positive review and separate positive approval bound to the exact immutable artifact digest and the applicable separation-of-duties policy.
  - `pending_review → rejected` on a negative review or approval decision.
  - `pending_review → revoked`, `approved → revoked`, or `published → revoked` for withdrawal or revocation.
  - `approved → published` on authorized catalog publication after successful manifest validation and active positive review and approval for the exact digest.

  `rejected` and `revoked` are terminal. Every other status change, including any return to `pending_review`, MUST be rejected without mutation; exact retries follow applicable idempotency rules and MUST NOT create another transition. Rejected submissions cannot become active. A partner resubmitting after rejection or revocation MUST create a new `ModuleSubmission` in `pending_review`; prior decisions and status remain immutable and are not inherited. A changed approved artifact likewise requires a new submission and fresh review and approval.

  Submission approval does not bypass certification, and certification does not bypass mandatory applicable pre-exposure gates. Catalog publication does not itself install or activate a module or expose a route. Gateway exposure remains subject to applicable contract, architecture, security, authorization, tenant, and channel gates. Revocation invalidates applicable approval and availability eligibility; affected exposure MUST be disabled, withdrawn, or reconciled under the governed lifecycle without discarding pending delivery obligations, and MUST NOT be reported available while eligibility is invalid. Withdrawal of a route or installation is a separate lifecycle outcome and does not by itself change submission status.

  Creation and every accepted status transition MUST produce immutable audit evidence containing submission and tenant IDs, actor, time, previous and new status (with no previous status for creation), artifact digest, reason and decision or supporting-evidence reference, correlation context, and applicable policy version. Unauthorized or invalid changes MUST be denied and audited. Audit records MUST NOT contain secrets.
- **FR-020**: System MUST maintain module registry (database or file) cataloguing all installed modules, their versions, and status
- **FR-021**: System MUST support module dependency resolution, including declared canonical synchronous contract dependencies, with circular dependency detection
- **FR-022**: System MUST enforce module boundaries and tenant isolation for operator-reviewed and approved module code. A module MUST NOT access another module's database or schema, repository, infrastructure or provider adapter, private/internal service, or internal domain model, and shared persistence MUST NOT serve as an implicit integration mechanism. Modules MAY depend across bounded contexts only through explicitly published, governed contracts. These boundaries apply in the modular monolith and after service extraction; they MUST NOT rely on in-process implementation coupling that requires substantial business-logic refactoring to extract a bounded context. The first release MUST NOT claim to sandbox unreviewed or untrusted code; the isolation mechanism is determined during planning.
- **FR-023**: System MUST support module lifecycle: register → validate → start → stop → unregister. Deactivation or removal MUST preserve governed event-delivery and subscription obligations for pending work. ModuleSubmission status is distinct from certification, installation/lifecycle, publication eligibility and publication status, and channel-exposure status; submission revocation triggers applicable governed reconciliation rather than silently completing those separate lifecycles.
- **FR-024**: System MUST keep the core and unaffected modules available when an optional module fails validation or startup. The failed module and its dependent modules MUST remain unavailable.

#### Module Scaffolding & Templates

- **FR-025**: System MUST provide CLI command to scaffold new modules: `sdd-cli module:scaffold --name <module_name>`
- **FR-026**: Scaffolded modules MUST include: directory structure following platform conventions, module manifest template, domain model template, Integration Event contract template, canonical synchronous contract declaration template, query interface template, test structure
- **FR-027**: Module scaffolding MUST enforce platform standards automatically (no manual compliance steps needed)
- **FR-028**: System MUST provide module update command: `sdd-cli module:update-standards` to refresh templates when platform standards change

#### Configuration Management

- **FR-029**: System MUST support configuration sources in priority order: environment variables (highest priority), configuration file (`.env` or JSON), database (lowest priority)
- **FR-030**: System MUST support configuration override per module, per environment, and per tenant
- **FR-031**: System MUST validate configuration against schema before applying
- **FR-032**: System MUST NOT require platform restart for configuration changes (hot reload for non-critical values, restart for critical infrastructure settings)
- **FR-033**: System MUST audit all configuration changes with timestamp, actor, and change reason. For non-secret settings, it MUST record before/after values; for secret-valued settings, it MUST record redacted references or versions and MUST NOT record secret values. The audit trail MUST record all sensitive operations, remain immutable, and be retained for seven years as required by the Constitution. Production secret management MUST use a governed vault or equivalent secret-management integration and enforce secret rotation policies without selecting a product.

#### Governance Module

- **FR-034**: System MUST maintain versioned platform standards (constitution, architecture guidelines, code standards)
- **FR-035**: System MUST require all modules to declare platform standards version in manifest
- **FR-036**: System MUST run governance checks: schema compatibility, Integration Event contract validation, canonical synchronous contract validation, module-boundary architecture validation, query interface validation, and naming conventions
- **FR-037**: System MUST generate compliance reports showing each module's status and any violations
- **FR-038**: System MUST maintain governance history (audit trail) tracking when standards were updated and module compliance status transitions
- **FR-039**: System MUST support a grace period for already-installed modules to upgrade to new standards before enforcement; new installations MUST meet the standards enforced for new installations without that grace period. After expiry, the system MUST disable still-non-compliant modules and their dependents while keeping the core and unaffected modules available.

#### Documentation Portal

- **FR-040**: System MUST provide searchable documentation portal with sections for architecture, API reference, module examples, and troubleshooting. The in-scope documentation and developer portals MUST conform to WCAG 2.2 Level AA.
- **FR-041**: Documentation MUST be generated from code (docstrings, JSDoc, event schemas, API endpoints) with manual markdown overrides allowed
- **FR-042**: Portal MUST display module documentation with event contracts and query interfaces
- **FR-043**: Portal MUST include platform standards documentation with version history
- **FR-044**: Portal MUST provide quickstart guide and module development tutorial

#### Developer Portal

- **FR-045**: System MUST provide developer self-service portal for creating and managing API credentials.
- **FR-046**: Developer portal MUST display module marketplace with filtering by category, language, compatibility
- **FR-047**: Developer portal MUST show installed modules with version and status
- **FR-048**: Developer portal MUST provide CLI downloads and installation instructions

#### Extension SDK

- **FR-049**: System MUST provide Extension SDK as npm package with TypeScript typings
- **FR-050**: SDK MUST expose governed Platform Core abstractions for Integration Event publishing and subscription, event metadata/context access, tenant/correlation/trace propagation, idempotent consumption, configuration access, logging, and telemetry. Delivery failures MUST be observable through platform observability. SDK business-facing contracts MUST NOT expose RabbitMQ/Kafka clients or broker-specific concepts.
- **FR-051**: SDK MUST include helper functions for creating modules from templates
- **FR-052**: SDK MUST validate Integration Event schemas at compile time and runtime and enforce supported contract/schema versions.
- **FR-053**: SDK MUST handle authoritative tenant context automatically; subscribers MUST use platform tenant context rather than infer tenant identity from business payload fields, subscriptions MUST receive only events authorized for their tenant scope, and missing or mismatched required tenant context MUST fail closed.
- **FR-054**: SDK MUST be usable by external developers building standalone extensions outside core repository

#### Inter-Module Communication Governance

- **FR-055**: System MUST select the interaction mechanism by business semantics: use a canonical synchronous contract only when the caller inherently requires an immediate result to complete its current operation; use an asynchronous Integration Event when a completed business occurrence may be handled independently without an immediate response. The platform SHOULD prefer asynchronous events where immediate temporal coupling is not inherent.
- **FR-056**: System MUST distinguish internal Domain Events from Integration Events. A Domain Event represents an occurrence within its bounded context and MUST NOT be published externally by default. When an occurrence must cross a bounded-context boundary, an explicit publication/mapping boundary MUST create the governed Integration Event.
- **FR-057**: Synchronous cross-module interaction MUST use an explicitly published, canonical, versioned Platform/Application contract. A module MUST NOT use another module's internal implementation detail as a synchronous contract or use synchronous calls merely as a shortcut around the Platform Event Bus.
- **FR-058**: An in-process adapter MAY invoke an approved application port directly without loopback HTTP when the Constitution permits it, provided it preserves the canonical capability's tenant and authentication context, authorization, policy, validation, audit, applicable idempotency and concurrency semantics, observability, correlation, and trace context. Internal invocation MUST NOT bypass governance.
- **FR-059**: For a business operation whose committed state requires an Integration Event, the platform MUST reliably coordinate committed business state with a durably recorded pending publication according to the constitutional Outbox model. Pending publications MUST be eligible for reliable eventual publication with at-least-once delivery and idempotent consumption; this MUST NOT be represented as generic end-to-end exactly-once processing.
- **FR-060**: Module SDK and event-consumer abstractions MUST enter authoritative application capabilities for event-triggered operations rather than mutate domain or persistence state through shortcuts.
- **FR-061**: Event publication and event-triggered application handling MUST preserve applicable authentication, authorization, policy evaluation, tenant isolation, and audit controls. Event handling MUST NOT bypass current or future authoritative authorization governance; missing or invalid required context MUST fail closed.
- **FR-062**: Platform observability MUST correlate the originating operation, domain occurrence, Integration Event, publication, broker delivery, and subscriber processing. Where applicable, observable records MUST identify source and subscriber modules, event identity and schema version, tenant context, correlation and trace identifiers, delivery attempt, success, retry, dead-letter outcome, and consumer failure.
- **FR-063**: Module validation and certification MUST automatically detect and reject direct cross-module private-state reads or writes, database/schema/table, ORM, repository, migration, infrastructure/provider, internal-domain, or private-service dependencies; unauthorized persistence credentials; forbidden broker-client dependencies in domain/application business logic; and asynchronous cross-module behavior that bypasses the Platform Event Bus. Validation MUST allow module-owned persistence, explicitly derived local projections, governed Integration Event publication/consumption, and approved synchronous contracts when their decision rule is satisfied. FR-115 and FR-116 define the data-boundary certification and architecture-validation cases.
- **FR-064**: Platform Core MUST expose observable lifecycle outcomes and prevent module deactivation, upgrade, or removal from silently violating governed event-delivery or subscription guarantees, including when pending deliveries exist, a subscriber is disabled, or supported event versions change.
- **FR-065**: The API-first → MCP-second → CLI/GUI principle MUST govern channel exposure. API-first MUST establish canonical operational capabilities; asynchronous Integration Events MUST govern cross-module event propagation; MCP MUST remain an agent-oriented interface to governed capabilities; CLI and GUI MUST remain presentation channels. MCP, CLI, GUI, SDK, and automation MUST NOT publish directly to broker infrastructure or bypass application capabilities. Canonical contracts MUST distinguish read-only operations from naturally idempotent state changes, state changes requiring explicit retry protection, and operations whose retry is unsafe without a stable operation or idempotency identity. Each applicable state-changing contract MUST define whether the operation is idempotent, its safe-retry semantic or protection, applicable operation and correlation identity, retry and duplicate-request behavior, concurrency semantics, behavior for conflicting concurrent mutations, and errors when safe behavior cannot be guaranteed. Where concurrent mutation is possible, the contract MUST expose or preserve an applicable concurrency semantic. Unsafe retries or missing required identities MUST NOT silently repeat a business effect. No idempotency key is required for every operation, and no implementation mechanism is selected here. Every exposed channel MUST preserve these canonical semantics.
- **FR-066**: Platform contract validation MUST include independently testable checks for Integration Event schema and version compatibility, required metadata, tenant isolation, at-least-once duplicate handling and idempotent effects, correlation and trace propagation, publisher independence from subscriber availability, retry and dead-letter behavior, authorization/policy/audit preservation, canonical synchronous contract boundaries, and forbidden cross-module implementation coupling.
- **FR-067**: Platform Core MUST prevent or reject duplicate active registrations of the same event subscription for the same module, tenant scope, and Integration Event contract version, and MUST expose the registration outcome.
- **FR-068**: Platform Core MUST NOT imply global Integration Event ordering. When an Integration Event contract declares an ordering requirement, contract validation and consumer behavior MUST ensure that out-of-order delivery does not cause effects that violate the declared requirement.
- **FR-069**: The Platform Event Bus MUST NOT backfill events accepted before a subscription becomes active to a newly registered subscriber. This rule does not remove governed retry or replay obligations for deliveries already assigned to an active subscription.
- **FR-070**: System MUST support parent-child tenant relationships. Parent-to-child administrative access MUST require explicit delegated authorization, execute within the child tenant context, and MUST NOT be implied by the parent-child relationship alone. Neither that relationship nor a grant to administer an existing child grants authority to create tenants or grants global administration authority; child-provisioning requests and creation are governed by FR-001.

#### Governed Platform API Gateway

- **FR-071**: Platform Core MUST provide a shared, governed Platform API Gateway as the authoritative external entry point for canonical business APIs exposed by Platform Core, installed modules, approved extensions, and future independently deployed modules. The Gateway MUST support modules hosted in the initial modular monolith and MUST NOT require independent module deployment. Gateway governance MUST control external exposure and MUST NOT implement module business capabilities.
- **FR-072**: Each module exposing an external synchronous capability MUST own its canonical, versioned, machine-readable API contract and its operation, request, response, business-error, compatibility, authentication, authorization, tenant, and observability semantics. REST contracts MUST use OpenAPI. The corresponding application capability MUST be exposed through a module inbound adapter; Platform Core MUST NOT redefine module business APIs as generic Core controllers.
- **FR-073**: A module manifest declaring an external synchronous API MUST list every provided canonical API contract and version, externally publishable operation, route-publication metadata, compatibility rule, authentication, authorization, tenant, and observability requirement. A manifest MUST list an operational endpoint if one is exposed and MUST list outbound capability/provider requirements if the module uses them; fields for capabilities the module does not expose or require MAY be empty. Declarations MUST describe governed capabilities and MUST NOT substitute implementation or vendor dependencies for contracts.
- **FR-074**: A module without an externally consumable synchronous capability MUST be eligible for registration and certification without a public API. It MAY operate through Integration Event consumption, scheduled or background processing, reconciliation, outbound provider operations, internal application capabilities, or other governed non-public mechanisms. Module registration MUST NOT require an artificial public API.
- **FR-075**: Externally consumable module business routes MUST be published exclusively through the governed Platform API Gateway and MUST correspond to declared canonical API contracts. Gateway configuration MUST NOT become the sole source of API business semantics. Modules MUST NOT expose unmanaged external business routes. External consumers MUST NOT depend on internal module hostnames, ports, service-discovery names, process boundaries, or deployment topology; supported canonical contracts MUST remain stable across topology changes under the applicable versioning and compatibility policy. Directly reachable health, readiness, or liveness endpoints MUST be narrowly governed and MUST NOT expose business capabilities, mutate business state, grant business authority, expose unauthorized tenant data, or bypass application controls.
- **FR-076**: For every externally published business route, the Platform API Gateway MUST support or integrate with governed route registration, update and withdrawal; supported API-version exposure; request routing; edge-authentication integration; traffic policies; rate limiting; request-size constraints; abusive-traffic protections; access logging; request/traffic metrics; and correlation and trace-context propagation. A quota MUST be enforced when the platform traffic policy assigns one; CORS MUST apply to browser-origin requests. This requirement MUST NOT define numerical rate limits, quotas, timeouts, payload limits, or route conventions.
- **FR-077**: Gateway edge authentication or successful request processing MUST NOT constitute authoritative business authorization. The Gateway MUST NOT be the sole enforcement point for application authorization, tenant or RACI authorization, business policy, domain validation, aggregate invariants, or state-transition authorization. The authoritative application capability MUST revalidate operation-specific identity, tenant, authorization, and policy context and MUST fail closed when required context is missing or invalid. Input validation MUST use allowlist-based schema, length/range, and applicable format checks; output MUST use context-aware encoding to prevent injection and cross-site scripting in alignment with OWASP ASVS.
- **FR-078**: Gateway route creation, publication and activation, publication of a new API version, and activation of a changed contract MUST wait for all mandatory applicable contract, architecture, security, authentication, authorization, tenant, policy, governance, and channel gates in FR-090, as well as version, compatibility, route metadata, observability, module-status, and certification checks. Platform Core MUST coordinate route publication and withdrawal with module and capability lifecycle, including disablement, suspension, withdrawal, uninstall, expiry, loss of support, non-compliance, and failed revalidation. Route registration, activation, update, rejection, disablement, withdrawal, and incomplete lifecycle outcomes MUST be observable; an external route MUST NOT remain governed as active after its capability is unavailable. While the control plane is unavailable and data-plane routes remain active, the data plane MAY continue routing only with its last successfully validated configuration for capabilities that remain available; route registration, update, and withdrawal MUST pause until control-plane recovery. This exception MUST NOT expose a new or changed route, new contract version, previously failed capability, or non-compliant capability without successful gate validation. The authoritative application capability MUST fail closed for a disabled or unavailable capability, and the control/data-plane discrepancy and recovery MUST be observable.
- **FR-079**: Externally invoked synchronous APIs MUST be defined by canonical API-First contracts and use the governed Gateway for external publication. Agent-relevant MCP capabilities and applicable CLI, GUI, SDK, and automation channels MUST remain consumers of canonical application capabilities under existing channel requirements. The Gateway MUST NOT replace the Platform Event Bus: asynchronous cross-module occurrences MUST use governed Integration Events through the Event Bus and MUST NOT be routed through the Gateway for infrastructure uniformity. MCP MUST NOT use Gateway-administration APIs or configuration to bypass Platform Core governance or authoritative application capabilities.
- **FR-080**: Platform Core SHOULD prefer a mature, market-standard API Gateway over a bespoke implementation unless an Architecture Decision Record (ADR) demonstrates that available products cannot meet requirements. Kong Gateway SHOULD be evaluated as an initial candidate but MUST NOT be a hard dependency; final product selection MUST be made through an ADR. The selection ADR SHOULD evaluate applicable OpenAPI, declarative configuration, container/Kubernetes, authentication, rate limiting, observability/OpenTelemetry, high-availability, lifecycle automation, configuration-as-code/GitOps, upgrade, control/data-plane, and vendor-coupling requirements. This specification MUST NOT compare or select Gateway products.

#### Dependency Inversion and Module Architecture

- **FR-081**: Gateway-management capabilities MUST depend on a Platform Core-owned application contract or port implemented by a Gateway infrastructure adapter. Domain and authoritative Application business logic MUST NOT depend on Kong or another Gateway product's Admin API, SDK, plugins, CRDs, configuration, or persistence models. Replacing the product MUST NOT require changing Domain business rules or canonical API semantics; the specification MUST NOT claim transparent interchangeability where product semantics differ.
- **FR-082**: Dependency Inversion MUST apply uniformly to Platform Core, existing and future modules, operator- and partner-developed modules, in-repository modules and standalone extensions, modules running in-process or in the modular monolith, and bounded contexts later extracted as services. High-level Domain and Application policies MUST NOT depend on low-level infrastructure or vendor implementations; source-code dependencies MUST point inward even when runtime calls travel outward through ports.
- **FR-083**: Application code MUST define the outbound ports its use cases require, and Infrastructure MUST implement those ports. Abstractions MUST be owned by the inner layer that needs them and express platform/domain capability semantics rather than vendor transport or API semantics. The specification MUST NOT require an interface for every class or artificial interfaces for pure domain collaborators without a meaningful external boundary.
- **FR-084**: Persistence MUST follow Domain/Application → inward-owned repository or persistence port → infrastructure adapter → persistence technology. Each module or bounded context MUST own its private persistent state and persistence boundary. Domain MUST NOT depend on Prisma, PostgreSQL clients, database schemas, migration frameworks, ORM-generated persistence models, or concrete repositories. Application business logic MUST NOT directly depend on concrete persistence implementations. Existing prohibitions on accessing another module's database, schema, tables, ORM, repository, or persistence implementation remain in force; FR-092–FR-106 define the ownership, access, isolation, projection, and consistency requirements.
- **FR-085**: Messaging MUST follow Application → event publication/subscription port → messaging adapter → broker. Domain and authoritative Application business logic MUST NOT depend directly on RabbitMQ/Kafka clients, broker topology, exchanges, queues, routing keys, partitions, retry/dead-letter topology, or broker-specific message models. Existing Platform Event Bus, Outbox, at-least-once, and idempotent-consumer requirements remain in force.
- **FR-086**: Provider and other external integrations MUST use capability-oriented ports owned by the appropriate inner layer and infrastructure adapters for vendor APIs or SDKs. For example, a DNS capability SHOULD use `DNSProviderPort.ensureRecord(...)`, not a vendor-shaped `InfobloxApiPort.callWapi(...)`. This applies where meaningful to DNS, Compute, Virtualization, Network, Load Balancing, Storage, Backup, Security, IPAM, certificates, secrets, identity providers, telemetry backends, cloud services, ITSM, CMDB, and other external technologies. Vendor-specific models MUST NOT leak into Domain or canonical Application contracts; stable language/runtime primitives MUST NOT require artificial abstraction.
- **FR-087**: Module scaffolding, templates, SDKs, and governance mechanisms MUST provide or support distinct Domain, Application/use-case, inbound-adapter, outbound-port, and infrastructure-adapter responsibilities, plus canonical API, Integration Event, provider contracts, and architecture tests when applicable. Scaffolding MUST also support the module-owned persistence, migration, projection, lifecycle, and data-boundary certification responsibilities in FR-110. This requirement defines responsibilities and dependency direction, not exact directory names.
- **FR-088**: Module certification and automated architecture validation MUST enforce Gateway governance, Dependency Inversion, and Module Autonomy & Data Sovereignty for Platform Core and all modules before availability. Validation MUST reject unmanaged routes; Domain imports of NestJS or other frameworks, Prisma or other ORMs, PostgreSQL clients, RabbitMQ/Kafka clients, Kong or other Gateway SDKs, and provider/vendor SDKs; Application imports of concrete Prisma repositories, RabbitMQ/Kafka adapters, Gateway Admin APIs/adapters, or Infoblox/other provider adapters where an inward-owned port is required; vendor-shaped ports owned by Infrastructure; infrastructure-specific types leaking into Domain or canonical Application contracts; and data-boundary violations specified by FR-115–FR-116. Validation MUST allow Application to define and depend on its own ports, Infrastructure adapters to implement those ports, controllers, MCP adapters, and event consumers to invoke governed application capabilities, and Gateway adapters to implement the Gateway-management port.
- **FR-089**: The Extension SDK MUST expose platform-owned API declaration/publication lifecycle, identity/tenant/correlation/trace context, messaging and provider capability ports, application/infrastructure adapter integration, and certification contracts where applicable. It SHOULD provide the data-sovereignty abstractions specified by FR-109 and MUST NOT expose Gateway-product, broker, another module's persistence, or provider-vendor models as authoritative module business abstractions.
- **FR-090**: Contract and architecture tests MUST validate, where applicable, OpenAPI validity; route-to-contract correspondence; supported version and compatibility; request/response and error-contract compatibility; route registration, update, withdrawal, and lifecycle consistency; edge-authentication integration; identity, tenant, correlation, and trace propagation; application authorization after Gateway processing; unmanaged-route rejection; absence of Gateway-specific types from canonical contracts; and the data-boundary behaviors specified by FR-117. Applicable canonical contract tests MUST verify retry-safe duplicate requests do not repeat business effects, conflicting concurrent mutations do not silently overwrite each other, and conflict, stale-state, duplicate-request, and unsafe-retry errors follow the contract. When MCP exposure exists, MCP contract tests MUST verify semantic compatibility with the canonical capability, including composed operations, and preserve applicable authentication, authorization, tenant isolation, policy and RACI authorization, validation, error, idempotency, concurrency, retry, audit, correlation, trace, and authoritative state-change semantics; MCP tools MAY compose operations and MUST NOT be required to mirror API endpoints one-to-one. Where a capability is exposed through multiple applicable channels, cross-channel governance tests MUST exercise only channels that actually expose it, including the canonical API, MCP, CLI, GUI, SDK, or automation where applicable. For the same principal, tenant, operation, and context, tests MUST verify no channel bypasses the authoritative Application capability, receives broader authorization than another channel or the canonical capability, bypasses tenant isolation, policy or RACI, idempotency or concurrency controls, directly mutates persistence or providers, or obtains a privileged execution path absent from the canonical capability. GUI or CLI implementations MUST NOT be required solely for these tests.
  A platform capability MUST NOT become available through any applicable consumer channel until all mandatory gates for that capability and channel have passed. The governed delivery sequence is resource/capability model → canonical operational contract → Application port/use case → implementation/inbound adapter → mandatory contract tests → mandatory architecture tests → applicable security and governance tests → applicable channel-specific compatibility tests → eligibility for channel exposure. The gate applies to channels that actually expose the capability, including external API through the Gateway, MCP, CLI, GUI, SDK, automation, external integrations, and any other governed inbound channel; it MUST NOT require implementation of an absent channel. Before exposure, validation MUST establish the existence, version, machine-readable validity, and applicable compatibility of the canonical contract; applicable authentication, authorization, tenant isolation, policy and RACI, validation, error, idempotency, retry, concurrency, audit, correlation, and trace semantics; module-boundary, Dependency Inversion, Module Autonomy & Data Sovereignty, provider, and persistence architecture boundaries; and applicable channel-specific contract and governance tests. MCP tools, resources, and prompts MUST NOT precede the canonical operational contract or become available before these applicable gates and MCP compatibility tests pass. CLI, GUI, SDK, automation, and other channels MUST use the validated canonical capability and preserve its applicable semantics without privileged bypass; applicable cross-channel governance tests MUST pass before release.
  A failed, missing, expired, or stale mandatory gate MUST prevent new publication or activation. Material canonical-contract or incompatible API changes, authorization or applicable RACI policy changes, tenant-enforcement changes, certification failure, architecture-boundary or security-control failure, module non-compliance with enforced standards, unsupported versions, or module/capability withdrawal or suspension MUST invalidate affected exposure eligibility and require applicable revalidation. The standards grace period in FR-039 remains applicable where an upgraded standard is not yet enforced for an already-installed module. When eligibility is invalidated, new publication or activation MUST be denied; existing exposure MUST be disabled, withdrawn, or reconciled under the governed lifecycle and outage rules in FR-078, and the capability MUST NOT be reported as successfully available while mandatory gates remain failed.
- **FR-091**: Platform Core observability MUST expose platform/module health and performance information, including CPU, memory, database connections, request latency, distributed traces, and policy-configured alerts. Platform instances MUST be scalable without code changes while maintaining the deployment's documented service objectives and capacity profile. Gateway access logs, traffic metrics, and traces MUST support correlation across the external request, Gateway, module inbound adapter, application capability, domain operation, infrastructure interaction, and applicable Integration Event publication. Validated identity, tenant, correlation, and trace context MUST be propagated without replacing it absent a governed reason. Persistence access MUST be attributable as specified by FR-118, and projection health and outcomes MUST be observable as specified by FR-102 and FR-119. Observability MUST NOT expose credentials, secrets, or unauthorized cross-tenant data. Alert thresholds and infrastructure-specific telemetry choices are determined by deployment policy, not this specification.

#### Module Autonomy & Data Sovereignty

- **FR-092**: Every module or bounded context that owns private persistent state MUST own its persistence model, inner-layer persistence ports, schema evolution, migrations, persistence invariants, authoritative mutation rules, local transaction boundaries, private-state lifecycle, module-specific persistence configuration, and data required solely for its operation. Each private-state owner MUST be explicitly identifiable through module governance and independently verifiable by platform validation; no other module may be an implicit co-owner.
- **FR-093**: Only the owning bounded context MAY authoritatively insert, update, or delete its private state, or execute migrations against it. A non-owning module MUST NOT mutate another module's private tables or records, invoke its repository as an integration shortcut, import its ORM-generated models, use ordinary runtime credentials with direct business-data access to it, or bypass its governed application capability. Cross-module business mutations MUST use the owner's governed application capability.
- **FR-094**: A module's private persistence MUST NOT be an inter-module integration or query contract. Cross-module authoritative reads MUST NOT use direct or cross-schema SQL, database links, foreign-data wrappers, shared ORM models, repositories, database views exposing another bounded context's private model, shared persistence libraries exposing business tables, or persistence optimizations that form an undeclared contract.
- **FR-095**: Cross-module operations MUST use the owner's canonical synchronous contract when an immediate authoritative result is inherently required. A completed business occurrence intended for independent reaction MUST use a versioned Integration Event through the Platform Event Bus. The Event Bus MUST NOT be used as a substitute for an inherently synchronous authoritative result.
- **FR-096**: Platform Core MAY own authoritative platform metadata, including tenant identity and platform-level tenant metadata, module registration, module identity and lifecycle, platform resource identity where defined, Gateway publication state, Event Registry state, authorization and governance metadata, certification results, global audit/evidence, and platform-level configuration. A module MAY own private state required solely by its bounded context, including business aggregates, provider mappings, reconciliation and operation state, module-specific configuration, processing cursors, Inbox/Outbox state, and local projections. These examples are not exhaustive; authoritative ownership is determined by the bounded context. When existing contracts do not establish an owner, the applicable module specification MUST resolve ownership before implementation.
- **FR-097**: Every authoritative business datum MUST have one declared authoritative owner. Multiple representations MUST NOT create undeclared dual ownership; every non-owning representation MUST be explicitly classified as derived state, such as a cache, read model, projection, analytical copy, search index, reconciliation reference, or other declared derived representation. Derived state MUST NOT silently become a second source of truth.
- **FR-098**: Database-per-module means private persistence ownership per bounded context and does not require one physical PostgreSQL server or cluster per module. Shared physical database infrastructure, including a shared PostgreSQL cluster with separate Platform Core and module-owned logical boundaries, MUST be permitted when enforceable ownership, access, and migration isolation exists. A shared public business schema owned by several modules MUST be prohibited. This specification MUST NOT select whether logical isolation uses separate databases, schemas, clusters, or physical servers.
- **FR-099**: Shared physical persistence infrastructure MUST preserve distinct logical ownership, migration authority, access controls, module credentials or equivalent enforceable identity boundaries, independent schema evolution, prevention of unauthorized cross-module reads and writes, and operational attribution of persistence access. Shared physical infrastructure MUST NOT imply shared business ownership or weaken tenant isolation.
- **FR-100**: A module's private persistence boundary MUST support extraction from a modular monolith with shared physical infrastructure to an independently deployed service with independently deployed persistence without significant changes to its Domain rules, Application use cases, canonical APIs, Integration Event contracts, or consuming modules.
- **FR-101**: Modules MAY maintain local projections when eventual consistency is acceptable. A projection MUST be owned by its consuming module. A cross-module projection maintained asynchronously MUST be populated from the source module's versioned Integration Event through the Platform Event Bus. The source module remains authoritative for the original business fact, and a consumer MUST NOT mutate that authoritative state by changing its projection.
- **FR-102**: Where applicable, a module's derived projection MUST preserve or identify its authoritative source module, source contract/event type and version, tenant, source aggregate/resource identity, event identity, last-applied version/event/checkpoint, correlation context, and trace context. The owning module's specification or plan MUST define applicable consistency expectations, stale-data behavior, replay, idempotency, reconciliation, rebuild, incompatible-version and unavailable-source behavior, and observable projection health. This requirement MUST NOT establish global numeric freshness or staleness targets.
- **FR-103**: Each owning persistence boundary MUST provide local transactional consistency. Cross-module consistency MUST use a canonical synchronous contract when an immediate authoritative result is inherent, or Integration Events and eventual consistency when a completed occurrence is propagated for independent reaction. Global ACID transactions and distributed two-phase commit MUST NOT be the default inter-module consistency mechanism. Any exceptional distributed-transaction requirement MUST be governed by an explicit future ADR and MUST NOT weaken ownership boundaries.
- **FR-104**: When an Integration Event results from a local authoritative state change, the publishing module MUST coordinate its private business-state transaction and pending Integration Event according to the existing Outbox requirements. A module MUST NOT write Outbox records into another module's private persistence. Shared Outbox infrastructure MAY exist only when transaction and event ownership remain attributable to the publisher. Inbox and idempotency state MAY be maintained privately by the consuming module; one module MUST NOT depend on or mutate another module's Inbox or idempotency records. Where applicable, private Inbox/idempotency state SHOULD preserve tenant, event or operation identity, consumer identity, processing state/outcome, replay information, and retention semantics. No specific Inbox implementation is mandated. These requirements preserve existing at-least-once delivery and idempotent-consumer rules and MUST NOT imply generic end-to-end exactly-once processing.
- **FR-105**: Module-owned private and derived state MUST preserve applicable tenant isolation. Access MUST retain authoritative tenant context; persistence adapters and module runtime credentials MUST enforce the module and tenant boundaries; projections MUST preserve source tenant context and security/privacy classification; migrations, backups, restores, exports, analytical copies, and dead-letter payloads MUST preserve applicable tenant governance, classification, retention, and access controls; and missing or invalid mandatory tenant context MUST fail closed. Shared physical infrastructure MUST NOT weaken tenant isolation. Sensitive Platform Core and module-owned data MUST be protected at rest using AES-256 as required by the Constitution, wherever applicable sensitive data is persisted, including primary and module-private persistence, local projections, backups, restore artifacts, archives, exports, analytical copies, persisted dead-letter payloads, and other persisted sensitive copies. Applicable personally identifiable information, including social security numbers and payment card data when present, MUST be encrypted under these constitutional controls. This outcome MUST preserve applicable classification, tenant isolation, retention, and access controls without requiring each Application or repository to implement encryption or selecting the protection mechanism.
- **FR-106**: Persistence dependencies MUST follow Domain/Application → module-owned Repository or Persistence Port → module Infrastructure Adapter → module-owned persistence boundary. Domain and authoritative Application logic MUST NOT depend directly on Prisma, PostgreSQL client libraries, concrete repositories, ORM-generated persistence models, database schema implementation, or another module's persistence artifacts. Infrastructure adapters MUST implement inward-owned ports whose semantics express module/domain capabilities rather than raw SQL or vendor-specific persistence behavior.
- **FR-107**: The Platform API Gateway MUST NOT query private module business tables, mutate module-private business state, execute cross-module SQL, expose database connectivity as an external API, own module business persistence, or substitute database access for canonical module APIs. Gateway-specific management persistence required by a Gateway implementation is infrastructure state and MUST remain separate from module business state.
- **FR-108**: The existing Module Manifest MUST support applicable data-ownership metadata and SHOULD declare, where applicable, persistence requirement, logical persistence owner, persistence boundary identifier, migration ownership, required persistence capabilities, local projections and their authoritative source module and source contract/event, Outbox and Inbox/idempotency requirements, retention and backup/restore classifications, uninstall data-lifecycle policy reference, and extraction-readiness metadata. A manifest MUST NOT contain passwords, connection strings, database secrets, or administrative credentials, and MUST NOT declare another module's private database, schema, repository, ORM model, or migration implementation as an integration dependency.
- **FR-109**: The Module SDK MUST support clear responsibility for module persistence ports and context, tenant-aware persistence integration, Outbox and applicable Inbox/idempotency integration, local projection ingestion and source metadata/checkpoints, lifecycle integration, architecture-test hooks, and data-ownership validation. It SHOULD provide platform-owned abstractions for these responsibilities where applicable. The SDK MUST NOT expose another module's repository, ORM models, database connection, cross-module SQL helpers, or shared business-table abstractions; it MUST reinforce governed contracts as the inter-module boundary.
- **FR-110**: Module scaffolding MUST support clear responsibilities for Domain, Application, module-owned persistence ports and infrastructure adapters, module-owned migrations, applicable Outbox and Inbox/idempotency state, local projections and reconciliation, data-lifecycle declarations, architecture tests, and data-boundary certification. This specification defines responsibilities and boundaries, not exact directory names.
- **FR-111**: Every private persistence schema change MUST have one owning bounded context and MUST be statically discoverable or otherwise verifiable by platform certification. A module MAY migrate only its own private state; it MUST NOT migrate another module's private state, package cross-module business migrations as ordinary module migrations, or require another module to import its migration implementation. Private schema evolution MUST remain independent from canonical API and Integration Event contract versioning; a private schema change MUST NOT automatically constitute a public contract change.
- **FR-112**: Each persistence-owning module or its governing deployment policy MUST define applicable backup, restore, retention, export, archive, deletion, module-upgrade, module-uninstall, and disaster-recovery behavior. Each production deployment MUST document its data-loss and service-restoration objectives and verify them through recovery tests. The applicable module specification, deployment policy, or data-classification policy MUST determine whether data is retained, archived, exported, anonymized where required, deleted, or transferred through an explicitly governed process. Lifecycle handling MUST preserve tenant isolation, auditability, ownership, and applicable security and privacy classifications; this specification MUST NOT establish one universal lifecycle choice.
- **FR-113**: Module persistence credentials MUST follow least privilege. Normal module runtime credentials MUST access only module-owned persistence boundaries required by that module; shared high-privilege database credentials MUST NOT be used for normal module execution. Administrative and migration credentials MUST be separately governed, auditable, and unavailable to ordinary runtime paths; they MUST be purpose-scoped where possible and time-bounded or dynamically issued where supported by deployment policy. Rotation follows security policy. This specification MUST NOT select a secrets-management product unless already mandated elsewhere.
- **FR-114**: Reporting, analytics, search, observability, and audit requirements MUST NOT justify uncontrolled cross-module persistence access. Cross-domain analytical needs SHOULD use governed Integration Events, dedicated read models, analytical projections, governed exports, search indexes, audit streams, or explicit reporting contracts. An aggregated analytical store MUST be classified as derived state unless explicitly assigned authoritative ownership as its own bounded context. Operational modules MUST NOT treat an analytical store as a hidden replacement for canonical module contracts.
- **FR-115**: Module certification MUST reject, at minimum, direct connection to another module's private database; queries or mutations of another module's private schema/table, including through database links, foreign-data wrappers, or private views; imports of another module's ORM model; direct invocation of another module's repository; migrations against another module's private state; shared authoritative business tables; manifests declaring another module's database as an integration dependency; shared normal-runtime superuser credentials; and private ORM entities exposed in public OpenAPI or Integration Event contracts. Certification MUST permit module-owned persistence through its own ports/adapters, governed canonical synchronous contracts, governed Integration Event consumption, explicitly derived local projections, and shared physical PostgreSQL infrastructure with enforceable logical ownership, credentials, migration authority, tenant isolation, and access boundaries.
- **FR-116**: Automated architecture validation MUST detect, where tooling permits, imports of another module's persistence package, ORM models, or migrations; repositories exported as inter-module integration mechanisms; direct cross-module database connections or unauthorized cross-schema references; shared business-table ownership; persistence implementation leaking into canonical API or Integration Event contracts; ambiguous migration ownership; local projections without a declared authoritative source or treated as authoritative without ownership declarations; and manifests declaring another module's private persistence as a dependency. Validation SHOULD integrate with existing module certification rather than create an unrelated subsystem.
- **FR-117**: Contract tests MUST verify, where applicable, that canonical APIs and Integration Events use contract models rather than ORM/persistence models; private schema changes do not silently change public contracts; authoritative cross-module reads and mutations use governed capabilities; projections update from governed contracts/events with tenant-aware and idempotent ingestion; extracted modules preserve supported external contracts; and supported module behavior does not depend on direct cross-module database access.
- **FR-118**: Persistence access MUST be operationally attributable to its owning module and, where applicable, tenant, operation, and migration identity. Applicable persistence and projection health MUST be observable through the platform's established observability controls without exposing credentials, secrets, or unauthorized tenant data.
- **FR-119**: Module specifications and certification MUST define applicable behavior for projections when source data or contracts are unavailable, events are duplicated or out of order, versions are incompatible, tenant context is missing, or projection state requires replay, reconciliation, or rebuild. Projection health and relevant failure or recovery outcomes MUST be observable; no universal numeric freshness, staleness, or recovery target is established here.
- **FR-120**: AI engineering agents and other automated implementation tools MUST refuse to implement a module persistence design when authoritative ownership is unresolved or the requested design requires a prohibited cross-module persistence dependency, unauthorized mutation, migration, tenant-boundary bypass, privileged shared runtime credentials, or private persistence models in public contracts. They MUST also refuse an undeclared projection or analytical source of authority and physical co-location used to justify persistence coupling. They MUST report the unresolved ownership or governance requirement and request an explicit platform/module contract or ADR decision rather than inventing a shared owner, direct database shortcut, or success-shaped fallback.

#### Constitutional Testing Assurance

- **FR-121**: CI MUST verify the Constitution's test-coverage targets separately: Domain and Application each at least 85%, and at least 95% for each critical Domain or Application scope; Infrastructure at least 70%; and Presentation at least 60%. Security and authorization code in critical Domain or Application scope is subject to that scope's 95% target; no blanket 95% target applies to all security or authorization code regardless of layer or classification. Every generated feature MUST include unit tests with at least 85% coverage as required by the Constitution; this unit-test requirement does not establish a separate overall code-coverage percentage. CI reports MUST identify each measured scope and coverage metric and MUST fail when any applicable target is missed. Unit, integration, contract, architecture, and end-to-end tests MUST verify applicable business rules and constitutional boundaries, including critical security and authorization paths; mandatory tests and boundary gates MUST pass independently of aggregate coverage so high aggregate coverage cannot hide untested boundaries. No new percentage is imposed on individual contract, architecture, integration, or end-to-end test types.

### Key Entities

- **Tenant**: Organization using the platform (name, deployment-wide case-insensitively unique slug, status, optional parent relationship, created_at, updated_at, isolation_root); the parent relationship does not itself confer administrative or provisioning authority.
- **User**: Tenant-specific account for an individual accessing the platform (email unique within its tenant ignoring case, password_hash, tenant_id, roles, created_at, last_login)
- **Role**: Permission grouping (name, permissions array, tenant_id or platform-wide flag); Platform Operator is platform-global and Tenant Admin is tenant-scoped. Organization Administrator is a persona mapped to Platform Operator for tenant provisioning, suspension/reactivation, and initial Tenant Admin bootstrap, not a separate role.
- **ModuleSubmission**: Tenant-scoped immutable artifact submission with submitter, artifact digest, and status `pending_review`, `approved`, `rejected`, `published`, or `revoked`; its FR-019 lifecycle is distinct from module installation, certification, publication eligibility, and exposure.
- **Module**: Installed extension (manifest, version, status, dependencies, created_at, updated_at)
- **ModuleApiContract**: Module-owned, versioned, machine-readable contract for an externally consumable synchronous capability, including its operations, request/response semantics, errors, compatibility, and applicable security/context requirements
- **GatewayRoutePublication**: Governed association between a declared module or Core API version and its external route, including publication status and lifecycle outcome; it does not define business semantics
- **CapabilityPort**: Inner-owned application boundary describing a persistence, messaging, Gateway-management, provider, or other external capability implemented by an infrastructure adapter
- **ModulePersistenceBoundary**: A module-owned logical persistence boundary with an identifiable authoritative owner, persistence port and adapter, migration authority, access controls, and lifecycle; it does not imply a particular physical database topology
- **DataOwnershipDeclaration**: Governance metadata identifying the bounded-context owner of authoritative data and explicitly classifying any non-owning representations as derived state
- **DerivedProjection**: Consumer-owned local representation of source-module facts, traceable to its source contract/event and version, tenant, source identity, and applicable event/checkpoint metadata; it is not authoritative for the source fact
- **Inbox/OutboxState**: Module-owned private delivery/idempotency state attributable to the consuming or publishing module, respectively, and coordinated according to local transaction and event-delivery requirements
- **DomainEvent**: Internal business occurrence owned by its bounded context; it is not automatically a public inter-module contract
- **IntegrationEvent**: Versioned, governed contract for a business occurrence consumed outside its originating bounded context, carried in the canonical platform event envelope
- **SynchronousContract**: Explicit, versioned Platform/Application capability contract provided or required by a module for interactions that inherently need an immediate result
- **EventSubscription**: Governed subscription for a supported Integration Event contract/version (subscriber_module_id, event_type, handler_id, tenant scope)
- **Configuration**: Environment-specific key-value pairs (key, value, scope [tenant/module/global], environment, version)
- **StandardsVersion**: Platform standards release (version, release_date, breaking_changes, migration_guide)
- **ComplianceReport**: Module compliance assessment (module_id, standards_version, violations[], timestamp)

---

## Success Criteria

### Measurable Outcomes

- **SC-001**: Tenant provisioning completes in under 10 seconds with isolation verified by automated tests, and zero conflicting tenant slugs are accepted across the deployment when compared ignoring case. In provisioning and bootstrap acceptance tests, 100% of authorized Platform Operator operations succeed when otherwise valid, including initial bootstrap with or without existing non-admin users when no Tenant Admin exists; zero unauthorized root creations, child creations, or initial Tenant Admin bootstraps succeed, and initial bootstrap is denied when a Tenant Admin already exists. A child-provisioning request alone creates no tenant and grants no creation authority.
- **SC-002**: User authentication (login → access token → API call) succeeds in under 500ms; sign-in resolves the explicitly identified tenant and accepts no duplicate email within that tenant ignoring case; a logged-out session's refresh tokens and already-issued access tokens are rejected immediately for subsequent use while the user's other sessions remain usable.
- **SC-003**: Module scaffolding generates complete module structure in under 5 seconds with zero manual configuration needed
- **SC-004**: Event publication latency, measured from a valid application publish request to durable acceptance for dispatch by the Platform Event Bus, is under 100ms (p95) in the local-development profile and under 500ms (p95) in the externally deployed profile; the thresholds are independent of broker product selection.
- **SC-005**: Platform startup with 10+ modules completes in under 30 seconds
- **SC-006**: Module isolation prevents cross-tenant data leakage, and a suspended tenant cannot initiate business operations; authorized background processing, maintenance, and tenant management remain subject to tenant context and applicable controls, with zero violations in security tests. Suspension and reactivation acceptance tests allow the Platform Operator and reject tenant-scoped roles.
- **SC-007**: RBAC enforcement prevents unauthorized access with 100% accuracy (zero security bypasses), including attempts by tenant-scoped roles to exercise platform-global tenant provisioning, suspension, reactivation, or initial Tenant Admin bootstrap authority, and attempts by a Tenant Admin to grant platform-global authority to itself or another tenant role.
- **SC-008**: Configuration changes apply without platform restart (except infrastructure changes requiring restart)
- **SC-009**: Governance compliance checks complete in under 10 seconds for 50+ modules
- **SC-010**: Developer portal search returns the expected relevant results for every query in a maintained acceptance-test set in under 1 second
- **SC-011**: At least 95% of published runnable documentation examples pass their automated verification tests
- **SC-012**: Extension SDK provides TypeScript type safety with zero uncaught errors from type violations

### Operational Outcomes

- **SC-013**: Core platform and unaffected modules remain operational when an optional module fails validation or startup; the failed module and its dependent modules remain unavailable.
- **SC-014**: Platform instances can be added or removed to scale horizontally without code changes while maintaining the deployment's documented service objectives, including its active-tenant capacity and concurrency profile
- **SC-015**: All critical and sensitive operations emit immutable audit logs, including tenant/user creation, module installation, standards changes, and applicable authentication and configuration events; audit retention is seven years.
- **SC-016**: Platform observability (logging, tracing, metrics) requires zero manual instrumentation in modules (automatic via SDK)

### Business Outcomes

- **SC-017**: Developers can progress from successful module scaffolding to first valid Integration Event accepted for publication in under 2 hours
- **SC-018**: An external partner without core-repository access can complete an operator-approved extension submission and catalog publication, verified by an end-to-end acceptance test. Lifecycle acceptance tests verify every FR-019 permitted transition, denial without mutation of every other transition, terminal rejection/revocation, new-submission resubmission, and no automatic installation, activation, or exposure.
- **SC-019**: Existing modules remain compatible with their declared platform and event contract versions during the applicable grace period; breaking standards changes are versioned and accompanied by a migration path before enforcement.

### Inter-Module Communication Outcomes

- **SC-020**: 100% of asynchronous cross-module interactions use governed, versioned Integration Event contracts through the Platform Event Bus.
- **SC-021**: Architecture validation accepts zero direct cross-module private-state, database/schema/table, repository, ORM, migration, infrastructure/provider, internal-domain, or private-service dependencies, and zero cyclic canonical synchronous contract dependencies.
- **SC-022**: 100% of accepted Integration Events satisfy the governed schema and required envelope metadata validation.
- **SC-023**: Duplicate delivery of an accepted Integration Event produces no duplicate business effect.
- **SC-024**: An originating operation can complete after durable event acceptance without synchronous availability of any subscriber.
- **SC-025**: Unauthorized cross-tenant observation or business effects through event publication, routing, retries, dead-lettering, and consumption occur zero times in validation.
- **SC-026**: 100% of Integration Event contracts and canonical synchronous contracts provided or required by modules are versioned and discoverable through governed registries/manifests, and zero duplicate active subscription registrations exist for the same module, tenant scope, and contract version.
- **SC-027**: 100% of synchronous cross-module interactions use approved canonical versioned contracts and are justified by an inherent immediate-result requirement.
- **SC-028**: Domain, application, and module business logic contain zero direct RabbitMQ/Kafka client or infrastructure dependencies where prohibited by architecture rules.
- **SC-029**: Every successful business operation requiring an Integration Event leaves its business state committed with a pending event durably recorded and eligible for reliable eventual publication under at-least-once semantics.
- **SC-030**: Event publication and subscriber processing outcomes are correlatable end-to-end with applicable source/subscriber, event/version, tenant, correlation/trace, attempt, and delivery outcome metadata; retry, failure, and dead-letter outcomes are observable.
- **SC-031**: 100% of Integration Event contracts that declare ordering requirements pass validation for out-of-order delivery without consumer effects violating those requirements.
- **SC-032**: 100% of event-triggered application operations enforce applicable authorization, policy, and audit controls; zero operations bypass those controls.
- **SC-033**: 100% of event subscribers enter governed application capabilities, with zero direct domain/persistence mutation or broker-publication shortcuts through MCP, CLI, GUI, SDK, or automation.
- **SC-034**: Newly registered subscriptions receive zero events accepted before activation; existing assigned delivery obligations remain subject to governed retry and replay handling.
- **SC-035**: 100% of parent-to-child administrative operations require an explicit delegated grant and execute in the child tenant context; zero unauthorized cross-tenant operations succeed.
- **SC-036**: Each production deployment documents its data-loss and service-restoration objectives, and recovery tests verify those deployment-specific targets.
- **SC-037**: When a deployment requires separate review and approval, zero artifacts are approved by their reviewer; every approved artifact records both reviewer and approver identities. All accepted submission creations and transitions have the immutable, attributable, secret-free FR-019 audit evidence; unauthorized or invalid changes are denied and audited.
- **SC-038**: The in-scope documentation and developer portals conform to WCAG 2.2 Level AA before release.

### Governed API Gateway and Dependency Inversion Outcomes

- **SC-039**: 100% of externally published Platform Core and module business APIs are exposed through the governed Platform API Gateway (FR-071, FR-075).
- **SC-040**: 100% of externally published module APIs correspond to declared, versioned, machine-readable canonical contracts, and 100% of REST contracts pass OpenAPI and route-correspondence validation (FR-072–FR-073, FR-090).
- **SC-041**: Module certification accepts zero unmanaged external business routes; modules with no external synchronous capability can be certified with zero artificial public APIs (FR-074–FR-075, FR-088).
- **SC-042**: Zero routes remain governed as active after the represented module/API capability has completed withdrawal, and 100% of route lifecycle outcomes are observable (FR-078, FR-090).
- **SC-043**: 100% of applicable requests preserve validated identity, tenant, correlation, and trace context across the Gateway and application boundary, without exposing credentials, secrets, or unauthorized cross-tenant data (FR-076, FR-091).
- **SC-044**: Zero business operations are authorized solely because a request passed the Gateway; missing or invalid required application identity, tenant, authorization, or policy context results in denial. Applicable security tests reject invalid input and verify context-aware output encoding against injection and cross-site scripting. Applicable canonical contract tests verify retry-safe duplicate requests, conflicting concurrent mutations, and contract-defined conflict, stale-state, duplicate, and unsafe-retry outcomes; 100% of MCP exposures pass applicable canonical semantic and governance contract tests, and 100% of capabilities exposed through multiple channels pass applicable cross-channel governance tests with zero bypasses. Before channel activation, 100% of newly exposed or materially changed capabilities pass all mandatory applicable contract, architecture, security, governance, and channel gates; zero capabilities are exposed through API, MCP, CLI, GUI, SDK, automation, external integrations, or other governed inbound channels around failed mandatory gates; and 100% of implemented channels preserve applicable canonical capability semantics. Channels that do not expose the capability are not required solely to satisfy the gate (FR-065, FR-077–FR-079, FR-088, FR-090).
- **SC-045**: 100% of Platform Core and certified current/future modules pass the same dependency-direction checks at meaningful external technology boundaries, regardless of ownership or deployment topology (FR-082, FR-088).
- **SC-046**: Zero Domain dependencies on frameworks, ORMs, brokers, Gateway products, provider SDKs, or other vendor infrastructure are accepted by certification (FR-084–FR-086, FR-088).
- **SC-047**: Zero authoritative Application dependencies on concrete persistence, messaging, Gateway, provider, or vendor implementations are accepted where an inward-owned port is required (FR-083–FR-088).
- **SC-048**: 100% of applicable persistence, messaging, Gateway, and provider integrations use inner-owned capability ports implemented by infrastructure adapters, and scaffolding/SDK/certification expose the same boundary rules (FR-083–FR-089).
- **SC-049**: 100% of Gateway product selections are recorded in an ADR, Kong is not a mandatory Domain/Application dependency, and the selection ADR evaluates applicable governed criteria (FR-080–FR-081).
- **SC-050**: A supported external API contract remains usable across a modular-monolith to independent-service topology change without requiring consumers to learn internal module locations (FR-071, FR-075, FR-079, FR-082).
- **SC-051**: 100% of route registration, activation, update, rejection, disablement, withdrawal, and incomplete lifecycle outcomes are observable; no failed lifecycle transition is reported as successful exposure or withdrawal (FR-078, FR-090–FR-091).

### Module Autonomy & Data Sovereignty Outcomes

- **SC-052**: 100% of modules owning persistent state have one explicitly identifiable owner, a private logical persistence boundary, owner-controlled persistence responsibilities, and independently verifiable ownership metadata (FR-092, FR-098–FR-099, FR-108, FR-110).
- **SC-053**: 100% of authoritative business data has exactly one declared owner; every non-owning representation is explicitly classified as derived, and no unresolved ownership ambiguity passes module certification (FR-096–FR-097, FR-115).
- **SC-054**: Unauthorized direct cross-module private-state reads or writes occur zero times, including access by the Platform API Gateway, whether modules share physical infrastructure or not (FR-093–FR-095, FR-107, FR-115–FR-116).
- **SC-055**: Certification rejects all direct SQL, cross-schema access, database links, foreign-data wrappers, shared ORM models, direct repositories, exposed private-model database views, shared persistence libraries, cross-module migrations, and shared authoritative business tables used as integration mechanisms (FR-094, FR-111, FR-115–FR-116).
- **SC-056**: 100% of cross-module authoritative reads and business mutations use the owner's governed synchronous capability when an immediate authoritative result is inherent; completed occurrences intended for independent reaction use versioned Integration Events through the Platform Event Bus (FR-095).
- **SC-057**: 100% of applicable local projections are declared derived and identify the authoritative source module, source contract/event and version, tenant, source identity, event identity, and applicable last-applied checkpoint/context (FR-097, FR-101–FR-102, FR-119).
- **SC-058**: A shared physical PostgreSQL cluster can host Platform Core and multiple module-owned logical boundaries while certification verifies distinct ownership, migration authority, credentials or equivalent identities, access controls, tenant isolation, and access attribution; zero unauthorized cross-boundary access succeeds (FR-098–FR-099, FR-105, FR-113, FR-118).
- **SC-059**: A module can move from shared physical infrastructure in the modular monolith to independent service and persistence deployments while preserving its Domain rules, Application use cases, canonical APIs, Integration Event contracts, and consuming-module behavior (FR-100).
- **SC-060**: 100% of applicable projection ingestion is tenant-aware and idempotent, and changing a consumer-owned projection never mutates the source module's authoritative business state (FR-101–FR-102, FR-105, FR-117).
- **SC-061**: 100% of module Outbox state is attributable to its publisher and coordinated with its local authoritative transaction; Inbox/idempotency state is owned by its consumer; no generic end-to-end exactly-once claim is made (FR-104).
- **SC-062**: 100% of private schema changes have one discoverable owner and only that owner may migrate the state; a private schema change does not silently alter an API or Integration Event contract (FR-111).
- **SC-063**: Normal runtime credentials have no access beyond the module's required persistence boundaries, shared normal-runtime superuser credentials are rejected, and applicable private/projection persistence access fails closed for missing or invalid tenant context (FR-099, FR-105, FR-113, FR-115).
- **SC-064**: 100% of canonical API and Integration Event contracts use public contract models rather than private ORM/persistence entities, and contract tests verify that private schema changes do not silently change those contracts (FR-117).
- **SC-065**: Certification rejects every prohibited cross-module persistence pattern in FR-115 and accepts module-owned persistence ports/adapters, governed canonical contracts, governed event consumption, explicitly derived projections, and shared physical infrastructure with enforceable logical isolation (FR-115–FR-116).
- **SC-066**: Manifests, SDK support, scaffolding, and certification make applicable module ownership, migration, projection, lifecycle, persistence capability, and extraction-readiness responsibilities discoverable without secrets or exact directory-name mandates (FR-108–FR-110).
- **SC-067**: 100% of persistence-owning modules or governing deployment policies declare applicable backup, restore, retention, export, archive, deletion, upgrade, uninstall, and disaster-recovery behavior without relying on a universal lifecycle policy; 100% of applicable projections, migrations, backups, restores, exports, analytical and archival copies, and dead-letter payloads preserve applicable security/privacy classification, tenant isolation, retention, and access controls, with zero unauthorized access by modules, principals, or tenants. Validation verifies 100% of applicable sensitive Platform Core and module-owned persisted representations, including primary and private persistence and those copies, are protected at rest using AES-256 without prescribing the mechanism (FR-105, FR-112).
- **SC-068**: Reporting, search, analytics, observability, and audit integrations use governed contracts or explicitly classified derived data; no operational module depends on direct cross-module persistence or treats an undeclared analytical store as authoritative (FR-114).
- **SC-069**: 100% of applicable projections define observable behavior for duplicate/out-of-order or incompatible events, missing tenant context, unavailable sources, stale data, replay, reconciliation, and rebuild without a platform-wide numeric freshness target (FR-102, FR-119).
- **SC-070**: 100% of applicable persistence access and projection health outcomes are operationally attributable to the owning module and, where applicable, tenant, operation, and migration identity, without exposing secrets or unauthorized tenant data (FR-099, FR-118–FR-119).
- **SC-071**: Each module's own persistence changes are locally transactional; zero cross-module interactions require global ACID transactions or distributed two-phase commit by default, and any exception requires an explicit ADR that preserves ownership boundaries (FR-103–FR-104).
- **SC-072**: In validation, 100% of AI engineering agents and other automated implementation tools that generate or modify platform or module artifacts refuse unresolved or prohibited module persistence designs and report the ownership/governance issue; zero produce or approve an implementation violating Module Autonomy & Data Sovereignty, including direct cross-module database or repository access, cross-module ORM-model imports or migration ownership violations, shared authoritative business tables, persistence-model leakage into canonical APIs or Integration Events, derived state treated as authoritative without explicit ownership, shared privileged database credentials in normal runtime paths, or tenant-boundary bypasses (FR-096, FR-120).

### Constitutional Testing Outcomes

- **SC-073**: CI verifies each constitutional target independently: Domain and Application each at least 85%, each critical Domain or Application scope at least 95%, Infrastructure at least 70%, Presentation at least 60%, and unit-test coverage for every generated feature at least 85%. Required unit, integration, contract, architecture, and end-to-end tests and applicable security/authorization boundary gates pass independently; zero failing or untested mandatory boundaries are accepted because aggregate coverage is high (FR-121).

---

## Assumptions

- **Environment Assumptions**:
  - Deployment target is containerized (Docker) environment with Kubernetes optional but desirable
  - Database is PostgreSQL; schema isolation or logical tenancy strategies are both acceptable
  - RabbitMQ is the expected initial messaging infrastructure behind platform contracts and adapters; an in-memory implementation may be used for local development behind the same abstraction
  - Persistent storage exists for configuration, audit logs, and event archive
  - Recovery objectives are defined and validated per production deployment; v1 makes no platform-wide numeric data-loss or service-restoration promise

- **Scope Boundaries**:
  - Business modules (Billing, Subscriptions, Analytics, etc.) are **explicitly out of scope** for v1; core foundation ONLY
  - Documentation and developer web portals are in scope; a general administrative dashboard is out of scope. Platform capabilities remain operable without a GUI.
  - Mobile app support is out of scope
  - Single sign-on (SSO) and OIDC integration are out of scope (JWT-only authentication in v1)
  - Advanced features like module versioning side-by-side (blue-green) are out of scope; single version per module in v1

- **Technology Assumptions**:
  - Node.js 22+ and TypeScript 5+ are the development runtime (enforced by platform)
  - NestJS with Fastify adapter is the web framework
  - Prisma ORM abstracts database access
  - Extension SDK is published as npm package
  - RabbitMQ is the expected initial broker; Kafka may be evaluated as a future alternative but is not assumed to be transparently interchangeable
  - API Gateway product selection is deferred to an ADR; Kong is an evaluation candidate, not a mandatory dependency. This specification does not compare products or select one.
  - External business APIs use governed Gateway publication; modules without externally consumable synchronous capabilities do not require a public API.

- **Security Assumptions**:
  - All communication is over TLS 1.2+ (enforced by infrastructure, not platform code)
  - Secrets (database passwords, API keys) are managed by governed infrastructure secret-management controls; platform does not store secrets
  - Audit logs are immutable and retained for 7 years for compliance

- **Data Assumptions**:
  - Tenant data is never shared or visible across tenants under any circumstances (non-negotiable)
  - Logical data ownership is per bounded context; shared physical database infrastructure is permitted only with enforceable ownership, access, migration, and tenant-isolation boundaries. Physical topology is deferred to planning/deployment architecture.
  - Platform Core owns platform metadata; modules own their authoritative private business data. Any additional copy is explicitly classified as derived unless it has its own declared authoritative bounded context.
  - Applicable data lifecycle behavior is determined by the owning module specification or governing deployment/data-classification policy; this specification selects no universal retention or uninstall behavior.
  - Active-tenant capacity and concurrency are deployment-specific; v1 sets no platform-wide tenant-count ceiling
  - Configuration data may be inherited from parent scope (global → tenant → module) unless explicitly overridden
  - Integration Event retention and archival follow governed, configurable event and deployment policies; this specification sets no universal event-retention period or module-data lifecycle choice

- **Operational Assumptions**:
  - Platform has a single deployment per organization (no multi-deployment support in v1)
  - Module installation requires administrative action (no self-service installation by regular users)
  - Module code, including partner code, must be reviewed and approved by the platform operator before installation; unreviewed code is out of scope.
  - Standards upgrades require manual migration steps for breaking changes (automated for non-breaking changes)
  - Monitoring/alerting infrastructure exists externally (platform emits logs/metrics that ops team ingests)

- **Governance Assumptions**:
  - Platform standards are maintained by core team and published as versioned releases
  - New modules must conform to standards enforced for new installations (non-compliant installations are rejected).
  - Compliance with upgraded standards is advisory for already-installed modules during the grace period; enforcement follows grace period expiry.

---

## Deliverables

This specification establishes the requirements for the Platform Core Foundation v1. Following the SDD workflow:

- ✅ **Specification complete**: User scenarios, functional requirements, success criteria, and assumptions documented
- ✅ **Specification quality checklist**: Updated for Gateway, Dependency Inversion, and Constitution v2.3.0 Module Autonomy & Data Sovereignty requirements
- [ ] **Ready for planning**: After clarifications resolved (if any)
- [ ] **Ready for implementation**: After planning and task generation

---

**Version**: 1.0
**Status**: Draft — Module Autonomy & Data Sovereignty requirements synchronized with Constitution v2.3.0
**Next Phase**: Specification Clarification (/speckit-clarify) or Planning (/speckit-plan)
