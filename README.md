# SDD Template (Software Design Document)

# Engineering Constitution
```contitution
 .specify/constitution.md
```

## Purpose

This repository shall be maintained as an enterprise-grade TypeScript system designed for long-term maintainability, testability, and scalability.

---

# Core Principles

## Principle 1 — Clean Architecture

The system SHALL follow Clean Architecture.

Dependencies must always point inward.

Allowed dependency flow:

Infrastructure
→ Presentation
→ Application
→ Domain

Domain MUST NOT depend on:

- Frameworks
- Databases
- ORMs
- External APIs
- SDKs

---

## Principle 2 — SOLID

All code SHALL comply with SOLID principles.

Special attention:

- Single Responsibility Principle
- Dependency Inversion Principle

---

## Principle 3 — Dependency Injection

Dependencies SHALL be injected.

Forbidden:

new ConcreteRepository()

inside use cases.

Required:

constructor(
    private readonly repository: UserRepository
)

---

## Principle 4 — Domain Driven Design

When business complexity exists, the system SHALL use:

- Entities
- Value Objects
- Aggregates
- Domain Events
- Repositories

Simple CRUD systems should avoid unnecessary DDD abstractions.

---

## Principle 5 — Testing

Every business rule MUST have automated tests.

Required:

- Unit tests
- Integration tests
- End-to-end tests for critical flows

Minimum coverage target:

80%

---

# Required Design Patterns

The following patterns are approved:

- Strategy
- Factory Method
- Builder
- Repository
- Adapter
- Facade
- Observer
- Command

Each pattern must be justified by a business or technical need.

Pattern abuse is forbidden.

---

# Forbidden Anti-Patterns

The codebase SHALL NOT contain:

- God Classes
- Fat Controllers
- Anemic Domain Model
- Primitive Obsession
- Business Logic inside Controllers
- Circular Dependencies
- Framework Leakage into Domain
- Singleton Global State
- Large Switch Statements
- Direct Database Access outside Repositories

---

# TypeScript Rules

Required:

- strict mode
- noImplicitAny
- strictNullChecks
- exhaustive typing

Forbidden:

- any
- ts-ignore
- magic strings for domain rules

```architecture
.specify/architecture.md
```
# System Architecture

## Architectural Style

- Clean Architecture
- Modular Monolith by default
- Event-driven internally
- API-first design

---

# Layers

## Domain

Responsibilities:

- Enterprise rules
- Entities
- Value Objects
- Domain Events

Folder:

src/domain

---

## Application

Responsibilities:

- Use Cases
- Commands
- Queries
- DTOs

Folder:

src/application

---

## Infrastructure

Responsibilities:

- Database
- Messaging
- Cache
- External APIs

Folder:

src/infrastructure

---

## Presentation

Responsibilities:

- Controllers
- Routes
- Validation
- Serialization

Folder:

src/presentation

---

# Project Structure

```files
src/
├── domain/
├── application/
├── infrastructure/
├── presentation/
├── shared/
└── tests/
```
---

# Event Model

Domain events SHALL be used for:

- User registration
- Order lifecycle
- Payment lifecycle
- Audit activities

Examples:

- UserCreatedEvent
- OrderPaidEvent
- InvoiceGeneratedEvent

Implementation pattern:

Observer/EventBus

# Development Standards
```standards
.specify/standards.md
```


## Naming

Entities:

User
Order
Invoice

Value Objects:

Email
Money
Address
UserId

Commands:

CreateUserCommand
PayInvoiceCommand

Queries:

GetUserByIdQuery

Repositories:

UserRepository

Adapters:

StripeAdapter
SapAdapter

Facades:

PaymentFacade
NotificationFacade

---

# Error Handling

Base hierarchy:

ApplicationError
BusinessRuleError
ValidationError
IntegrationError
InfrastructureError

Never throw generic Error.

---

# Logging

Must use structured logging.

Required attributes:

- timestamp
- traceId
- correlationId
- requestId

---

# Validation

Must happen at system boundaries.

Examples:

- HTTP Requests
- Queue Messages
- External Integrations

Domain entities must remain self-validating.

---

# Security

Required:

- Authentication
- Authorization
- Input validation
- Secret management
- Audit logging

Forbidden:

- secrets in source code
- credentials in repositories

# Feature Specification
```feature-template
.specify/templates/feature-template.md
```

## Feature Name

[FEATURE_NAME]

---

## Business Goal

Describe the business problem.

---

## Actors

- User
- Administrator
- External Service

---

## Functional Requirements

### FR-001

The system shall ...

### FR-002

The system shall ...

---

## Non-Functional Requirements

### Performance

Response time < 500ms

### Availability

99.9%

### Security

JWT authentication required

---

## Domain Model

### Entities

- User
- Subscription

### Value Objects

- UserId
- Email
- Money

### Domain Events

- SubscriptionCreated

---

## Use Cases

### Create Subscription

Input:

- userId
- planId

Output:

- subscriptionId

---

## Architecture Impact

Layer changes:

- Domain
- Application
- Infrastructure

---

## Patterns Applied

- Factory
- Strategy
- Repository

Justification:

Describe why each pattern is necessary.

---

## Anti-Pattern Validation

Verify feature does NOT introduce:

- God Class
- Fat Controller
- Primitive Obsession
- Circular Dependency
- Framework Leakage

---

## Testing Requirements

Unit Tests:
Required

Integration Tests:
Required

E2E Tests:
Required

Coverage:
80% minimum

# AI Generation Rules

Before generating code:

1. Validate compliance with Constitution.
2. Validate Clean Architecture boundaries.
3. Validate SOLID.
4. Validate DDD rules.
5. Detect anti-patterns.
6. Prefer composition over inheritance.
7. Prefer Value Objects over primitive types.
8. Prefer interfaces over concrete implementations.
9. Prefer domain events over tight coupling.
10. Generate tests together with implementation.

If a requested implementation violates this constitution,
propose a compliant alternative.

# Security Architecture Decisions (SADR)

## 1. Gestão de Credenciais e Senhas
### SADR-001 Armazenamento de senhas

Senhas devem ser armazenadas utilizando Argon2id, com salt único por credencial e pepper armazenado em serviço de gerenciamento de segredos (Vault, Key Vault, Secrets Manager etc.).

### SADR-002 Política de senha

O sistema não deve impor regras complexas de composição (caracteres especiais, letras maiúsculas etc.), mas deve exigir comprimento mínimo de 12 caracteres e verificar senhas comprometidas em bases conhecidas de vazamento.

### SADR-003 MFA

Autenticação multifator deve ser obrigatória para acessos administrativos e altamente recomendada para usuários finais.

## 2. Gestão de Segredos
### SADR-004 Proibição de segredos em código

Chaves, tokens, certificados e credenciais não devem ser armazenados em código-fonte, arquivos de configuração versionados ou pipelines.

### SADR-005 Secret Management

Todos os segredos devem ser armazenados em solução centralizada de gerenciamento de segredos com versionamento, auditoria e rotação automatizada.

### SADR-006 Rotação de credenciais

Credenciais de serviços devem possuir política de rotação automática e validade limitada.

## 3. Autenticação e Autorização
### SADR-007 Identity Provider

Autenticação deve ser centralizada em um Identity Provider compatível com OAuth2/OIDC.

### SADR-008 Menor privilégio

Todas as permissões devem seguir o princípio de Least Privilege.

### SADR-009 RBAC ou ABAC

O sistema deve implementar autorização baseada em papéis (RBAC) ou atributos (ABAC), evitando verificações de perfil espalhadas no código.

### SADR-010 JWT

Tokens JWT devem possuir curta duração, assinatura forte (RS256 ou superior) e revogação suportada por refresh tokens.

## 4. Proteção de APIs
### SADR-011 TLS obrigatório

Todo tráfego entre clientes, APIs e serviços internos deve utilizar TLS 1.2+ (preferencialmente TLS 1.3).

### SADR-012 Rate Limiting

APIs expostas devem implementar rate limiting e proteção contra abuso.

### SADR-013 Validação de entrada

Toda entrada deve ser validada por whitelist, nunca apenas por blacklist.

### SADR-014 Proteção contra OWASP API Top 10

O projeto deve contemplar controles específicos para os riscos do OWASP API Security Top 10.

## 5. Criptografia de Dados
### SADR-015 Dados em repouso

Dados classificados como sensíveis devem ser criptografados em repouso utilizando algoritmos aprovados (AES-256 ou equivalente).

### SADR-016 Gestão de chaves

Chaves criptográficas devem ser armazenadas em HSM ou serviço gerenciado de Key Management.

### SADR-017 Criptografia de campo

Dados pessoais sensíveis (CPF, passaporte, informações bancárias, prontuários etc.) devem possuir criptografia em nível de campo.

## 6. Logs e Auditoria
### SADR-018 Auditoria obrigatória

Todas as operações sensíveis devem gerar trilha de auditoria imutável.

### SADR-019 Não registrar segredos

Logs não devem conter senhas, tokens, chaves, cookies de sessão ou dados pessoais desnecessários.

### SADR-020 Correlação

Todas as transações devem possuir Correlation ID para rastreabilidade.

## 7. Segurança de Desenvolvimento
### SADR-021 SAST obrigatório

Todo código deve passar por análise estática automatizada antes do merge.

### SADR-022 SCA obrigatório

Dependências devem ser verificadas continuamente para vulnerabilidades conhecidas.

### SADR-023 Pipeline seguro

Builds só podem ser promovidos após aprovação das verificações de segurança configuradas.

### SADR-024 Assinatura de artefatos

Artefatos de software devem ser assinados digitalmente antes da distribuição.

## 8. Arquitetura Zero Trust
### SADR-025 Nunca confiar pela rede

A confiança não deve ser concedida com base apenas na localização da rede.

### SADR-026 Autorização contínua

Toda requisição deve ser autenticada e autorizada independentemente de sua origem.

### SADR-027 Segmentação

Componentes críticos devem operar em segmentos lógicos independentes.

## 9. Privacidade e LGPD
### SADR-028 Minimização de dados

Apenas dados estritamente necessários para o propósito de negócio devem ser coletados.

### SADR-029 Privacy by Design

Requisitos de privacidade devem ser definidos desde a etapa de concepção da solução.

### SADR-030 Retenção

Dados devem possuir política explícita de retenção e descarte.

## 10. Decisões modernas para IA e LLMs

Caso o SDD contemple sistemas com IA:

### SADR-031 Proteção contra Prompt Injection

Entradas fornecidas ao modelo devem ser tratadas como conteúdo não confiável.

### SADR-032 Proteção de dados sensíveis

Informações classificadas como confidenciais não devem ser enviadas para LLMs públicos sem aprovação formal.

### SADR-033 Validação de respostas

Respostas produzidas por IA que acionem processos críticos devem passar por validações determinísticas antes da execução.
