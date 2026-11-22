# Enterprise SaaS Platform — Constitution

## Project Overview

An enterprise-grade, multi-tenant SaaS platform optimized for autonomous AI implementation while maintaining strict architectural governance. The system prioritizes modularity, scalability, and maintainability for teams of 20+ engineers.

## Core Architectural Principles

### 1. Architecture Styles

- **Domain Driven Design (DDD)** — Strategic and tactical DDD with bounded contexts
- **Clean Architecture** — Strict dependency layers with inward-only dependencies
- **CQRS** — Separated command and query models with independent evolution
- **Event-Driven Architecture** — Domain events drive business operations
- **Modular Monolith First** — Explicit bounded contexts, microservices-ready
- **API First** — RESTful APIs as primary integration mechanism
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

## Clean Architecture Layers

### Layer Hierarchy

```
┌─────────────────────────────────────┐
│      Infrastructure                 │
│  (Prisma, Redis, NestJS, Fastify)   │
├─────────────────────────────────────┤
│      Presentation                   │
│  (Controllers, Interceptors, Guards)│
├─────────────────────────────────────┤
│      Application                    │
│  (Use Cases, Commands, Queries)     │
├─────────────────────────────────────┤
│      Domain (Pure TypeScript)       │
│  (Entities, Aggregates, Services)   │
└─────────────────────────────────────┘
```

### Dependency Rules

**Mandatory:**
- Dependencies point ONLY inward
- Higher layers depend on lower layers
- No circular dependencies permitted

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

// Guard: Validate tenant authorization
@UseGuards(TenantGuard)
@Controller('api/invoices')
class InvoiceController {
  constructor(private query: GetInvoiceQuery) {}
  
  @Get(':id')
  async getInvoice(@Param('id') invoiceId: string) {
    // Guard ensures user belongs to request tenant
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
- Authorization logic lives in Guards, not Controllers
- Controllers delegate to Guards
- Use Decorators for declarative authorization
- Fail-secure: deny by default

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
- Context API surface defined
- Input/Output DTOs versioned
- Change logs maintained

**Example Contract:**

```typescript
// @sdd/billing-context-contract

export interface BillingContext {
  commands: {
    CreateInvoiceCommand: (payload: CreateInvoicePayload) => Promise<InvoiceId>;
  };
  events: {
    InvoiceGeneratedEvent: DomainEvent;
    PaymentApprovedEvent: DomainEvent;
  };
  queries: {
    GetInvoiceQuery: (id: InvoiceId) => Promise<Invoice>;
  };
}
```

### Integration Mechanisms

| Mechanism | Use Case | Example |
|-----------|----------|---------|
| **Async Events** | Loose coupling, eventual consistency | SubscriptionActivated → SendWelcomeEmail |
| **Message Broker** | Distributed transactions, outbox pattern | RabbitMQ topic subscriptions |
| **REST APIs** | Synchronous queries, service-to-service | GET /invoices/:id |
| **gRPC** (Future) | High-throughput, low-latency internal APIs | Streaming events |

### Idempotency

**Requirement:** All operations must be idempotent

**Implementation:**
- Idempotency keys in request headers
- Idempotency cache (Redis)
- Deduplication in event handlers

```typescript
@Post('/invoices')
@Idempotent()
async createInvoice(@Header('Idempotency-Key') key: string) {
  // Redis lookup prevents duplicate processing
  const cached = await this.cache.get(key);
  if (cached) return cached;
  
  const result = await this.command.execute(dto);
  await this.cache.set(key, result, TTL_1HOUR);
  return result;
}
```

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
| Presentation | Repository interfaces | Direct database access |
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

### Code Generation Standards

**Every generated feature SHALL include:**

1. Domain models (entities, aggregates, value objects)
2. Domain events (immutable, timestamped)
3. Application use cases (commands/queries, handlers)
4. Repository interfaces (domain-layer contracts)
5. Infrastructure implementations (Prisma repositories)
6. API endpoints (REST controllers)
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
│   ├── constitution.md      # This file
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
│   ├── api.md               # API documentation
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

- ✅ `.specify/constitution.md` — Project principles and rules
- [ ] `.specify/architecture.md` — Architecture guide and diagrams
- [ ] `.specify/standards.md` — Code standards and style guide
- [ ] `.specify/templates/feature-template.md` — Feature implementation template
- [ ] `.specify/templates/bounded-context-template.md` — Bounded context template
- [ ] `.specify/templates/domain-event-template.md` — Domain event template

---

**Version:** 1.0  
**Last Updated:** 2025-11-22  
**Status:** Active
