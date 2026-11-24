<!--
Sync Impact Report
Version: 2.2.0 -> 2.3.0
Modified: Core Principles; Domain Driven Design repository ownership clarification;
Governance version history. Existing principle titles are unchanged.
Added: Module Autonomy & Data Sovereignty, including ownership, isolation, projections,
lifecycle, certification, architecture testing, contract testing, and AI agent gates.
Removed: none.
Deferred: TODO(RATIFICATION_DATE) - original adoption date remains unknown. Synchronize
dependent feature specifications and other affected artifacts separately after this amendment.
-->
# Enterprise SaaS Platform — Constitution

## Project Overview

An enterprise-grade, multi-tenant SaaS platform optimized for autonomous AI implementation while maintaining strict architectural governance. The system prioritizes modularity, scalability, and maintainability for teams of 20+ engineers.

## Core Principles

### 1. Architecture Styles

- **Domain Driven Design (DDD)** — Strategic and tactical DDD with bounded contexts
- **Clean Architecture** — Strict dependency layers with inward-only dependencies
- **CQRS** — Separated command and query models with independent evolution
- **Event-Driven Architecture** — Versioned Integration Events published through the
  Platform Event Bus propagate completed business occurrences across bounded contexts;
  Domain Events remain internal unless explicitly mapped to an Integration Event
- **Modular Monolith First** — Explicit bounded contexts, microservices-ready
- **API-First → MCP-Second → CLI/GUI** — Canonical operational contracts before channel exposure
- **Dependency Inversion Principle (DIP)** — Domain and application policies depend on
  inward-owned abstractions, not infrastructure or vendor implementations; applies uniformly
  to Platform Core and all modules
- **Governed Platform API Gateway** — Platform Core governs external publication of canonical
  synchronous APIs without taking ownership of module business capabilities
- **Module Autonomy & Data Sovereignty** — Each bounded context owns its private state;
  modules integrate through governed contracts, not each other's persistence
- **Cloud Native** — Containerized, orchestration-ready, horizontally scalable

### 2. Technology Stack

**Runtime & Language:**
- Node.js 22+
- TypeScript 5+ (strict mode mandatory)

**Web Framework:**
- NestJS with Fastify Adapter

**Data & Persistence:**
- PostgreSQL (primary data store)
- Prisma ORM (abstraction layer)
- Redis (caching, sessions, rate limiting)

**Messaging & Events:**
- RabbitMQ is the expected initial message broker behind platform messaging contracts
- Kafka MAY be evaluated as a future alternative; it is not a promise of transparent
  semantic interchangeability
- Transactional Outbox and idempotent consumers support reliable at-least-once delivery

**Observability:**
- OpenTelemetry (distributed tracing)
- Structured Logging
- Correlation/Trace IDs

**Infrastructure:**
- Docker (containerization)
- Kubernetes Ready
- Environment-based configuration

## API-First → MCP-Second → CLI/GUI

### API-First

- Every platform capability MUST have a stable, versioned, documented, testable,
  authenticated, authorized, tenant-aware, and observable API contract before release
  through MCP, CLI, GUI, SDK, automation, or external integrations. The API contract is
  the canonical operational contract.
- REST MUST be the default external API style unless an Architecture Decision Record
  justifies another protocol. REST contracts MUST use OpenAPI; an approved alternative
  MUST use an equivalent machine-readable contract specification.
- Contracts MUST define authentication, authorization, tenant scope, validation, errors,
  audit, and observability. Authentication bootstrap operations MUST authenticate supplied
  credentials without requiring a previously issued access token.
- Applicable state-changing operations MUST define idempotency, concurrency, validation,
  error, audit, and retry semantics.
- API contracts MUST be independent of presentation channels and provider-specific
  implementations. Business capabilities MUST NOT exist exclusively in controllers,
  MCP servers, CLI commands, GUI components, SDKs, provider adapters, or automation scripts.

### MCP-Second

- Capabilities relevant to AI agents SHOULD be exposed through MCP so agents can use platform
  capabilities. MCP exposure MUST follow the canonical API contract and governed application
  capability.
- MCP is an agent-oriented semantic interface, not an alternative implementation of domain
  or application logic. MCP tools MAY compose platform operations and need not mirror API
  endpoints one-to-one.
- MCP servers MUST preserve authentication, authorization, tenant isolation, policy,
  validation, audit, idempotency, concurrency, observability, and state-management guarantees.
  MCP MUST NOT independently decide authorization; deterministic platform services make
  authoritative decisions.
- MCP MUST NOT call a provider or vendor API directly when an equivalent governed platform
  capability exists.

### CLI/GUI and Other Channels

- CLI, GUI, SDKs, automation, and external integrations are consumers of canonical platform
  capabilities. They MUST NOT implement authoritative business rules or privileged execution
  paths unavailable through platform contracts.
- Every channel MUST preserve platform security, tenancy, policy, audit, error, and observability
  semantics. Operational completeness MUST NOT depend on a GUI.

### Contract-First Delivery

The required delivery sequence is:

```
Resource and capability model
    → Canonical API contract
    → Application port and use case
    → API implementation / inbound adapter
    → Contract and architecture tests
    → Platform API Gateway publication
    → MCP exposure, when agent-relevant
    → CLI/GUI exposure, when required
```

In-process adapters MAY invoke application ports directly; loopback HTTP calls are not required.
Such calls MUST pass through the same authoritative validation, authentication context,
authorization, tenant isolation, policy, audit, idempotency, concurrency, and observability
mechanisms defined by the canonical contract. No internal invocation may bypass those controls.
Correlation and trace context MUST propagate from the initiating channel through execution.

## Governed Platform API Gateway

The Platform API Gateway is a first-class Platform Core capability and the authoritative
governed external entry point for canonical APIs exposed by Platform Core and installed
modules. It governs external exposure; it MUST NOT implement module business capabilities
or become a second source of business contracts.

### Module API Ownership and External Publication

- Each module MUST own the canonical API contracts for synchronous capabilities in its
  bounded context that are intended for external consumption. The module MUST version the
  contract, define its request/response and domain/application error semantics, provide a
  machine-readable contract, expose the capability through an inbound adapter, and declare
  publishable capabilities through governed platform metadata or contracts.
- REST contracts MUST use OpenAPI. No module is required to expose public HTTP endpoints.
  A module without externally consumable synchronous capabilities MAY operate through
  Integration Event consumption, scheduled or reconciliation processing, internal
  application capabilities, provider adapters, or other governed non-public mechanisms.
  Modules MUST NOT create artificial external APIs to satisfy registration requirements.
- **Module owns the API contract. Platform Core governs external API publication. The
  Platform API Gateway exposes the externally available route.** A module MUST NOT
  independently expose an unmanaged external business route that bypasses Gateway
  governance.
- Narrow health, readiness, or liveness endpoints MAY be directly reachable only when
  deployment architecture requires them and the exception is explicitly governed. They
  MUST NOT expose business capabilities or bypass application governance.
- The canonical contract and application capability remain authoritative. External
  consumers MUST NOT depend on internal module hostnames, deployment topology, process
  boundaries, or service-discovery details. Canonical external contracts SHOULD remain
  stable across topology changes under the applicable versioning and compatibility policy.
  Modular Monolith First remains in force; modules need not be independently deployed from
  the first release.

### Gateway Responsibilities and Trust Boundary

For applicable external routes, the Gateway MUST support or integrate with governed
capabilities for route publication and withdrawal, API-version exposure, request routing,
edge-authentication integration, rate limits and quotas or traffic policies, request-size
constraints, abusive-traffic protections, applicable CORS policy, access logging, traffic
metrics, and correlation and trace-context propagation. Only supported API versions
approved by platform policy MAY be exposed.

The Gateway MAY authenticate credentials or tokens at the edge, reject malformed or
unauthenticated requests, apply technical traffic policies, and propagate validated
identity, tenant, correlation, and trace context. Successful Gateway processing MUST NOT
be treated as authoritative business authorization. The Gateway MUST NOT be the sole
enforcement point for authorization, RACI authorization, tenant authorization, business
policy, domain validation, aggregate invariants, or state-transition authorization.
Authoritative application/control-plane capabilities MUST revalidate the context and
permissions applicable to each operation. They MUST fail closed when required identity,
tenant, authorization, or policy context is missing or invalid. Edge controls complement,
but do not replace, application authorization, tenant enforcement, domain invariants, and
audit.

Gateway configuration MUST NOT contain authoritative domain or business rules. A
compromised, misconfigured, or bypassed Gateway MUST NOT automatically grant business
authority to a request that reaches an application capability.

### Lifecycle, Product, and Isolation

- A module/API MUST NOT become externally available until its applicable canonical
  contract, version, compatibility, authentication, authorization, tenant, route metadata,
  observability, and platform-governance checks pass.
- Platform Core MUST be capable of disabling or withdrawing external exposure when a
  module or API version is disabled, withdrawn, uninstalled, suspended, or non-compliant.
  External route publication MUST NOT outlive the governed availability of its capability.
- The platform SHOULD prefer a mature, market-standard Gateway product over a bespoke
  implementation unless an Architecture Decision Record (ADR) demonstrates that existing
  products cannot meet platform requirements. Kong Gateway SHOULD be evaluated as an
  initial candidate; it is not mandatory. Final product selection MUST be made through an
  ADR. The selection ADR SHOULD evaluate applicable requirements such as OpenAPI support,
  declarative configuration, container/Kubernetes deployment, authentication integration,
  rate limiting, observability/OpenTelemetry, high availability, lifecycle automation,
  configuration-as-code/GitOps suitability, upgrade strategy, control/data-plane
  architecture, and vendor coupling. Product comparison is outside this Constitution
  amendment.
- Gateway management MUST use a Platform Core-owned application contract or port and a
  Gateway infrastructure adapter. Gateway-specific SDKs, APIs, plugins, CRDs,
  configuration models, administrative clients, and persistence models MUST remain within
  infrastructure/adaptation boundaries. Domain and authoritative Application business
  logic MUST NOT depend on Kong or another Gateway product. Replacing the product MUST NOT
  require changes to domain rules or canonical API semantics; the platform MUST NOT claim
  transparent interchangeability when product semantics materially differ.
- The Gateway governs externally exposed synchronous API traffic. The Platform Event Bus
  governs asynchronous Integration Event propagation. The Gateway MUST NOT replace the
  Event Bus, route Integration Events merely to unify infrastructure, or provide a
  shortcut around canonical external application capabilities. MCP MUST NOT use
  Gateway-provider administrative APIs to bypass Platform Core governance.
- Gateway tracing MUST support end-to-end correlation across the external request,
  Gateway, inbound adapter, application capability, domain operation, infrastructure
  interaction, and applicable Integration Event publication. Gateway-generated
  correlation and trace context MUST be propagated unless a governed reason requires
  otherwise. Observability MUST NOT expose credentials, secrets, or unauthorized
  cross-tenant data.

### Gateway Architecture and Contract Gates

Automated architecture and contract gates MUST verify that:

- Every externally published business API is registered through the governed Platform API
  Gateway and corresponds to a declared canonical API contract.
- Modules do not expose unmanaged external business routes; Gateway configuration is not
  the sole source of business semantics; Gateway-specific dependencies remain in
  infrastructure adapters.
- Routing preserves validated tenant and identity context and correlation and trace
  context. Disabling or withdrawing a governed module/API prevents continued unmanaged
  exposure of its route.
- Gateway enforcement cannot replace authoritative application authorization.
- Gateway publication occurs only after the required lifecycle and governance checks pass.

### Synchronous and Asynchronous Inter-Module Communication

**MODULES COMMUNICATE THROUGH CONTRACTS, NEVER THROUGH EACH OTHER'S IMPLEMENTATION.**

API-First and Event-Driven Architecture govern complementary interaction semantics:
canonical contracts govern synchronous operational capabilities; Integration Events
govern asynchronous propagation of completed business occurrences and state changes.

Use a synchronous canonical contract only when the caller inherently requires an
immediate result to complete its current operation. Such a synchronous cross-module
interaction MUST use an explicit canonical, versioned contract. Use an asynchronous
Integration Event when a business occurrence has already happened and one or more
bounded contexts may react independently. Asynchronous cross-module communication
MUST use a versioned Integration Event published through the Platform Core Event Bus
and transported through configured platform messaging infrastructure. The communication
choice MUST follow business interaction semantics, not implementation convenience. The
platform SHOULD favor asynchronous integration when an immediate result is not
inherent to the requirement.

A synchronous cross-module interaction MUST use an explicit, canonical, versioned
application/platform contract. It MUST preserve the Platform Core's authentication,
authorization, tenant isolation, policy, validation, audit, observability, correlation,
concurrency, and idempotency guarantees. A caller MUST NOT invoke another module's
internal service, repository, domain object, persistence implementation, or private API.

A synchronous contract MUST NOT be used as a shortcut for notifying other modules that
a business occurrence has completed or propagating a state change. Asynchronous
cross-module communication MUST use a versioned Integration Event published through
the Platform Core Event Bus and transported using configured platform messaging
infrastructure. A publisher MUST NOT depend on subscriber availability or know which
modules consume its event. Subscribers MUST use platform messaging contracts rather
than publisher implementations.

## Clean Architecture Layers

### Layer Hierarchy

Runtime flow: inbound channel adapter → application port/use case → domain; the application
may then use an outbound port/adapter when infrastructure is needed. This is not a source-code
dependency diagram.

Source dependencies point inward: inbound adapters depend on application contracts;
application code depends on the domain and defines the ports it needs; outbound adapters
implement those ports and depend inward. The domain depends on neither adapter.

### Dependency Rules

**Mandatory:**
- Dependencies point ONLY inward
- Higher layers depend on lower layers
- No circular dependencies permitted
- API controllers, MCP servers, CLI, GUI, SDK entry points, and automation handlers are
  inbound adapters. Persistence, brokers, provider integrations, and vendor SDKs are outbound
  adapters. Neither kind of adapter may own domain or application rules.
- Domain code MUST NOT depend on RabbitMQ, Kafka, broker clients, the Platform Event Bus
  infrastructure implementation, or messaging infrastructure.
- Application business logic MUST NOT depend directly on RabbitMQ/Kafka SDKs or broker
  infrastructure. It MAY depend on an application-owned messaging/publication port.
- Application code MAY define and use outbound event-publication or messaging ports.
  Infrastructure adapters implement those ports. Event consumers enter through explicit
  inbound adapters and application ports.
- Cross-module dependencies MUST target only explicitly published and governed contracts,
  never another module's implementation. This rule applies in a modular monolith and after
  bounded-context extraction.
- A module MUST NOT access another module's database or schema, repository, infrastructure
  implementation, provider implementation, internal domain model, or private/internal service.
  Shared persistence MUST NOT be used as an implicit integration mechanism.

**Domain Layer Prohibitions:**
Domain code MUST NOT depend on:
- NestJS or Fastify frameworks
- Prisma ORM
- PostgreSQL or Redis clients
- Message brokers (RabbitMQ/Kafka)
- External SDKs
- Third-party frameworks

**Domain Excellence:**
- Pure TypeScript (platform-agnostic)
- Business logic isolated
- Framework-agnostic entity definitions
- Testable without infrastructure

## Dependency Inversion Principle (DIP)

High-level Domain and Application policies MUST NOT depend on low-level infrastructure or
vendor implementations. Both high- and low-level components MUST depend on abstractions
owned by the appropriate inner architectural boundary. Source-code dependencies MUST point
inward; runtime calls MAY travel outward through ports without reversing source dependency
direction.

The required shape is:

```
Inbound Adapter → Application Port → Application Use Case → Domain

Domain / Application → inward-owned abstraction ← Outbound Adapter → External technology
```

Application code defines the outbound ports required by its use cases; Infrastructure
implements those ports. Infrastructure MUST NOT define a vendor-shaped interface that
forces Domain or Application to depend on it. Ports MUST express platform/domain capability
semantics, not vendor transport, API, or resource semantics. For example, prefer
`DNSProviderPort.ensureRecord(...)` over `InfobloxApiPort.callWapi(...)`.

### Uniform Scope and Technology Boundaries

DIP applies uniformly to Platform Core; existing, future, operator-developed, and
partner-developed modules; modules in the core repository or as standalone extensions;
modules deployed in the modular monolith; and bounded contexts later extracted as
independent services. No module is exempt because it currently runs in-process or alongside
Platform Core.

- **Persistence:** Domain/Application → repository or persistence port ← persistence
  adapter → Prisma/PostgreSQL. Domain MUST NOT depend on Prisma, PostgreSQL clients,
  database schemas, or ORM-generated persistence models. Application business logic MUST
  NOT directly depend on concrete persistence implementations. Infrastructure implements
  inward-owned persistence abstractions. Existing prohibitions on accessing another
  module's database, schema, tables, or repository remain in force.
- **Messaging:** Application → event publication/subscription port ← messaging adapter →
  RabbitMQ or a future broker such as Kafka. Domain/Application business rules MUST NOT
  depend directly on broker clients, topology, queue/exchange names, or broker-specific
  message models. Platform Event Bus governance remains in force.
- **Providers and external systems:** Provider-dependent capabilities (including DNS,
  Compute, Network, Storage, Load Balancing, Backup, Security, and IPAM) MUST depend on
  capability/provider ports implemented by infrastructure adapters, not vendor SDKs/APIs.
  The same rule applies where appropriate to secrets, telemetry backends, external identity,
  cloud providers, virtualization, network controllers, ITSM, CMDB/inventory, and other
  external vendor APIs.
- **API Gateway:** Platform/Application capabilities use a Platform-owned API
  publication/Gateway-management port implemented by a Gateway infrastructure adapter.
  Domain/Application MUST NOT consume Gateway-specific product APIs directly.

DIP MUST NOT be interpreted as requiring an interface for every class. Ports SHOULD be
introduced at meaningful external technology or architectural boundaries, including
persistence, messaging, Gateway management, provider/vendor APIs, secrets, external
identity, and telemetry where abstraction is required. Pure domain collaborators without
an external dependency boundary MUST NOT be wrapped in artificial interfaces solely to
claim DIP compliance. Stable language/runtime primitives do not require artificial
abstraction.

### Scaffolding, Certification, and Architecture Tests

Module scaffolding, templates, SDKs, certification, and governance mechanisms MUST enforce
DIP. New modules MUST provide or support distinct Domain, Application/use-case, inbound
adapter, outbound port, and infrastructure adapter responsibilities; canonical API
contracts, Integration Event contracts, and provider contracts MUST be present when
applicable. These are responsibility boundaries, not mandated directory names.

Before a new module becomes available, certification MUST verify DIP and reject at minimum:
framework, ORM, broker, Gateway, provider, or vendor infrastructure dependencies in
Domain; concrete Prisma repositories, broker/Gateway/provider adapters, or vendor APIs in
Application business logic where an inward-owned port is required; vendor-shaped ports
owned by Infrastructure; and infrastructure-specific models leaking into Domain or
canonical Application contracts.

Automated architecture tests MUST detect dependency-direction violations for Platform Core
and all modules, not rely only on code review. Where tooling permits, they MUST verify that
Domain has no framework/infrastructure/vendor dependencies; Application has no concrete
infrastructure/vendor dependencies where a governed port is required; Infrastructure may
depend inward and implement declared ports; inbound adapters invoke application
capabilities; outbound adapters implement inner-owned abstractions; cross-module
dependencies use governed contracts; and vendor SDKs remain within adapter boundaries.
Passing examples include an application use case depending on an inward-owned port, an
infrastructure adapter implementing that port, a controller or MCP adapter invoking an
application capability, an event consumer invoking an application capability, and a
Gateway adapter implementing the Gateway-management port.

## Module Autonomy & Data Sovereignty

Every module MUST own its private persistent state. Only the owning bounded context MAY
authoritatively mutate that state. Every authoritative business datum MUST have one declared
authoritative owning bounded context. A database, schema, table, view, ORM model, repository,
migration, database link, foreign-data wrapper, or direct SQL access MUST NOT become an
inter-module integration contract. Modules MUST communicate through governed contracts,
not through another module's persistence implementation.

These rules preserve independently evolvable bounded contexts and prevent physical
co-location from becoming hidden coupling or shared authority.

### Private State and Authoritative Ownership

Each module or bounded context MUST own and govern its persistence model, inward-owned
persistence ports and abstractions, schema evolution, migrations, private-state invariants,
authoritative mutations, local transaction boundaries, private-state lifecycle, module-specific
persistence configuration, and data required solely by that bounded context. Ownership MUST
be explicit, attributable, auditable, and suitable for automated validation.

Running in the same process or deployment, sharing a PostgreSQL cluster or ORM technology,
having the same maintainers, or participating in the modular monolith MUST NOT make a second
module an implicit co-owner. The declared owner is the source of truth; undeclared dual
authority MUST NOT exist. When ownership is ambiguous, the relevant specification or ADR MUST
identify the authoritative bounded context before implementation. Copies outside the owner
MUST be explicitly classified as derived state, such as a cache, read model, materialized or
reporting projection, analytical copy, search index, or reconciliation reference, and MUST
NOT silently become a competing source of truth.

Platform Core MAY own authoritative platform metadata, including tenant identity and
platform-level tenant metadata, module identity and registration, module lifecycle state,
constitutionally established global platform resource identity, API Gateway publication
state, Event Registry metadata, platform authorization and governance-policy metadata,
certification results, global audit and evidence, and platform-level configuration.
A module MAY own provider mappings, reconciliation state, module-specific desired and
observed state, operation state, module configuration, private aggregates, processing
cursors, idempotency records, Inbox and Outbox state, and local projections. These examples
are illustrative, not an exhaustive universal data model; authoritative ownership by
bounded context governs.

### Access, Communication, and Persistence Inversion

A non-owning module MUST NOT insert, update, or delete another module's private records;
execute its migrations; invoke its repository as an integration shortcut; import its
ORM-generated entities; use its persistence package as an integration library; obtain
ordinary runtime credentials for direct access to its business data; or bypass its
authoritative Application capability. Cross-module business mutations MUST use governed
Application capabilities and contracts.

Private persistence MUST NOT be a cross-module query interface. When an immediate
authoritative answer is inherently required, the caller MUST use a canonical synchronous
contract. When eventual consistency is acceptable, a consumer MAY maintain a local derived
projection populated by versioned Integration Events through the Platform Event Bus.
Completed business occurrences propagated asynchronously MUST use those Integration Events.

Direct SQL, cross-schema SQL, database links, foreign-data wrappers, shared ORM models,
another module's repository or private database views, shared persistence libraries exposing
business tables, another module's database connection, and another module's migration
package MUST NOT be used for cross-module business integration. A performance optimization
MUST NOT silently become an undeclared inter-module contract.

Domain and Application depend on module-owned repository or persistence ports; module
Infrastructure adapters implement those ports and access the module-owned persistence
boundary. Ports MUST express bounded-context capabilities and semantics, not raw SQL,
ORM, database, or vendor semantics. Domain and authoritative Application business logic
MUST NOT depend directly on Prisma, PostgreSQL clients, concrete repositories, ORM-generated
persistence entities, physical schema implementations, or another module's persistence
package, migrations, or database connection.

### Logical Isolation and Extraction

Logical data ownership per bounded context is mandatory; physical database deployment is
an operational and deployment decision. A shared PostgreSQL cluster or other shared physical
infrastructure MAY host distinct module-owned logical persistence boundaries when
enforceable isolation preserves distinct ownership, separate migration authority, access
controls, scoped credentials or equivalent enforceable module identities, independent schema
evolution, prevention of unauthorized cross-module reads and writes, attributable persistence
observability, tenant isolation, and future extraction capability. Shared physical
infrastructure MUST NOT imply shared authoritative business ownership. A shared public
schema containing business tables jointly owned by multiple modules MUST NOT be used.

One physical database server, PostgreSQL cluster, or database engine instance per module
is NOT required; immediate independent service deployment is NOT required. Modular Monolith
First remains in force. Each private persistence boundary MUST support evolution from shared
physical infrastructure with logically private persistence to an independently deployed
service with independently deployed persistence without significant changes to Domain
rules, Application use cases, canonical API contracts, Integration Event contracts, or
consuming modules. External consumers MUST NOT depend on database locations, schema or table
names, physical database topology, ORM entities, or internal persistence identifiers.

### Derived Projections and Consistency

The conceptual flow is source module → versioned Integration Event → Platform Event Bus →
consumer module → consumer-owned local projection. The consumer owns its projection; the
source remains authoritative for the original business fact. Changing a local projection
MUST NOT mutate the source's authoritative state. An IPAM allocation event consumed by a
DNS-owned IP projection is illustrative only; neither IPAM nor DNS is a mandatory Platform
Core module.

Where applicable, derived state MUST preserve sufficient metadata for traceability,
idempotency, reconciliation, and rebuilding. A projection SHOULD preserve or identify its
authoritative source module, source contract or event type and version, tenant identity,
source aggregate or resource identity, event identity, last applied event/version/checkpoint,
and correlation and trace context, so those operations can be verified.

Derived projections MAY be delayed, stale, incomplete, duplicated, out of order, inconsistent,
or incompatible with newer source event versions. Where relevant, module specifications or
plans MUST define consistency expectations, stale-data behavior, replay, idempotency,
reconciliation, rebuild, unavailable-source handling, incompatible-version handling, and
observable projection health. This Constitution does NOT establish universal numeric
freshness, staleness, replay, or recovery thresholds.

Transactional consistency MUST remain local to the owning module or an explicitly defined
local persistence boundary; global ACID transactions across bounded contexts are NOT
required or promised. Immediate authoritative needs use a canonical synchronous contract;
independent reactions use Integration Events and eventual consistency. Distributed two-phase
commit MUST NOT be the default inter-module consistency mechanism. Any exceptional
distributed transaction design MUST have an explicit ADR and MUST NOT weaken ownership.

### Outbox, Inbox, and Tenant Isolation

When a module changes authoritative state and publishes an Integration Event, its local
transaction atomically persists the module-private business state and module-owned pending
event, followed by reliable eventual publication, at-least-once delivery, and idempotent
consumption. The publishing module MUST own or control the Outbox records associated with
its local authoritative transaction. A module MUST NOT write pending events directly into
another module's private Outbox. Shared Outbox infrastructure MAY provide support, but
transaction ownership, event ownership, tenant attribution, and source-module attribution
MUST remain attributable to the publishing bounded context. Generic end-to-end exactly-once
claims MUST NOT be made.

A consuming module MAY maintain private Inbox or idempotency state, which belongs to that
consumer. A module MUST NOT depend on another module's Inbox or idempotency records.
Where applicable, this state SHOULD preserve tenant identity, event or operation identity,
consumer identity, processing state and outcome, replay information, and retention
semantics to support safe deduplication and recovery. No particular Inbox implementation
is mandated.

Where applicable, private-state access MUST carry authoritative tenant context, persistence
adapters MUST enforce tenant boundaries, local projections MUST preserve source tenant
context, and migrations, backups, restores, exports, and analytical copies MUST preserve
tenant controls and boundaries. Missing or invalid mandatory tenant context MUST fail closed.
Shared physical infrastructure and co-location of different tenants MUST NOT weaken tenant
isolation or grant cross-tenant authority.

### Gateway, Migrations, Lifecycle, and Credentials

The Platform API Gateway MUST NOT query private module business tables, mutate private
module business state, execute cross-module SQL, expose database connectivity as a business
capability, own module business persistence, or substitute database access for module-owned
canonical APIs. Gateway product management state, when required, is infrastructure state
and MUST remain separate from module business state.

Every migration affecting private business state MUST have one owning bounded context.
A module MAY migrate its own private state but MUST NOT migrate another module's private
state, package cross-module business migrations as ordinary module migrations, or require
another module to import its migration implementation. Migration ownership MUST be
statically discoverable or otherwise verifiable through certification. Private schema
evolution and public contract evolution MUST remain separate: a private schema change MUST
NOT automatically become a canonical API, Integration Event, or consumer-visible contract
change.

Each persistence-owning module or its governing deployment/data policy MUST define
applicable backup, restore, retention, export, archive, deletion, module upgrade, module
uninstall, and disaster recovery classification behavior. The applicable module
specification, deployment policy, or data policy MUST determine whether private state is
retained, archived, exported, anonymized where required, deleted, or transferred through a
governed process. Lifecycle handling MUST preserve ownership, tenant isolation, auditability,
security classification, and privacy classification. No universal retention or uninstall
policy is imposed by this principle.

Database credentials MUST follow least privilege. Normal module runtime credentials MUST
provide access only to the module-owned persistence boundary required for that module;
shared high-privilege database credentials MUST NOT be used by normal execution across
modules. Administrative and migration credentials MUST be separately governed, auditable,
unavailable to ordinary runtime paths, purpose-scoped where possible, and time-bounded or
dynamically issued where supported by deployment policy.

### Reporting, Security, and Privacy

Reporting, analytics, search, observability, and audit MUST NOT justify uncontrolled
cross-module database access. Cross-domain analytical use cases SHOULD consume governed
data products or contracts, including Integration Events, dedicated read models, analytical
projections, governed exports, search indexes, audit streams, or explicit reporting contracts,
to retain attributable ownership and access governance. An aggregated analytical store
MUST be treated as derived state unless explicitly assigned authoritative ownership as a
separate bounded context. Operational modules MUST NOT use it as a hidden replacement for
authoritative module contracts.

Private and derived data MUST preserve platform security, privacy, and classification
requirements. Private-state access MUST be authenticated where applicable, authorized,
tenant-scoped, auditable, observable, least-privilege, and protected in transit and at rest
according to platform policy. Backups, exports, projections, analytical copies, dead-letter
payloads, and restore artifacts MUST preserve applicable data and privacy classifications,
tenant isolation, retention, and access controls. Projection copying MUST NOT remove the
source data's security or privacy classification.

### Manifests, SDKs, and Scaffolding

Module manifests MUST support applicable data-ownership metadata without exposing secrets.
Where applicable, a manifest SHOULD declare the persistence requirement, logical owner,
persistence-boundary reference, migration ownership, required persistence capabilities,
local projections and each external projection's authoritative source and source contract
or Integration Event, Outbox and Inbox/idempotency requirements, retention and backup/restore
classifications, uninstall data-lifecycle policy reference, and extraction-readiness metadata,
so governance can validate the module's declared boundaries and lifecycle.
Manifests MUST NOT contain database passwords, connection strings, secret tokens, or
administrative credentials, or declare another module's private database, schema,
repository, ORM, or migration implementation as an integration dependency.

Module SDKs and new scaffolding MUST support clear responsibility for Domain, Application,
module-owned persistence ports, persistence adapters, module-owned migrations, applicable
Outbox and Inbox/idempotency integration, applicable local projections and reconciliation,
data lifecycle declarations, architecture tests, and data-ownership validation. Exact
directory names are NOT mandated. SDK abstractions MUST NOT expose another module's
repository, ORM entities, database connection, cross-module SQL helpers, or shared
authoritative business tables as inter-module conveniences.

### Certification, Architecture, and Contract Gates

Before a module becomes available, certification MUST reject direct access to another
module's private database, schema, or tables; imports of another module's ORM model;
invocation of its repository; migrations against its private state; shared authoritative
business tables; another module's database declared as an integration dependency; shared
cross-module DB superuser credentials in normal runtime; and private ORM entities leaking
into canonical APIs or Integration Events.

Certification MUST permit conforming module-owned persistence through an owned port and
adapter, canonical synchronous contract invocation, Integration Event consumption,
explicitly derived local projections, and a shared PostgreSQL cluster with enforceable
logical ownership, separate migration authority, access and tenant isolation, and scoped
credentials.

Automated architecture validation MUST detect, where technically possible, imports of
another module's persistence package or ORM-generated entity; references to another
module's migration artifacts; repositories exported as inter-module interfaces; direct
cross-module database connections; unauthorized cross-schema access; ambiguous shared
business-table ownership or migration ownership; private persistence types leaking into
canonical API or Integration Event contracts; projections without a declared authoritative
source; and manifests declaring another module's private persistence as a dependency.
These gates apply to in-repository modules, standalone extensions, operator- and
partner-developed modules, modules in the modular monolith, and independently deployed
services.

Contract tests MUST verify, where applicable, that canonical APIs expose contract models
and Integration Events expose versioned event schemas rather than ORM entities; private
schema changes do not silently alter public contracts; authoritative cross-module reads
use governed contracts and mutations use governed Application capabilities; local
projections consume governed contracts and events with tenant-aware, idempotent ingestion;
extracted modules preserve supported contracts; and supported module behavior does not
depend on direct cross-module database access.

### AI Agent Governance for Data Sovereignty

AI agents MUST detect and refuse direct access by one module to another module's database,
schema, tables, ORM entities, repository, or migration-owned private state; shared
authoritative business tables; views, links, foreign-data wrappers, or cross-schema queries
used to bypass contracts; shared database infrastructure used as an implicit integration API;
private persistence models leaking into canonical APIs or Integration Events; ordinary
runtime paths using shared cross-module privileged database credentials; and physical
co-location used to justify logical coupling.

Agents MUST also refuse a projection treated as authoritative without explicit ownership
transfer or an analytical/reporting store becoming an undeclared operational source of
truth. Agents MUST require explicit ownership resolution when multiple modules appear to
claim authority over a business datum. Agents MUST prefer a canonical synchronous contract
or Integration Event plus local projection, as appropriate to the interaction semantics,
over direct cross-module persistence access.

## Domain Driven Design

### Strategic DDD

**Bounded Contexts** (Initial Set):
1. **Tenant Context** — Multi-tenancy model, tenant isolation, tenant hierarchy
2. **Identity & Access Context** — Users, roles, permissions, JWT/refresh tokens
3. **Subscription Context** — Plans, subscriptions, lifecycle, renewals
4. **Billing & Payments Context** — Invoices, payments, refunds, tax calculation
5. **Audit Context** — Audit trails, compliance, change tracking

**Ubiquitous Language:**
- Establish glossaries for each bounded context
- Document strategic domain concepts
- Align terminology across teams

Each bounded context owns its internal model and implementation. A bounded context MUST
NOT expose its internal domain model as a cross-module contract. Cross-context dependencies
MUST use an explicitly versioned canonical synchronous contract or a versioned Integration
Event, according to the interaction semantics defined above.

### Tactical DDD

**Required Concepts:**

| Concept | Purpose | Location |
|---------|---------|----------|
| **Aggregate** | Consistency boundary, invariants | Domain |
| **Entity** | Business-critical identity | Domain |
| **Value Object** | Immutable concept without identity | Domain |
| **Domain Service** | Cross-aggregate business logic | Domain |
| **Repository** | Persistence abstraction; implementation in Infrastructure | Domain/Application port |
| **Domain Event** | Business occurrence notification | Domain |
| **Factory** | Complex aggregate construction | Domain/Application |
| **Specification** | Query predicate encapsulation | Infrastructure |

**Example Domain Model:**

```typescript
// Value Objects (immutable, no identity)
class TenantId extends BrandedType<'TenantId', string> {}
class UserId extends BrandedType<'UserId', string> {}
class Email extends ValueObject<{ value: string }> {}
class Money extends ValueObject<{ amount: Decimal; currency: string }> {}

// Entities (identity, mutable)
class User implements Entity {
  id: UserId;
  email: Email;
  tenantId: TenantId;
  roles: Set<Role>;
}

// Aggregates (consistency boundary)
class Subscription implements Aggregate {
  id: SubscriptionId;
  tenantId: TenantId;
  userId: UserId;
  plan: Plan;
  status: SubscriptionStatus;

  activate(): void { /* business logic */ }
  cancel(): void { /* domain events */ }
}

// Domain Events
class SubscriptionActivatedEvent implements DomainEvent {
  id: EventId;
  aggregateId: SubscriptionId;
  timestamp: Date;
  tenantId: TenantId;
}

// Domain Services (stateless, cross-aggregate)
class SubscriptionService {
  activate(subscription: Subscription): void {}
  renew(subscription: Subscription): void {}
}

// Repository port (Domain/Application; implementation in Infrastructure)
interface SubscriptionRepository {
  save(subscription: Subscription): Promise<void>;
  findById(id: SubscriptionId): Promise<Subscription | null>;
}
```

**Anti-Patterns to Avoid:**
- Primitive Obsession (use Value Objects)
- Anemic Domain Models (models without behavior)
- Domain logic in repositories or use cases
- Unnecessary DDD complexity for simple CRUD

## CQRS (Command Query Responsibility Segregation)

### Separation of Concerns

**Command Model** — Write operations, state changes:
```
Command → Validation → Handler → Repository → Domain → Event
```

**Query Model** — Read operations, projections:
```
Query → Handler → Projection → ReadModel/Database
```

### Application Layer Structure

```
Application/
├── Commands/
│   ├── CreateTenantCommand.ts
│   ├── ActivateSubscriptionCommand.ts
│   └── CreateUserCommand.ts
├── Queries/
│   ├── GetTenantQuery.ts
│   ├── ListInvoicesQuery.ts
│   └── GetUserQuery.ts
├── Handlers/
│   ├── CreateTenantHandler.ts
│   └── GetTenantHandler.ts
├── DTOs/
│   ├── CreateTenantDTO.ts
│   └── TenantResponseDTO.ts
├── Services/
│   ├── TenantApplicationService.ts
│   └── SubscriptionApplicationService.ts
└── Events/
    ├── IntegrationEvent.ts
    └── DomainEventPublisher.ts
```

### CQRS Benefits

1. **Independent Scaling** — Read and write models scale separately
2. **Optimization** — Each model optimized for its use case
3. **Auditability** — Command audit trail explicit
4. **Eventually Consistent** — Acceptable denormalization

### Read Model Synchronization

- **Outbox Pattern** — Atomically persist business state and pending Integration Events;
  consumers update read models idempotently from at-least-once delivery
- **Event Handlers** — Asynchronous projection builders
- **Eventual Consistency** — Clients accept short delays

## Multi-Tenancy

### Fundamental Rules

**Mandatory:**
- Every business operation executes within a tenant context
- Tenant data leakage is strictly forbidden
- Tenant isolation is enforced at every layer

### Tenant Isolation Mechanisms

| Layer | Mechanism | Example |
|-------|-----------|---------|
| **API** | Tenant middleware resolver | Extract from JWT, subdomain, header |
| **Database** | Tenant-aware queries | WHERE tenant_id = $1 |
| **Application** | Tenant context injection | TenantContext in request scope |
| **Authorization** | Tenant-based rules | RBAC within tenant boundary |

### Multi-Tenant Entities

**Tenant-Scoped** (must have tenant_id):
- User
- Subscription
- Invoice
- Workspace
- Audit Log

**Global Entities** (shared across tenants, explicitly marked):
- Plan (shared SaaS plans)
- Feature (shared feature catalog)
- Locale/Region (reference data)

### Implementation Pattern

```typescript
// Middleware: Resolve tenant from request
@Injectable()
class TenantMiddleware implements NestMiddleware {
  use(req: Request, res: Response, next: NextFunction) {
    const tenantId = extractTenantId(req); // JWT, subdomain, header
    TenantContext.setTenantId(tenantId);
    next();
  }
}

// Repository: Enforce tenant isolation
@Injectable()
class UserRepository {
  async findById(userId: UserId): Promise<User | null> {
    const tenantId = TenantContext.getTenantId();
    return this.prisma.user.findUnique({
      where: { id: userId, tenantId }, // ALWAYS filter by tenant
    });
  }
}

// Guard delegates channel checks; the application enforces authoritative authorization
@UseGuards(TenantGuard)
@Controller('api/invoices')
class InvoiceController {
  constructor(private query: GetInvoiceQuery) {}

  @Get(':id')
  async getInvoice(@Param('id') invoiceId: string) {
    // The application also authorizes the operation within the request tenant.
    return this.query.execute(invoiceId);
  }
}
```

## Authentication & Authorization

### Authentication

**Strategy:** JWT with Refresh Tokens

```typescript
// Access Token (short-lived, 15min)
{
  sub: "user_123",
  tenant: "tenant_456",
  roles: ["admin"],
  iat: timestamp,
  exp: timestamp + 15min
}

// Refresh Token (long-lived, 7 days, stored in httpOnly cookie)
{
  sub: "user_123",
  tenant: "tenant_456",
  type: "refresh",
  iat: timestamp,
  exp: timestamp + 7days
}
```

### Authorization

**Current:** Role-Based Access Control (RBAC)
- Tenant Admin
- Tenant User
- Billing Manager
- Read-Only User

**Future Extensions:**
- Attribute-Based Access Control (ABAC)
- Single Sign-On (SSO)
- OpenID Connect (OIDC)
- SAML 2.0

**Rules:**
- Guards MAY perform channel-specific enforcement, but MUST NOT be the only protection.
- Authoritative authorization and policy decisions MUST reside in shared application or
  control-plane services or ports, not controllers or channel adapters.
- Every inbound channel MUST invoke the same authoritative authorization capability.
- Authorization MUST deny by default. Decorators MAY declare channel requirements.

```typescript
@UseGuards(AuthGuard, BillingGuard)
@Controller('api/invoices')
class InvoiceController {
  @Post()
  @Roles('tenant:admin', 'billing:manager')
  async createInvoice(@Body() dto: CreateInvoiceDTO) {
    return this.command.execute(dto);
  }
}
```

## Event-Driven Architecture

### Domain Events

A **Domain Event** is an immutable record of a significant business occurrence inside
its originating bounded context. It belongs to that context's domain or application
model and is not automatically a public or cross-module contract.

Domain Events MUST be immutable, timestamped, associated with their aggregate and
tenant where applicable, and contain only the minimal facts needed inside their
bounded context. The Domain layer MUST NOT depend on a message broker, broker client,
or Platform Event Bus infrastructure.

A Domain Event MUST NOT automatically become an Integration Event. When an occurrence
must cross a bounded-context boundary, an explicit application/publication boundary
MUST map it to the corresponding Integration Event contract.

### Integration Events

An **Integration Event** is an independently versioned Platform Core contract intended
for consumption outside its originating bounded context. Asynchronous cross-module
communication MUST use Integration Events through the Platform Event Bus. The event
MUST be transported by the configured platform messaging infrastructure; modules MUST
NOT publish or consume through broker-specific clients.

Integration Event contracts MUST be independent of internal domain models and MUST
preserve the applicable platform context: stable event identity, event type, schema
version, source module, tenant identity, aggregate or resource identity, timestamp,
correlation context, and trace context. Contract evolution MUST follow the versioning,
compatibility, and migration requirements in Microservices Contracts.

Publishers MUST NOT depend on subscriber availability and MUST NOT need to know which
modules consume an event. Subscribers MUST consume through platform messaging
contracts and MUST revalidate tenant context and applicable authorization. Event
delivery MUST be treated as at least once; duplicate delivery MAY occur. Consumers
MUST process idempotently so duplicate deliveries do not repeat business effects.
Messaging infrastructure MUST provide observable retry and dead-letter handling
according to platform policy. Delivery observability MUST preserve correlation and
trace context and MUST NOT expose secrets or cross-tenant data.

### Platform Event Bus

The **Platform Event Bus** is a first-class Platform Core capability and the governed
application/infrastructure boundary for Integration Events. Its contracts MUST
provide publication and subscription, event-schema validation, preservation of
versioned metadata, tenant-context enforcement, correlation and trace propagation,
retry, dead-letter handling, delivery observability, and schema evolution support.

Modules MUST depend on the Platform Event Bus contract or application port, never on
RabbitMQ, Kafka, their SDKs, or the broker adapter. Broker-specific implementation
belongs in outbound infrastructure adapters. RabbitMQ is the expected initial broker;
Kafka MAY be considered as a future alternative. Replacing a broker MUST NOT require
changes to domain business rules or Integration Event semantics, but the platform
MUST NOT claim transparent interchangeability where broker semantics materially
differ or impose a lowest-common-denominator abstraction solely to imply it.

Event consumers MUST enter through explicit inbound adapters and application ports.
No event handler may bypass authoritative application validation, authentication,
authorization, tenant isolation, policy, audit, idempotency, or observability controls.
MCP, CLI, GUI, SDK, and other inbound channels MUST NOT publish directly to
broker-specific infrastructure or bypass canonical application capabilities.

### Outbox Pattern

The Outbox Pattern atomically persists business state and pending Integration Events.
It enables reliable eventual publication and is compatible with at-least-once broker
delivery. Consumers MUST tolerate duplicates through idempotent processing; the
pattern does not guarantee generic end-to-end exactly-once processing.

```
1. Begin transaction
2. Change bounded-context state and record its Domain Event
3. Map applicable occurrences to versioned Integration Event contracts
4. Persist the state change and pending Integration Events atomically
5. Commit transaction
6. Publish pending Integration Events through the Platform Event Bus
7. Record publication outcome and retry observable transient failures
```

The Outbox Pattern MUST NOT require the Domain layer to depend on a broker. The
application/publication boundary maps internal Domain Events to Integration Events
and records them using an application port implemented by infrastructure.

## Microservices Readiness

### Design Principles

**Every bounded context SHOULD be extractable as an independently deployed service
without major business-logic refactoring.** The modular monolith MUST enforce the same
contract boundaries required after extraction; in-process implementation coupling
MUST NOT make extraction dependent on major business-logic refactoring.

### Microservices Contracts

**Explicit Boundaries:**
- Canonical API contracts MUST define synchronous operational capabilities.
- Asynchronous integration events MUST have separate versioned contracts.
- Application commands and domain events are not automatically public API contracts.
- Public DTOs and integration event schemas MUST be versioned independently of internal
  domain models. Change logs MUST be maintained.
- Breaking changes MUST use a new contract version or an explicitly governed compatibility
  and migration process; supported versions MUST be covered by compatibility tests.
- Modules MUST communicate through explicit, published contracts and MUST NOT depend on
  one another's implementation. Synchronous interactions use canonical versioned
  application/platform contracts only when an immediate result is inherently required.
  Asynchronous propagation uses independently versioned Integration Events through the
  Platform Event Bus.
- A module MUST NOT access another module's database/schema, repository, internal domain
  model, infrastructure or provider implementation, or private service/API. Shared
  persistence MUST NOT become an implicit module integration mechanism.

### Inter-Module Communication Decision

| Interaction semantics | Required mechanism |
|-----------------------|-------------------|
| Caller inherently needs an immediate result to complete its current operation | Explicit canonical, versioned synchronous application/platform contract |
| A business occurrence has completed and one or more bounded contexts may react independently | Versioned Integration Event through the Platform Event Bus and configured messaging infrastructure |

This decision is based on business semantics, not convenience. API-First governs
canonical synchronous operational capabilities; Event-Driven Architecture governs
asynchronous propagation. A synchronous interaction MUST NOT substitute for an event
when the intent is notification of a completed occurrence or independent propagation
of a state change. The platform SHOULD favor asynchronous integration when no immediate
result is inherently required.

The initial broker is RabbitMQ behind outbound infrastructure adapters. Kafka MAY be
considered later; broker-specific code MUST remain within those adapters. Do not claim
transparent broker interchangeability where semantics materially differ.

REST remains the default external synchronous API style. Another synchronous protocol,
including the previously identified future gRPC option, requires an Architecture Decision
Record and an equivalent versioned machine-readable contract; it MUST preserve the same
governance guarantees.

**Conceptual flow:**

```
Consumers → MCP / CLI / GUI / SDK / Automation
          → Canonical API Contracts
          → Application Capability → Domain
                                   ├→ synchronous result
                                   └→ Domain Event
                                      → publication boundary
                                      → versioned Integration Event
                                      → Outbox → Platform Event Bus
                                      → broker adapter → RabbitMQ
                                      → subscriber module application port
```

### Idempotency

**Requirement:** All operations must be idempotent

**Implementation:**
- Idempotency keys in request headers
- Idempotency cache (Redis)
- Deduplication in event handlers

Idempotency enforcement MUST remain authoritative across channels and handle concurrent
attempts; a channel-local cache check alone MUST NOT be treated as sufficient.

## Observability

### Structured Logging

**Mandatory Fields:**
- Timestamp (ISO 8601)
- Log Level (DEBUG, INFO, WARN, ERROR)
- Logger Name
- Message
- Correlation ID (request-scoped)
- Tenant ID (tenant-scoped)
- User ID (user-scoped)
- Context (additional business data)

**Example:**
```json
{
  "timestamp": "2025-11-22T14:30:00Z",
  "level": "INFO",
  "logger": "BillingService",
  "message": "Invoice generated",
  "correlationId": "req-12345",
  "tenantId": "tenant-456",
  "userId": "user-789",
  "invoiceId": "inv-111",
  "amount": "1500.00",
  "currency": "USD"
}
```

### Distributed Tracing

**OpenTelemetry Implementation:**
- Trace ID propagation across services
- Correlation and trace context propagation from each inbound channel through execution
- Span creation per operation
- Baggage for context propagation
- Resource attributes (service, version, environment)

**Trace Hierarchy:**
```
Trace: api-request-12345
├── Span: POST /api/invoices
│   ├── Span: ValidateInvoiceCommand
│   ├── Span: CreateInvoiceHandler
│   │   ├── Span: Save to Database
│   │   └── Span: Publish Event
│   └── Span: HTTP Response
```

### Metrics

**Golden Signals:**
- Latency (p50, p95, p99)
- Traffic (RPS, bytes/sec)
- Errors (rate, types)
- Saturation (CPU, memory, DB connections)

**Business Metrics:**
- Tenant count
- MRR (Monthly Recurring Revenue)
- Churn rate
- Invoice generation rate

## Security

### OWASP ASVS Alignment

**Input Validation:**
- Whitelist, not blacklist
- Schema validation (Zod, class-validator)
- Length/range enforcement
- Format validation (email, URL, etc.)

**Output Encoding:**
- Context-aware encoding (HTML, JSON, URL)
- Prevent XSS
- Prevent injection attacks

**Secret Management:**
- Never commit secrets
- Environment variables for local dev
- Vault integration for production (HashiCorp Vault, AWS Secrets Manager)
- Secret rotation policies

**Audit Trail:**
- Log all sensitive operations
- Immutable audit logs
- Retention: 7 years (compliance)

**Encryption:**
- TLS 1.2+ for all transport
- AES-256 for sensitive data at rest
- PII encryption (SSN, credit cards)

**Example:**
```typescript
@Post('/payments')
@UseGuards(AuthGuard)
class PaymentController {
  async processPayment(@Body() dto: ProcessPaymentDTO) {
    // Input validation (DTO validation)
    // TLS secured transmission
    // Encrypted storage of sensitive fields
    // Audit logging
    // Output encoding (JSON response)
  }
}
```

## Resilience

### Error Handling

**Error Hierarchy:**
```
Error (Generic)
├── ApplicationError (Recoverable)
│   ├── ValidationError
│   ├── AuthenticationError
│   ├── AuthorizationError
│   └── BusinessRuleError
├── DomainError (Business rules violated)
│   ├── InvalidSubscriptionStateError
│   └── InsufficientCreditsError
└── InfrastructureError (External dependencies)
    ├── DatabaseError
    └── ExternalServiceError
```

**Usage:**
```typescript
class SubscriptionService {
  activate(subscription: Subscription): void {
    if (!subscription.canActivate()) {
      throw new InvalidSubscriptionStateError('Must be in pending state');
    }

    if (subscription.isExpired()) {
      throw new BusinessRuleError('Subscription plan expired');
    }

    subscription.activate();
  }
}
```

### Resilience Patterns

| Pattern | Purpose | Implementation |
|---------|---------|-----------------|
| **Retry** | Transient failures | Exponential backoff, jitter |
| **Circuit Breaker** | Cascading failures | Open → Half-Open → Closed |
| **Timeout** | Stuck requests | Abort after deadline |
| **Bulkhead** | Resource isolation | Thread/connection pools |
| **Fallback** | Degraded service | Alternative response |

## Testing Strategy

### Testing Pyramid

```
         /\
        /E2E\
       /-----\
      /  API  \
     /---------\
    / Integration\
   /--------- ----\
  /    Unit Tests   \
 /-------------------\
```

### Coverage Targets

| Layer | Minimum | Critical |
|-------|---------|----------|
| Domain | 85% | 95% |
| Application | 85% | 95% |
| Infrastructure | 70% | - |
| Presentation | 60% | - |

### Test Types

**Unit Tests:**
- Domain entities, value objects
- Specifications, domain services
- Use case handlers
- Utilities

**Integration Tests:**
- Repository implementations
- Application services with real database
- Event handlers
- API contracts

**Contract Tests:**
- Bounded context boundaries
- Event schemas
- API response/request formats

**Mandatory Contract and Architecture Gates:**
- API contracts MUST be machine-readable as specified by the API-First principle.
- Contract tests MUST cover requests, responses, validation, and error behavior.
- Integration Event contract tests MUST validate schemas, version evolution and compatibility,
  required event identity and metadata, tenant isolation, and correlation/trace propagation.
- Messaging contract tests MUST verify at-least-once duplicate handling, consumer idempotency,
  publisher independence from subscriber availability, and observable retry and dead-letter
  handling according to platform policy.
- Automated architecture tests MUST reject a module importing another module's infrastructure,
  accessing another module's repository or database/schema, or invoking a private/internal
  module service. They MUST reject broker-specific SDK dependencies outside outbound
  infrastructure adapters and asynchronous cross-module communication outside the Platform
  Event Bus.
- Architecture and contract tests MUST reject synchronous cross-module calls used for
  notification of completed occurrences or independent state propagation instead of an
  Integration Event.
- Architecture tests MUST permit conforming versioned Integration Event publication and
  consumption through Platform Event Bus contracts and explicitly exposed canonical
  synchronous contracts.
- Tests MUST verify authentication, authorization, tenant isolation, and backward compatibility
  for supported API versions.
- Tests MUST verify idempotency for retryable state changes, concurrency where concurrent
  updates are possible, and correlation and trace propagation.
- Where MCP exposure exists, MCP contract tests MUST verify compatibility with the underlying
  platform contracts, including composed operations.
- Cross-channel tests MUST verify that each exposed MCP, CLI, GUI, SDK, and automation path
  preserves platform governance and cannot bypass its controls.
- Automated dependency tests MUST prevent channel or provider adapters from leaking into the
  domain or application and MUST prevent adapters from owning authoritative business rules.

**E2E Tests:**
- Complete user workflows
- Multi-step transactions
- Cross-context integration

**Example Test Suite:**

```typescript
// unit.spec.ts
describe('SubscriptionAggregate', () => {
  describe('activate', () => {
    it('should emit ActivatedEvent when valid', () => {
      const subscription = new Subscription(...);
      subscription.activate();
      expect(subscription.getEvents()).toContain(
        isInstanceOf(SubscriptionActivatedEvent)
      );
    });

    it('should throw InvalidStateError when already active', () => {
      const subscription = new Subscription(...);
      subscription.activate();
      expect(() => subscription.activate()).toThrow(InvalidStateError);
    });
  });
});

// integration.spec.ts
describe('SubscriptionRepository', () => {
  it('should persist and retrieve subscription', async () => {
    const subscription = new Subscription(...);
    await repo.save(subscription);

    const retrieved = await repo.findById(subscription.id);
    expect(retrieved).toEqual(subscription);
  });
});
```

## TypeScript Standards

### Compiler Options (tsconfig.json)

**Mandatory:**
```json
{
  "compilerOptions": {
    "strict": true,
    "strictNullChecks": true,
    "noImplicitAny": true,
    "noUncheckedIndexedAccess": true,
    "exactOptionalPropertyTypes": true,
    "useUnknownInCatchVariables": true,
    "noImplicitThis": true,
    "alwaysStrict": true,
    "noFallthroughCasesInSwitch": true
  }
}
```

### Naming Conventions

| Category | Convention | Example |
|----------|-----------|---------|
| Entities | PascalCase, singular | `User`, `Subscription` |
| Value Objects | PascalCase, singular | `Email`, `Money`, `TenantId` |
| Commands | PascalCase + "Command" | `CreateTenantCommand` |
| Queries | PascalCase + "Query" | `GetTenantQuery` |
| Events | PascalCase + "Event" | `SubscriptionActivatedEvent` |
| Repositories | PascalCase + "Repository" | `UserRepository` |
| Services | PascalCase + "Service" | `SubscriptionService` |
| Handlers | PascalCase + "Handler" | `CreateTenantHandler` |
| Interfaces | PascalCase, with I prefix optional | `IUserRepository` or `UserRepository` |
| Functions | camelCase | `calculateDiscount()` |
| Constants | UPPER_SNAKE_CASE | `MAX_RETRY_ATTEMPTS` |

### Type System Best Practices

**Discriminated Unions:**
```typescript
type SubscriptionStatus =
  | { type: 'pending'; expiresAt: Date }
  | { type: 'active'; activatedAt: Date }
  | { type: 'cancelled'; cancelledAt: Date };
```

**Branded Types:**
```typescript
type UserId = string & { readonly brand: 'UserId' };
function createUserId(value: string): UserId {
  return value as UserId;
}
```

**Avoid:**
- `any` type (use `unknown` instead)
- `ts-ignore` comments
- `ts-nocheck` files
- Unsafe type assertions

## Repository Pattern Rules

### Abstract Persistence

**Requirement:** No Prisma code outside Infrastructure layer

**Boundaries:**

| Layer | Allowed | Forbidden |
|-------|---------|-----------|
| Domain | Only types/interfaces | Prisma import |
| Application | Repository interfaces | Direct Prisma calls |
| Presentation | Application ports | Direct repository or database access |
| Infrastructure | Prisma implementation | Business logic |

**Example Implementation:**

```typescript
// Domain/Repositories (interface only, no implementation)
export interface UserRepository {
  save(user: User): Promise<void>;
  findById(id: UserId): Promise<User | null>;
  findByEmail(email: Email): Promise<User | null>;
}

// Application (use case depends on interface)
export class CreateUserHandler {
  constructor(private repo: UserRepository) {}

  async handle(command: CreateUserCommand): Promise<UserId> {
    const user = User.create(command);
    await this.repo.save(user);
    return user.id;
  }
}

// Infrastructure (Prisma implementation)
@Injectable()
export class PrismaUserRepository implements UserRepository {
  constructor(private prisma: PrismaClient) {}

  async save(user: User): Promise<void> {
    await this.prisma.user.upsert({
      where: { id: user.id.value },
      update: { /* ... */ },
      create: { /* ... */ },
    });
  }

  async findById(id: UserId): Promise<User | null> {
    const data = await this.prisma.user.findUnique({
      where: { id: id.value },
    });
    return data ? toDomain(data) : null;
  }
}
```

## Forbidden Anti-Patterns

### Strictly Prohibited

The codebase SHALL NOT contain:

1. **God Classes** — Classes with >200 lines, multiple responsibilities
2. **Fat Controllers** — Controllers with business logic, >50 lines
3. **Fat Services** — Services with >300 lines, tight coupling
4. **Anemic Domain Models** — Entities with only getters/setters, no behavior
5. **Primitive Obsession** — Using primitives instead of value objects
6. **Circular Dependencies** — Module A → B → A
7. **Framework Leakage** — Prisma/NestJS imports in domain
8. **Database Leakage** — Raw SQL, direct schema access in business logic
9. **Transaction Scripts** — Procedural code without domain model
10. **Singleton Global State** — Global variables, non-injectable singletons
11. **Large Switch Statements** — >5 branches (use strategy pattern)
12. **Copy-Paste Logic** — Duplicated code (extract to utilities)
13. **Utility Classes** — Classes with only static methods (use modules)
14. **Business Logic in Controllers** — Controllers orchestrate only
15. **Business Logic in ORM Models** — Prisma models are data only
16. **Direct Prisma Outside Infrastructure** — Breaks layer boundary
17. **Cross-Module Database Access** — A module accesses another module's database or schema
18. **Cross-Module Repository or Service Access** — A module invokes another module's repository,
    internal service, private API, or domain object
19. **Cross-Module Infrastructure or Model Imports** — A module imports another module's
    infrastructure implementation, provider implementation, or internal domain model
20. **Shared-Persistence Integration** — A module uses another module's tables or schema as an
    implicit integration contract
21. **Direct Broker Dependency** — Domain/Application business logic or a module depends on a
    RabbitMQ/Kafka SDK rather than a Platform Event Bus contract/port
22. **Uncontracted Cross-Module Messaging** — Asynchronous cross-module communication bypasses
    versioned Integration Events and the Platform Event Bus
23. **Synchronous Shortcut for Event Semantics** — A synchronous internal call replaces an
    event for notification of a completed business occurrence or independent state propagation
24. **Exactly-Once Consumer Assumption** — An event consumer relies on exactly-once delivery or
    allows duplicates to repeat business effects

### Detection & Refusal

**AI agents MUST:**
1. Refuse implementations violating these patterns
2. Auto-detect violations in code review
3. Suggest refactoring during implementation
4. Document violations in pull request comments

AI agents MUST also detect the inter-module coupling violations listed above and report
the failing boundary and governing contract in code review.

## AI Agent Governance

### Pre-Implementation Checklist

Before generating any code, **VALIDATE:**

- [ ] Constitution compliance — Does design follow this constitution?
- [ ] Clean Architecture boundaries — Are layers separated correctly?
- [ ] DDD principles — Are aggregates, entities, value objects modeled?
- [ ] CQRS separation — Are commands/queries clearly separated?
- [ ] Tenant isolation — Is tenant context enforced everywhere?
- [ ] Anti-patterns detection — Does code contain forbidden patterns?
- [ ] Architectural violations — Are framework/database leaks present?
- [ ] Test completeness — Are all business rules tested?
- [ ] Canonical API contract, shared authorization, tenant isolation, and required channel
      and architecture tests exist before channel exposure.
- [ ] Delivery follows resource/capability model → API contract → application port/use case →
      API implementation/inbound adapter → contract and architecture tests → Platform API
      Gateway publication → MCP when agent-relevant → CLI/GUI when required.
- [ ] Inter-module interaction semantics are classified as immediate synchronous result or
      asynchronous propagation of a completed occurrence.
- [ ] Cross-module synchronous calls use explicit versioned contracts; asynchronous
      cross-module communication uses versioned Integration Events through the Platform
      Event Bus.
- [ ] No module depends on another module's implementation, persistence, repository, internal
      service, or provider; no broker dependency leaks outside outbound infrastructure adapters.
- [ ] Event consumers tolerate at-least-once delivery, apply business effects idempotently,
      and preserve tenant, correlation, trace, retry, and dead-letter controls.
- [ ] Every external business route is declared and published through the governed Platform
      API Gateway; the Gateway is not the sole authority for business authorization.
- [ ] Gateway publication, withdrawal, version compatibility, and module availability satisfy
      the applicable lifecycle gates; route and trace context preserve tenant and identity.
- [ ] Domain and Application depend only on inward-owned capability ports at infrastructure
      boundaries; adapters implement those ports, and vendor-specific models remain outside.
- [ ] Scaffolding, certification, and automated architecture tests enforce DIP for Platform
      Core and every module, including in-process and standalone modules.

### Code Generation Standards

**Every generated feature SHALL include:**

1. Domain models (entities, aggregates, value objects)
2. Immutable Domain Events internal to their bounded context; explicitly mapped
   versioned Integration Event contracts for cross-context publication
3. Application use cases (commands/queries, handlers)
4. Repository/persistence ports owned by the Domain or Application inner boundary
5. Infrastructure implementations (Prisma repositories)
6. Versioned, documented synchronous API contracts and versioned Integration Event
   contracts, with contract and architecture tests before channel exposure
7. Transactional Outbox publication and idempotent at-least-once consumers where asynchronous
   inter-module communication is required
8. Unit tests (minimum 85% coverage)
9. Integration and contract tests for repositories, handlers, event schemas, compatibility,
   tenant isolation, idempotency, retries, dead-letter handling, and trace propagation
10. Architecture tests detecting prohibited module coupling, dependency-direction
    violations, Gateway bypass, and broker/vendor SDK leakage
11. Architecture documentation (component diagram, published module contracts, and
    inbound/outbound adapter boundaries)

### Refusal Criteria

**Agents MUST REFUSE:**
1. Implementations mixing layers
2. Business logic in controllers
3. Framework dependencies in domain
4. Direct Prisma calls outside infrastructure
5. Missing tests for business rules
6. Violations of naming conventions
7. Use of `any` type without justification
8. Missing tenant context enforcement
9. Circular dependencies
10. Copy-paste logic (suggest extraction)
11. Business capabilities existing only in MCP, CLI, GUI, or other channel adapters
12. Direct provider integration bypassing an existing governed platform capability
13. Channel-specific authorization that another channel can bypass
14. Duplicated domain or application logic in MCP servers or presentation components
15. State-changing operations lacking applicable idempotency or concurrency semantics
16. Externally visible behavior lacking a versioned contract
17. MCP implementations weakening API governance guarantees
18. Direct cross-module database or schema access
19. Direct cross-module repository access or invocation of private/internal services
20. Imports of another module's infrastructure, provider implementation, or internal domain model
21. Shared persistence used as an implicit cross-module integration mechanism
22. RabbitMQ/Kafka SDK dependencies in modules or Domain/Application business logic
23. Asynchronous cross-module communication outside versioned Integration Events and the
    Platform Event Bus
24. Synchronous coupling used to bypass an appropriate Integration Event
25. Consumers assuming exactly-once delivery or failing to prevent duplicate business effects
26. Internal Domain Events treated automatically as public Integration Events
27. Cross-module contracts lacking explicit versioning or required compatibility controls
28. A module publishing an unmanaged external business API that bypasses the Platform API
    Gateway
29. The Gateway treated as the sole authoritative business, RACI, or tenant authorization
    layer, or Gateway configuration containing authoritative domain/business rules
30. Domain or Application code depending directly on Kong or another Gateway product
31. Domain depending on a framework, ORM, broker, provider, Gateway, or vendor infrastructure
    implementation
32. Application business logic depending directly on concrete infrastructure implementations
    where an inward-owned port is required
33. An outbound abstraction shaped around a vendor API rather than the inner-layer capability
    required by the use case
34. Infrastructure-specific models leaking into Domain or canonical Application contracts
35. Module scaffolding omitting required architectural boundaries or current/future modules
    weakening DIP because they run in-process
36. Gateway publication without required contract, compatibility, security, tenant,
    observability, and governance checks, or continued exposure after governed withdrawal

Agents SHOULD recommend asynchronous Integration Events for a completed business occurrence
that other bounded contexts may handle independently. Agents SHOULD recommend canonical
synchronous contracts when the caller inherently needs an immediate result.
Agents MUST prefer inner-layer capability abstractions implemented by infrastructure
adapters over application/domain dependencies on vendor-specific implementations.

## Project Structure

```
sdd/
├── .github/
│   ├── skills/              # Copilot Agent Skills
│   │   ├── speckit-specify/
│   │   ├── speckit-plan/
│   │   └── ...
│   └── workflows/           # GitHub Actions
├── .specify/                # Spec Kit configuration
│   ├── memory/
│   │   └── constitution.md  # This file
│   ├── architecture.md      # Architecture guide
│   ├── standards.md         # Code standards
│   └── templates/
│       ├── feature-template.md
│       ├── bounded-context-template.md
│       └── domain-event-template.md
├── src/
│   ├── contexts/            # Bounded contexts (modular monolith)
│   │   ├── tenant/
│   │   ├── identity/
│   │   ├── subscription/
│   │   ├── billing/
│   │   └── audit/
│   ├── shared/              # Shared infrastructure
│   │   ├── domain/          # Base domain classes
│   │   ├── application/     # Base application classes
│   │   ├── infrastructure/  # Shared infrastructure
│   │   └── observability/   # Tracing, logging
│   └── main.ts              # Application bootstrap
├── test/
│   ├── unit/                # Unit tests
│   ├── integration/         # Integration tests
│   ├── contract/            # Contract tests
│   └── e2e/                 # End-to-end tests
├── docker/
│   ├── Dockerfile
│   └── docker-compose.yml
├── docs/
│   ├── architecture.md      # Architecture diagrams
│   ├── api.md               # API contract documentation and supported versions
│   └── domain-model.md      # Domain model glossary
├── package.json
├── tsconfig.json
├── .env.example
├── .gitignore
└── README.md
```

## Implementation Roadmap

### Phase 1: Foundation (Weeks 1-2)
- Project bootstrap
- Shared infrastructure
- Tenant context
- Identity & access foundation

### Phase 2: Core Domain (Weeks 3-4)
- Subscription domain
- Billing domain events
- Domain event infrastructure

### Phase 3: Integration (Weeks 5-6)
- Message broker setup
- Event handlers
- Cross-context communication

### Phase 4: Observability (Weeks 7-8)
- OpenTelemetry setup
- Distributed tracing
- Structured logging

### Phase 5: Testing (Weeks 9-10)
- Comprehensive test suite
- Contract tests
- Performance testing

## Deliverables

This constitution mandates the following artifacts:

- ✅ `.specify/memory/constitution.md` — Project principles and rules
- [ ] `.specify/architecture.md` — Architecture guide and diagrams
- [ ] `.specify/standards.md` — Code standards and style guide
- [ ] `.specify/templates/feature-template.md` — Feature implementation template
- [ ] `.specify/templates/bounded-context-template.md` — Bounded context template
- [ ] `.specify/templates/domain-event-template.md` — Domain event template

---

## Governance

- This constitution governs project decisions and MUST be checked in feature plans and reviews.
- Amendments MUST document the change, receive project maintainer approval, and identify
  affected artifacts and any required migration before adoption.
- Constitution versions follow semantic versioning: MAJOR for backward-incompatible
  governance changes, MINOR for new principles or material guidance, and PATCH for
  non-semantic clarifications. The 2.0.0 major increment introduced mandatory architecture
  and delivery constraints that may invalidate existing channel-first designs. Version
  2.1.0 makes the existing Event-Driven Architecture principle materially explicit:
  it governs module contracts, Platform Event Bus boundaries, delivery semantics, and
  mandatory architecture gates. It corrects the Outbox's exactly-once claim without
  removing or weakening an existing principle. Version 2.2.0 adds explicit governed
  Platform API Gateway and uniform Dependency Inversion principles, including new lifecycle,
  security, isolation, certification, and automated architecture gates without changing
  Modular Monolith First or weakening existing principles; a MINOR increment is appropriate.
  Version 2.3.0 adds Module Autonomy & Data Sovereignty as a normative principle extending
  DDD, bounded contexts, isolation, Clean Architecture, and DIP without replacing the v2
  architecture, requiring immediate independent service deployment, or requiring a
  physical database per module; a MINOR increment is appropriate.
- Reviews MUST verify compliance and identify unresolved violations before implementation.
- **Ratified:** TODO(RATIFICATION_DATE): Original adoption date is unknown.

**Version:** 2.3.0

**Last Updated:** 2026-11-23

**Status:** Active
