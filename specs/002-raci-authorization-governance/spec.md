# Feature Specification: RACI-Driven Authorization Governance

**Feature Branch**: `002-raci-authorization-governance`

**Created**: 2026-11-22

**Status**: Draft

**Input**: RACI responsibility, risk-based authorization, delegation, emergency access, and evidence for the Platform Core Control Plane.

## User Scenarios & Testing *(mandatory)*

Each story is independently testable with the Platform Core Foundation and the stated policy and identity fixtures. Priorities indicate delivery importance, not a relaxation of security prerequisites.

### User Story 1 - Define Responsibility Policy (Priority: P1)

A governance administrator defines versioned responsibility rules for an operation and scope, so ownership and required controls are enforceable rather than just documented.

**Why this priority**: All governed decisions need explicit rules.

**Independent Test**: Publish a policy with role assignments and controls, retrieve its version, and evaluate inheritance with higher-scope fixtures.

**Acceptance Scenarios**:

1. **Given** an authorized administrator and valid scope, **When** they publish a policy specifying Responsible, Accountable, Consulted and Informed roles and their requirements, **Then** the policy becomes available as a versioned, auditable record.
2. **Given** an organization policy mandates a security consultation, **When** a project administrator tries to remove that requirement, **Then** the change is rejected and the mandatory consultation remains applicable.
3. **Given** a designated governed operation with no valid policy, **When** execution is requested, **Then** execution is denied and the failed evaluation is auditable.
4. **Given** an authorized administrator, **When** they revise a scoped role binding or risk rule, **Then** its new version is available for future evaluations and prior decision evidence remains unchanged.

**Traceability**: FR-001–FR-006, FR-011, FR-032, FR-037; E01, E02; SC-005.

### User Story 2 - Request a Governed Operation (Priority: P1)

A user requests a defined operation on a tenant resource, knowing that identity, access and governance requirements will be checked before execution.

**Why this priority**: Requests establish the protected operation and its security context.

**Independent Test**: Submit an eligible request and a cross-tenant request against identity and policy fixtures; verify the latter cannot execute.

**Acceptance Scenarios**:

1. **Given** an authenticated principal with permission to request an operation, **When** they submit the target and desired change, **Then** a traceable request is recorded without executing the operation.
2. **Given** a principal without access to the target tenant, **When** they submit a request, **Then** access is denied and no target operation executes.

**Traceability**: FR-007–FR-010, FR-019, FR-031–FR-032, FR-037; E09, E15; SC-001–SC-004.

### User Story 3 - Determine Authorization Requirements (Priority: P1)

The Control Plane resolves applicable policy, responsibilities and risk to present a deterministic authorization plan.

**Why this priority**: A decision cannot be governed without knowing which controls apply.

**Independent Test**: Evaluate identical request, time, policy, binding and resource inputs twice, then compare the resolved requirements and decision inputs.

**Acceptance Scenarios**:

1. **Given** a permitted request and complete applicable inputs, **When** requirements are evaluated, **Then** the plan identifies risk, RACI roles and principals, applicable versions, approvals, consultations, notifications and execution constraints.
2. **Given** identical complete inputs and versions, **When** the request is evaluated again, **Then** its authorization requirements are identical.
3. **Given** no active binding for a required Accountable role, **When** requirements are resolved, **Then** execution remains blocked with an explicit unresolved-responsibility reason.

**Traceability**: FR-003–FR-006, FR-011–FR-015, FR-019, FR-037; E01–E04; SC-001, SC-005.

### User Story 4 - Approve or Reject a Request (Priority: P1)

An eligible Accountable principal approves or rejects the operation under its plan; the requester can see its resulting status.

**Why this priority**: Decisions must be attributable and enforce configured approval requirements.

**Independent Test**: Record an eligible approval and an ineligible approval against a pending request, then verify the required threshold and outcomes.

**Acceptance Scenarios**:

1. **Given** a pending request requiring approval, **When** an eligible Accountable principal approves, **Then** the approval is recorded and authorization proceeds only after all configured requirements are satisfied.
2. **Given** a pending request, **When** an eligible approver rejects it, **Then** it is rejected and cannot execute under that request.
3. **Given** a previously recorded approval, **When** the same submission is repeated, **Then** it is not counted twice and the existing outcome is returned.

**Traceability**: FR-016–FR-020, FR-029, FR-032; E02, E03, E10, E11; SC-002, SC-003.

### User Story 5 - Record Required Consultation (Priority: P1)

A consulted party records an outcome so configured consultation requirements are satisfied before authorization.

**Why this priority**: Mandatory consultation must not be bypassed by an approval.

**Independent Test**: Submit an authorized consultation response and attempt authorization with an unanswered required consultation.

**Acceptance Scenarios**:

1. **Given** a plan requiring consultation, **When** an eligible consulted principal records an outcome, **Then** the outcome and attribution are retained and evaluated according to policy.
2. **Given** a required consulted party is unavailable or has not responded, **When** authorization is evaluated, **Then** the request remains pending or fails closed and cannot execute.

**Traceability**: FR-016–FR-019, FR-032; E04; SC-002, SC-003.

### User Story 6 - Revalidate Before Execution (Priority: P1)

An approved operation is checked against its current authorization inputs immediately before it executes.

**Why this priority**: An approval for an old state must not authorize a changed operation.

**Independent Test**: Authorize a request, change one material input, and attempt execution; repeat with unchanged inputs.

**Acceptance Scenarios**:

1. **Given** an authorized operation, **When** its policy, binding, delegation, tenant, risk, target state, desired state or execution plan materially changes, **Then** execution is blocked, the request becomes authorization-stale, and reevaluation is required.
2. **Given** a current authorization whose controls remain satisfied, **When** execution is claimed, **Then** revalidation and the decision to begin execution protect against intervening changes and execution begins at most once.
3. **Given** authorization has expired or been revoked, **When** execution is attempted, **Then** execution is denied with an explicit reason.

**Traceability**: FR-019–FR-024, FR-029, FR-032; E05–E09, E11–E12; SC-002, SC-006.

### User Story 7 - Delegate Low-Risk Authority (Priority: P2)

A service owner grants bounded authority to an eligible delegate, reducing repeated approval for operations allowed by policy.

**Why this priority**: Controlled delegation enables practical governance without weakening authority boundaries.

**Independent Test**: Grant a bounded delegation and evaluate an in-scope request, then test an out-of-scope, expired and revoked delegation.

**Acceptance Scenarios**:

1. **Given** a policy permitting delegation and an authorized delegator, **When** a bounded delegation is created, **Then** an eligible in-scope operation can be authorized without manual approval only if policy permits.
2. **Given** authority beyond the delegator's permitted scope, **When** that authority is delegated, **Then** the delegation is rejected.
3. **Given** a pending request relying on a delegation, **When** the delegation expires or is revoked before execution, **Then** execution is blocked and reevaluation is required.

**Traceability**: FR-006, FR-013, FR-021–FR-023, FR-032; E05; SC-006.

### User Story 8 - Inform Stakeholders (Priority: P2)

Informed stakeholders receive the decision and operation outcome required by policy, including any delivery failure.

**Why this priority**: Governance requires visibility after decisions and execution.

**Independent Test**: Complete an operation with Informed-role fixtures and simulate successful and failed notification delivery.

**Acceptance Scenarios**:

1. **Given** a decision or execution outcome and required Informed roles, **When** the outcome is recorded, **Then** the applicable recipients are notified according to policy and delivery outcomes are recorded.
2. **Given** a notification cannot be delivered, **When** delivery fails, **Then** the failure remains visible and retryable; it does not erase the decision or falsely report delivery.

**Traceability**: FR-025–FR-026, FR-032; E13; SC-003, SC-008.

### User Story 9 - Reconstruct a Decision (Priority: P1)

An authorized auditor reconstructs why an operation was or was not authorized and who acted.

**Why this priority**: A decision without evidence is not accountable.

**Independent Test**: Retrieve a completed request's evidence and reconstruct every policy input, decision, action and execution outcome from the recorded history.

**Acceptance Scenarios**:

1. **Given** a governed operation, **When** an authorized auditor inspects its evidence, **Then** they can reconstruct the request, versions, resolved roles and principals, risk, responses, decision and outcome.
2. **Given** evidence belonging to a different tenant, **When** an auditor without explicitly modeled platform authority requests it, **Then** access is denied.

**Traceability**: FR-010, FR-030–FR-032, FR-037; E09; SC-003–SC-004.

### User Story 10 - Use Governed Emergency Authorization (Priority: P2)

An emergency operator acts under explicit, bounded emergency policy while preserving accountability.

**Why this priority**: Exceptional urgent operations need a controlled path, not an unrestricted bypass.

**Independent Test**: Submit emergency requests with and without required authority and justification, and inspect expiry, notification and review evidence.

**Acceptance Scenarios**:

1. **Given** an authenticated operator eligible under an active emergency policy, **When** they provide justification for an in-scope request, **Then** time-bounded authorization is recorded and required stakeholders are notified.
2. **Given** missing justification, expired emergency authority or no applicable emergency policy, **When** emergency access is requested, **Then** it is denied and no operation executes.
3. **Given** policy requires retrospective review, **When** emergency authorization is used, **Then** a review obligation is recorded and remains visible until completed.

**Traceability**: FR-027–FR-028, FR-031–FR-032; E13–E14; SC-007.

### User Story 11 - AI Agent Explains Requirements (Priority: P2)

An AI agent obtains and explains a Control Plane plan without independently determining authority.

**Why this priority**: Agents need useful explanations without becoming an authorization authority.

**Independent Test**: Compare an agent's retrieved plan with the canonical decision and attempt an unauthorized direct execution.

**Acceptance Scenarios**:

1. **Given** an agent authorized to inspect a plan, **When** it requests requirements, **Then** it receives the Control Plane's resolved requirements and can explain them without changing the decision.
2. **Given** an agent or MCP request lacking required authorization, **When** it attempts execution or a provider bypass, **Then** the operation is denied and the attempt is auditable.

**Traceability**: FR-033–FR-036, FR-031–FR-032; E15; SC-009.

### Edge Cases

- **E01 Missing Accountable binding**: Keep the request blocked with an unresolved-responsibility reason; no implicit fallback. (FR-011, FR-019; US3)
- **E02 Multiple principals for one role**: Record the eligible set and apply the configured approval threshold; without an explicit valid threshold, fail closed. (FR-012, FR-016; US3–US4)
- **E03 Responsible and Accountable are the same principal**: Permit only when the effective policy permits it; an explicit separation-of-duties rule takes precedence. (FR-012, FR-016; US4)
- **E04 Required Consulted party unavailable**: Keep consultation unsatisfied; do not convert silence into consent. (FR-017, FR-019; US5)
- **E05 Delegation expires or is revoked while pending**: Mark the dependent authorization stale or expired as applicable and block execution. (FR-021–FR-023; US6–US7)
- **E06 Policy changes after approval**: A material change makes the prior authorization stale and requires reevaluation. (FR-022–FR-023; US6)
- **E07 Role binding changes after approval**: Revalidate eligibility; a material change makes the authorization stale. (FR-022–FR-023; US6)
- **E08 Resource version, desired state, risk or execution plan changes**: Block execution as stale and reevaluate the changed operation. (FR-022–FR-023; US6)
- **E09 Tenant context changes**: Reject cross-tenant reuse and require a new evaluation under the target tenant's context. (FR-010, FR-022–FR-023; US2, US6, US9)
- **E10 Duplicate approval**: Return the prior result without counting another approval or creating another effective decision. (FR-018; US4)
- **E11 Concurrent approval and cancellation**: Establish one consistent order; cancellation before execution prevents execution, and a late approval cannot revive the request. Once execution begins, cancellation MUST NOT claim it was prevented. (FR-020, FR-024, FR-029; US4, US6)
- **E12 Authorization expires before execution**: Deny execution and record expiry; a new evaluation is needed. (FR-019, FR-022–FR-023; US6)
- **E13 Notification delivery fails**: Preserve an auditable failed-delivery status and retry; do not claim delivery succeeded or undo an already recorded operation. (FR-025–FR-026; US8, US10)
- **E14 Emergency request lacks justification**: Deny it and record the attempted emergency action. (FR-027, FR-032; US10)
- **E15 AI/MCP bypass attempt**: Deny any ungoverned execution and record the attempt; agent explanations have no decision authority. (FR-033–FR-036; US2, US11)

## Requirements *(mandatory)*

### Functional Requirements

#### Responsibility and Policy

- **FR-001**: The Control Plane MUST maintain responsibility policies as versioned, auditable functional data, including scope, applicable operations, RACI assignments, requirements, classification and effective period. (US1, US3)
- **FR-002**: Policies MUST support organization → tenant → project → environment → service/module → resource type → operation scope, inheritance, and controlled overrides. A narrower scope MUST NOT weaken a mandatory higher-scope requirement. (US1)
- **FR-003**: Policy requirements MUST be classified as mandatory, overridable or delegatable; effective policy MUST identify the source and version of each applied requirement and reject unauthorized overrides. Equally applicable conflicting rules MUST be resolved by explicit policy precedence or fail closed. (US1, US3)
- **FR-004**: RACI MUST distinguish Responsible (perform/co-ordinate), Accountable (own/authorize), Consulted (provide required input) and Informed (receive notice). Assignments SHOULD reference organizational or platform roles rather than hardcoded individuals. (US1, US3)
- **FR-005**: An authorized administrator MUST be able to create, revise, activate and inspect responsibility policies and their history; existing decisions MUST retain the policy versions used. (US1, US9)
- **FR-006**: The platform MUST support configurable, versioned LOW, MEDIUM, HIGH and CRITICAL risk classifications and corresponding authorization controls, without assigning universal approval rules to a risk label. (US1, US3, US7)

#### Identity, Request and Tenant Boundaries

- **FR-007**: A request MUST identify the requesting principal, tenant, target resource and version, operation, desired state, execution plan and request identity before governance evaluation; non-applicable fields MUST be explicitly identified. (US2, US3)
- **FR-008**: The Control Plane MUST resolve identity, authenticate the requester and evaluate existing IAM/RBAC and applicable policy before RACI and risk resolution. Denied or unresolved checks MUST block execution. (US2, US3)
- **FR-009**: RACI governance MUST complement, not replace, foundation IAM/RBAC; assignment to a RACI role alone MUST NOT grant permission. (US2, US3)
- **FR-010**: Policies, bindings, delegations, requests, responses, decisions and evidence MUST be tenant-isolated where applicable. Cross-tenant access MUST fail closed unless explicit platform-level authority is modeled and verified; it MUST still resolve and enforce the target tenant context and MUST NOT expose unrelated tenant data. (US2, US9)

#### Resolution, Planning and Decision

- **FR-011**: Authorized administrators MUST be able to manage and inspect scoped, versioned role bindings. The Control Plane MUST use them to resolve RACI roles to eligible active principals; a missing required role or principal MUST block authorization with an explicit reason. (US1, US3)
- **FR-012**: The effective policy MUST specify eligible principals, approval thresholds for approval-bearing roles and any separation-of-duties constraints; missing or invalid decision rules MUST fail closed. Multiple bindings and overlapping roles MUST be handled according to those rules. (US3, US4)
- **FR-013**: Before execution, the Control Plane MUST produce a durable authorization plan identifying request and tenant, target and operation, risk, resolved RACI roles and principals, policy and binding versions, required approvals, consultations, notifications, applicable delegations, execution constraints and status. (US3, US7)
- **FR-014**: Given identical complete inputs, including effective time, resource state, relevant policy versions and role bindings, evaluation MUST yield identical authorization requirements. Plans MUST record enough inputs and versions to reproduce the result. (US3, US9)
- **FR-015**: Policy MUST determine whether an in-scope operation can be automatically authorized, requires approvals or consultations, or has other constraints; risk labels alone MUST NOT hardcode a global approval workflow. (US3, US7)
- **FR-016**: Only principals eligible under current IAM/RBAC, bindings and effective policy MAY approve or reject; an eligible rejection MUST prevent execution under the request. Required approvals MUST meet the configured threshold. (US4)
- **FR-017**: Required consultation MUST be recorded by eligible consulted principals and evaluated according to policy; unanswered consultation MUST NOT count as consent. (US5)
- **FR-018**: Repeated submission of the same approval, rejection or consultation MUST NOT create duplicate effective responses or count more than once. (US4, US5)
- **FR-019**: An authorization decision MUST be more than a boolean: it MUST record status, reasons, actor, time, expiry and the plan and evidence it relied on. No operation may execute unless all applicable requirements are satisfied and the authorization remains valid. (US2–US6, US9)

#### Lifecycle, Delegation and Execution

- **FR-020**: The authorization lifecycle MUST define and audit allowed transitions: requested → policy validated → RACI resolved → risk classified → planned → pending or authorized → executing → verifying → completed or failed. Before execution, a request MAY become rejected, expired, authorization-stale or cancelled when the corresponding event occurs; these states are non-executable. Invalid transitions MUST fail closed; stale requests require reevaluation into a new plan before authorization. (US3–US6)
- **FR-021**: Authorized delegators MUST be able to grant and revoke delegations identifying grantor, recipient, permitted resource scopes, operations, environment, effective time, expiry, reason and evidence. A delegation MUST NOT exceed the delegator's permitted delegatable authority or override mandatory controls. (US7)
- **FR-022**: Immediately before execution, the Control Plane MUST revalidate the request, current identity and tenant, IAM/RBAC, policy and RACI versions, bindings, delegation status, risk, resource version, desired state, execution plan, approvals and consultations. Expired or revoked authority MUST fail closed. (US6–US7)
- **FR-023**: Material changes to authorization inputs MUST set an explicit authorization-stale state, block the prior authorization, and require policy-defined reevaluation; tenant changes require evaluation under the target tenant context. The decision to begin execution MUST prevent a change between revalidation and execution from silently authorizing a different operation. (US6)
- **FR-024**: Execution MUST be claimed at most once per authorized request; concurrent approval, cancellation and execution MUST have a consistent outcome. Cancellation before execution prevents it; cancellation after execution begins MUST NOT be reported as preventing execution. Execution and verification outcomes MUST be recorded. (US6)

#### Notification, Emergency and Evidence

- **FR-025**: Policy MUST determine which Informed roles receive decision and execution outcome notifications. The Control Plane MUST record recipient resolution and delivery status without treating delivery failure as success. (US8)
- **FR-026**: Failed required notifications MUST remain visible and retryable; a failure MUST NOT erase or falsify an already recorded decision or execution outcome. (US8)
- **FR-027**: Break-glass MUST require authentication, explicit applicable emergency policy and authority, in-scope operation, justification and a bounded validity period; missing or expired requirements MUST deny execution. It MUST NOT grant permanent unrestricted authority or disable governance. (US10)
- **FR-028**: Emergency use MUST identify the operator, notify policy-required stakeholders, and create a mandatory retrospective review obligation when configured; review completion MUST be recorded. (US10)
- **FR-029**: Lifecycle changes, duplicate submissions and conflicting concurrent actions MUST have deterministic, auditable outcomes and MUST NOT authorize an invalid transition or duplicate execution. (US4, US6)
- **FR-030**: Authorized auditors MUST be able to retrieve evidence sufficient to reconstruct each decision: request and operation identities, principal, tenant, target and version, desired state and execution plan, RACI roles and principals, risk, relevant policy and binding versions, delegation, approvals, consultations, decision, timestamps, expiry, correlation identifier and, where execution occurred, its execution/verification outcome. Evidence MUST explicitly indicate unavailable or inapplicable inputs. (US9)
- **FR-031**: Governance actions MUST use the foundation's immutable audit capability, tenant controls, event contracts and correlation/trace propagation throughout the lifecycle. (US2, US9–US11)
- **FR-032**: Evidence MUST record requests, policy evaluation, RACI and risk resolution, delegation grants/use/revocation, consultations, approvals, rejections, expiration, staleness, emergency use, execution authorization and outcomes, notifications and applicable version identifiers. (US1–US10)

#### Channel and Agent Governance

- **FR-033**: Governance capabilities MUST be available through canonical, versioned, authenticated, authorized, tenant-aware, documented and observable API contracts before release through other channels, consistent with Constitution v2.0.0. (US11)
- **FR-034**: Agent-relevant capabilities SHOULD be exposed through MCP. MCP exposure, when provided, MUST follow the canonical contract and MAY compose operations, but MUST NOT decide authority, bypass IAM, policy, RACI or audit, or directly authorize provider operations outside the Control Plane. (US11)
- **FR-035**: CLI, GUI, SDK and automation exposure, when provided, MUST preserve the same authorization, tenancy, validation, audit and state semantics; no channel MAY provide an ungoverned privileged path. (US2, US11)
- **FR-036**: An AI agent MAY inspect or explain plans, prepare requests, initiate authorized workflows and monitor status or evidence; it MUST NOT infer authority or substitute generated judgment for the deterministic Control Plane decision. (US11)
- **FR-037**: Authorized governance administrators MUST be able to designate operation types as governed. A designated operation MUST NOT execute when its applicable policy is missing or invalid, and designation changes MUST be auditable. (US1–US3, US9)

### Key Entities

- **Tenant, User and Role**: Existing foundation identities and permission groupings; this feature reuses rather than redefines them.
- **ResponsibilityPolicy**: Scoped, effective and versioned RACI, risk and control requirements, including inheritance and override classification.
- **RoleBinding**: Scoped relationship resolving an existing role to eligible principals and its validity; it does not independently grant IAM permission.
- **Delegation**: Bounded, time-limited, revocable transfer of permitted authority, including grantor, recipient, scope, reason and evidence.
- **RiskClassification**: Versioned classification and policy-selected controls for an operation.
- **AuthorizationRequest**: Principal, tenant, target, operation, desired state and execution context requiring a decision.
- **AuthorizationPlan**: Deterministic snapshot of applicable versions, RACI resolution, risk, required responses and execution constraints for a request.
- **AuthorizationDecision**: Attributable, time-bounded outcome and reasons referencing the plan and evidence.
- **Approval and Consultation**: Attributed responses to a plan's distinct approval and consultation requirements.
- **Notification**: Required stakeholder message and its delivery status.
- **BreakGlassAuthorization**: Emergency-policy-bound, justified and time-limited authorization with notification and review obligations.
- **AuthorizationEvidence**: Immutable, tenant-scoped history sufficient to reconstruct decisions, execution and verification.

## Success Criteria *(mandatory)*

### Measurable Outcomes

The following are acceptance targets for a defined test set covering every supported governed operation type and applicable channel; they are not claims about an implemented system.

- **SC-001**: 100% of tested governed operation requests receive identity, IAM/RBAC, policy, RACI and risk evaluation before execution. (US2–US3; FR-007–FR-015)
- **SC-002**: Zero tested executions occur with missing, rejected, expired, revoked or stale authorization, unsatisfied consultation, or invalid lifecycle transition. (US4–US6; FR-016–FR-024)
- **SC-003**: For 100% of tested decisions, an authorized auditor can reconstruct the available inputs, approvals, consultations, delegation, decision and any execution outcome from immutable evidence, with unavailable or inapplicable inputs identified. (US8–US9; FR-025–FR-026, FR-030–FR-032)
- **SC-004**: 100% of tested unauthorized cross-tenant requests and evidence reads are denied without exposing another tenant's data. (US2, US9; FR-010)
- **SC-005**: 100% of repeated evaluations with identical complete inputs produce identical requirements; all tested mandatory higher-scope controls remain effective under attempted lower-scope overrides. (US1, US3; FR-001–FR-006, FR-011–FR-014)
- **SC-006**: 100% of tested delegations outside grantor authority, scope or validity are rejected or blocked; permitted automatic decisions remain within configured controls. (US6–US7; FR-021–FR-023)
- **SC-007**: 100% of tested emergency authorizations require valid authority, justification and a bounded period, with required notices and configured review obligations recorded. (US10; FR-027–FR-028)
- **SC-008**: 100% of tested required notification failures remain visible and retryable, and are not reported as delivered. (US8; FR-025–FR-026)
- **SC-009**: For 100% of tested equivalent operations across each exposed channel, including MCP, CLI and GUI when present, decisions and governance protections agree; zero tested unauthorized channel or agent bypass attempts execute. (US11; FR-033–FR-036)

## Assumptions

- The foundation supplies tenant and identity context, users, roles, IAM/RBAC, audit, governance, observability, module contracts and events; this feature extends those capabilities rather than reimplementing them.
- A governed operation is one explicitly registered as subject to this feature's policies. No matching valid policy, binding, required decision rule or emergency policy fails closed.
- A policy explicitly defines thresholds, acceptable consultation outcomes, role overlap and separation-of-duties requirements; no universal quorum or mandatory human approval is inferred from risk labels.
- Scope inheritance applies only to actual ancestor relationships. Platform-level authority is explicitly modeled and authorized; tenant-scoped operations retain their target tenant context.
- Notification failure remains observable and retryable; notification alone is not treated as an approval. Any pre-execution notification constraint must be explicitly configured in policy.
- Supported channel parity is tested only for channels actually exposed. No GUI or CLI design, endpoint paths, workflow engine, database design, vendor integration, infrastructure-specific DNS logic, general BPM product, HR management, IAM replacement, AI-based authorization decision, implementation tasks or constitution amendment is in scope.
- Foundation dependencies and follow-up conflicts: foundation FR-025/FR-028 describe CLI scaffolding and standards updates without canonical contract requirements; FR-040–FR-048 and its UI-exclusion assumption disagree about portal scope; FR-010 limits users to one tenant and needs alignment with explicitly modeled platform authority. Foundation FR-022 retains an unresolved module-isolation clarification. These are not modified here.
