<!--
Sync Impact Report
Version: 1.0 -> 2.0.0 (new mandatory architecture and delivery constraints may invalidate channel-first designs)
Modified: Core Architectural Principles -> Core Principles; Clean Architecture Layers;
Authentication & Authorization; Microservices Contracts; Integration Mechanisms; Idempotency;
Observability; Testing Strategy; AI Agent Governance; Project Structure; Deliverables.
Added: API-First -> MCP-Second -> CLI/GUI; Governance.
Removed: none.
Deferred: TODO(RATIFICATION_DATE) - original adoption date is unknown; synchronize
the feature specification and dependent templates separately.
-->
# Enterprise SaaS Platform — Constitution

## Project Overview

An enterprise-grade, multi-tenant SaaS platform optimized for autonomous AI implementation while maintaining strict architectural governance. The system prioritizes modularity, scalability, and maintainability for teams of 20+ engineers.

## Core Principles

### 1. Architecture Styles

- **Domain Driven Design (DDD)** — Strategic and tactical DDD with bounded contexts
- **Clean Architecture** — Strict dependency layers with inward-only dependencies
- **CQRS** — Separated command and query models with independent evolution
- **Event-Driven Architecture** — Domain events drive business operations
- **Modular Monolith First** — Explicit bounded contexts, microservices-ready
- **API-First → MCP-Second → CLI/GUI** — Canonical operational contracts before channel exposure
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
- RabbitMQ or Kafka (integration events)
- Outbox Pattern (transaction guarantee)

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
    → API implementation
    → Contract and architecture tests
    → MCP exposure, when agent-relevant
    → CLI/GUI exposure, when required
```

In-process adapters MAY invoke application ports directly; loopback HTTP calls are not required.
Such calls MUST pass through the same authoritative validation, authentication context,
authorization, tenant isolation, policy, audit, idempotency, concurrency, and observability
mechanisms defined by the canonical contract. No internal invocation may bypass those controls.
Correlation and trace context MUST propagate from the initiating channel through execution.

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

### Tactical DDD

**Required Concepts:**

| Concept | Purpose | Location |
|---------|---------|----------|
| **Aggregate** | Consistency boundary, invariants | Domain |
| **Entity** | Business-critical identity | Domain |
| **Value Object** | Immutable concept without identity | Domain |
| **Domain Service** | Cross-aggregate business logic | Domain |
| **Repository** | Persistence abstraction | Infrastructure |
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

// Repositories (Infrastructure, not Domain)
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

- **Outbox Pattern** — Atomically persist events and read-model updates
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

**Definition:** Immutable records of significant business occurrences

**Mandatory Characteristics:**
- Immutable
- Timestamped
- Correlated with aggregate ID
- Correlated with tenant ID
- Carry minimal data (reference IDs, not full entities)

**Domain Event Catalog** (Initial):

| Event | Context | Payload |
|-------|---------|---------|
| TenantCreatedEvent | Tenant | tenantId, name |
| UserCreatedEvent | Identity | userId, tenantId, email |
| SubscriptionActivatedEvent | Subscription | subscriptionId, tenantId, planId |
| PaymentApprovedEvent | Billing | paymentId, invoiceId, amount |
| InvoiceGeneratedEvent | Billing | invoiceId, tenantId, amount |

### Integration Events

**Definition:** Events published to external systems via message broker

**Message Broker:** RabbitMQ or Kafka
- Topics/Exchanges per bounded context
- Schema versioning
- Idempotent consumers
- Dead-letter queues

### Outbox Pattern

**Problem:** Atomicity of domain event persistence and business operation

**Solution:** Write domain events and aggregates in single transaction

```
1. Begin transaction
2. Modify aggregate (Subscription)
3. Insert into Outbox table (SubscriptionActivatedEvent)
4. Commit transaction
5. Event handler polls Outbox
6. Publishes to message broker
7. Marks event as published
```

**Benefits:**
- No lost events
- Exactly-once semantics
- Atomic domain operations

## Microservices Readiness

### Design Principles

**Every bounded context should be extractable as a microservice without major refactoring.**

### Microservices Contracts

**Explicit Boundaries:**
- Canonical API contracts MUST define synchronous operational capabilities.
- Asynchronous integration events MUST have separate versioned contracts.
- Application commands and domain events are not automatically public API contracts.
- Public DTOs and integration event schemas MUST be versioned independently of internal
  domain models. Change logs MUST be maintained.
- Breaking changes MUST use a new contract version or an explicitly governed compatibility
  and migration process; supported versions MUST be covered by compatibility tests.

### Integration Mechanisms

| Mechanism | Use Case | Example |
|-----------|----------|---------|
| **Async Events** | Loose coupling, eventual consistency | SubscriptionActivated → SendWelcomeEmail |
| **Message Broker** | Distributed transactions, outbox pattern | RabbitMQ topic subscriptions |
| **REST APIs** | Canonical synchronous commands and queries | GET /invoices/:id |
| **gRPC** (Future) | High-throughput, low-latency internal APIs | Streaming events |

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

### Detection & Refusal

**AI agents MUST:**
1. Refuse implementations violating these patterns
2. Auto-detect violations in code review
3. Suggest refactoring during implementation
4. Document violations in pull request comments

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
      API implementation → contract and architecture tests → MCP when agent-relevant →
      CLI/GUI when required.

### Code Generation Standards

**Every generated feature SHALL include:**

1. Domain models (entities, aggregates, value objects)
2. Domain events (immutable, timestamped)
3. Application use cases (commands/queries, handlers)
4. Repository interfaces (domain-layer contracts)
5. Infrastructure implementations (Prisma repositories)
6. Versioned, documented API contracts and implementations (REST by default), with contract
   and architecture tests before any applicable MCP, CLI, or GUI exposure
7. Unit tests (minimum 85% coverage)
8. Integration tests (repository + handler)
9. Architecture documentation (component diagram)

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
  non-semantic clarifications. The 2.0.0 major increment introduces mandatory architecture
  and delivery constraints that may invalidate existing channel-first designs.
- Reviews MUST verify compliance and identify unresolved violations before implementation.
- **Ratified:** TODO(RATIFICATION_DATE): Original adoption date is unknown.

**Version:** 2.0.0

**Last Updated:** 2026-11-22

**Status:** Active
