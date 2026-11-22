# README - SADR, Gherkin, TypeScript e DevSecOps

Este projeto adota o modelo de **Security Architecture Decision Records (SADR)** para documentar, implementar, validar e evidenciar requisitos arquiteturais de segurança.

O objetivo é garantir que decisões arquiteturais não sejam apenas documentadas, mas também verificadas continuamente por meio de testes automatizados e pipelines DevSecOps.

---

# Objetivos

- Padronizar requisitos arquiteturais de segurança.
- Tornar requisitos testáveis.
- Automatizar verificações de conformidade.
- Integrar arquitetura ao CI/CD.
- Produzir evidências para auditorias.
- Implementar Security as Code.

---

# Fluxo de Governança

```text
SADR
  ↓
Critérios de Aceite
  ↓
Cenários Gherkin
  ↓
Testes Automatizados
  ↓
Pipeline CI/CD
  ↓
Evidência de Conformidade
```

---

# Estrutura Recomendada do Projeto

```text
project/
│
├── src/
│   ├── server.ts
│   ├── auth/
│   ├── security/
│   └── services/
│
├── docs/
│   └── sadr/
│       ├── SADR-001.md
│       ├── SADR-002.md
│       ├── SADR-003.md
│       └── ...
│
├── tests/
│   ├── features/
│   │   ├── SADR-001-password-storage.feature
│   │   ├── SADR-011-api-security.feature
│   │   └── SADR-022-ai-security.feature
│   │
│   └── steps/
│       ├── password.steps.ts
│       ├── api-security.steps.ts
│       └── ai-security.steps.ts
│
├── .github/
│   └── workflows/
│       └── ci-security.yml
│
├── package.json
├── tsconfig.json
├── .gitignore
└── README.md
```

---

# Exemplo Completo

## SADR-011 - API Security

### Requisito Arquitetural

Toda API protegida deve rejeitar requisições sem autenticação.

### Critério de Aceite

**CA-001**

Dada uma API protegida

Quando uma requisição for enviada sem token

Então a API deverá responder HTTP 401 Unauthorized.

---

# Cenário Gherkin

Arquivo:

```text
tests/features/SADR-011-api-security.feature
```

Conteúdo:

```gherkin
Feature: API Security

  Como arquiteto de segurança
  Quero garantir que APIs protegidas exijam autenticação
  Para impedir acesso não autorizado

  Scenario: Requisição sem autenticação
    Given uma API protegida
    When uma requisição sem token for enviada
    Then a resposta deverá ser HTTP 401
```

---

# Implementação da API

Arquivo:

```text
src/server.ts
```

```typescript
import express from "express";

const app = express();

app.get("/users", (req, res) => {
  const authorization = req.headers.authorization;

  if (!authorization) {
    return res.status(401).json({
      error: "Unauthorized"
    });
  }

  return res.status(200).json([
    {
      id: 1,
      name: "Administrador"
    }
  ]);
});

export default app;
```

---

# Implementação dos Steps

Arquivo:

```text
tests/steps/api-security.steps.ts
```

```typescript
import { Given, When, Then } from "@cucumber/cucumber";
import request from "supertest";
import assert from "node:assert";

import app from "../../src/server";

let response: request.Response;

Given("uma API protegida", async function () {
  // setup
});

When("uma requisição sem token for enviada", async function () {
  response = await request(app)
    .get("/users");
});

Then("a resposta deverá ser HTTP 401", function () {
  assert.strictEqual(response.status, 401);
});
```

---

# Exemplo de Segurança Avançada

## SADR-001 - Password Storage

### Cenário Gherkin

```gherkin
Feature: Password Storage

  Scenario: Senha armazenada utilizando Argon2id
    Given um novo usuário
    When uma senha for persistida
    Then o hash deverá utilizar Argon2id
```

### Serviço TypeScript

```typescript
import argon2 from "argon2";

export class PasswordService {

  async hash(password: string): Promise<string> {
    return argon2.hash(password, {
      type: argon2.argon2id
    });
  }

}
```

### Teste Automatizado

Arquivo:

```text
tests/steps/password.steps.ts
```

```typescript
import { Given, When, Then } from "@cucumber/cucumber";
import assert from "node:assert";

import { PasswordService } from "../../src/password-service";

const service = new PasswordService();

let hash = "";

Given("um novo usuário", function () {
});

When("uma senha for persistida", async function () {
  hash = await service.hash("SenhaSegura123!");
});

Then("o hash deverá utilizar Argon2id", function () {
  assert.ok(hash.startsWith("$argon2id$"));
});
```

---

# Dependências

Instalação:

```bash
npm install express supertest argon2

npm install --save-dev \
  @cucumber/cucumber \
  typescript \
  ts-node \
  jest \
  eslint \
  @types/node \
  @types/supertest
```

---

# package.json

```json
{
  "name": "sadr-demo",
  "version": "1.0.0",
  "scripts": {
    "build": "tsc",
    "test": "jest",
    "test:bdd": "cucumber-js --require-module ts-node/register --require tests/steps/**/*.ts tests/features/**/*.feature",
    "lint": "eslint .",
    "coverage": "jest --coverage"
  }
}
```

---

# tsconfig.json

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "commonjs",
    "moduleResolution": "node",
    "lib": [
      "ES2022"
    ],
    "rootDir": ".",
    "outDir": "./dist",
    "strict": true,
    "esModuleInterop": true,
    "resolveJsonModule": true,
    "skipLibCheck": true,
    "types": [
      "node"
    ]
  },
  "include": [
    "src/**/*.ts",
    "tests/**/*.ts"
  ],
  "exclude": [
    "node_modules",
    "dist"
  ]
}
```

---

# .gitignore

```gitignore
node_modules/
dist/
coverage/
.nyc_output/
.env
.env.*
```

---

# Executando Localmente

Compilar:

```bash
npx tsc --noEmit
```

Executar testes unitários:

```bash
npm test
```

Executar testes BDD:

```bash
npm run test:bdd
```

Executar cobertura:

```bash
npm run coverage
```

Executar lint:

```bash
npm run lint
```

---

# Resultado Esperado

```text
Feature: API Security

  Scenario: Requisição sem autenticação
    ✓ Given uma API protegida
    ✓ When uma requisição sem token for enviada
    ✓ Then a resposta deverá ser HTTP 401

1 scenario (1 passed)
3 steps (3 passed)
```

---

# Integração com GitHub Actions

Estrutura:

```text
.github/
└── workflows/
    └── ci-security.yml
```

---

# Workflow GitHub Actions

Arquivo:

```text
.github/workflows/ci-security.yml
```

```yaml
name: CI Security & Compliance

on:
  push:
    branches:
      - main
      - develop

  pull_request:
    branches:
      - main
      - develop

jobs:

  build-and-test:

    runs-on: ubuntu-latest

    strategy:
      matrix:
        node-version: [20.x]

    steps:

      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Node
        uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node-version }}

      - name: Install Dependencies
        run: npm ci

      - name: Validate TypeScript
        run: npx tsc --noEmit

      - name: Run Lint
        run: npm run lint

      - name: Run Unit Tests
        run: npm test

      - name: Run BDD Tests
        run: npm run test:bdd

      - name: Run Coverage
        run: npm run coverage
```

---

# Secret Scanning

Adicionar verificação de segredos:

```yaml
secret-scanning:

  runs-on: ubuntu-latest

  steps:

    - uses: actions/checkout@v4

    - name: Run Gitleaks
      uses: gitleaks/gitleaks-action@v2
```

---

# Dependency Vulnerability Scan

```yaml
dependency-check:

  runs-on: ubuntu-latest

  steps:

    - uses: actions/checkout@v4

    - name: Dependency Check
      uses: dependency-check/Dependency-Check_Action@main
      with:
        project: "typescript-project"
        path: "."
```

---

# Mapeamento dos SADRs no Pipeline

| SADR | Validação |
|--------|-----------|
| SADR-001 | Argon2id |
| SADR-002 | Secret Scanning |
| SADR-003 | OIDC |
| SADR-004 | MFA |
| SADR-005 | RBAC |
| SADR-011 | API Security |
| SADR-013 | Logging |
| SADR-016 | SAST |
| SADR-017 | Dependency Scan |
| SADR-018 | Container Security |
| SADR-022 | AI Security |
| SADR-025 | Security by Design |

---

# Critério de Aprovação de Pull Request

Um Pull Request somente pode ser aprovado quando:

```text
✅ Compilação TypeScript
✅ ESLint aprovado
✅ Testes unitários aprovados
✅ Cenários Gherkin aprovados
✅ Cobertura mínima atingida
✅ Sem segredos expostos
✅ Sem vulnerabilidades críticas
✅ Critérios de aceite dos SADRs atendidos
```

---

# Regra para Novos SADRs

Toda decisão arquitetural deve possuir:

- Documento SADR;
- Critérios de aceite;
- Cenários Gherkin;
- Testes automatizados;
- Evidências em pipeline.

Checklist:

```text
☐ SADR criado
☐ Critérios de aceite definidos
☐ Cenários Gherkin criados
☐ Steps implementados
☐ Testes automatizados criados
☐ Pipeline atualizado
☐ Evidências geradas
☐ Aprovação arquitetural registrada
```

---

# Benefícios

A adoção deste modelo proporciona:

- Arquitetura verificável;
- Segurança como código;
- Compliance contínuo;
- Evidências para auditorias;
- Integração com DevSecOps;
- Rastreabilidade ponta a ponta entre decisão arquitetural e implementação.

Com isso, os SADRs deixam de ser apenas documentação e passam a ser controles de segurança executáveis e continuamente validados.
