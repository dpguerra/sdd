# Arquitetura de Segurança e Testes de Conformidade

Este projeto adota o catálogo corporativo de **Security Architecture Decision Records (SADR)**.

Os SADRs definem decisões arquiteturais obrigatórias relacionadas a:

- Autenticação
- Autorização
- Criptografia
- Gestão de segredos
- Segurança de APIs
- Privacidade e LGPD
- DevSecOps
- Inteligência Artificial
- Observabilidade
- Zero Trust

Cada SADR possui:

- Contexto
- Decisão arquitetural
- Critérios de aceite
- Evidências obrigatórias
- Métricas
- Testes Gherkin

#### Artefatos:

- SADR-001 - Password Storage
- SADR-002 - Secret Management
- SADR-003 - Authentication Federation
- SADR-004 - Multi-Factor Authentication
- SADR-005 - Authorization RBAC ABAC
- SADR-006 - Session Management
- SADR-007 - Transport Security TLS
- SADR-008 - Encryption At Rest
- SADR-009 - Key Management
- SADR-010 - Data Classification
- SADR-011 - API Security
- SADR-012 - Input Validation
- SADR-013 - Secure Logging
- SADR-014 - Audit Trail
- SADR-015 - Observability and Correlation
- SADR-016 - Secure SDLC and SAST
- SADR-017 - Supply Chain Security
- SADR-018 - Container Security
- SADR-019 - Kubernetes Security
- SADR-020 - Zero Trust Architecture
- SADR-021 - Privacy and LGPD
- SADR-022 - AI Security
- SADR-023 - AI Governance
- SADR-024 - Secure by Default
- SADR-025 - Security by Design

## Sobre os Testes Gherkin

Os cenários escritos em Gherkin representam requisitos de segurança verificáveis.

Exemplo:

```gherkin
Feature: API Security

Scenario: Endpoint protegido
  Given uma API protegida
  When uma requisição sem token for enviada
  Then a resposta deverá ser HTTP 401
```

#### Instalação:

```npm
npm install --save-dev \
  @cucumber/cucumber \
  typescript \
  ts-node \
  tsx
  ```
#### Estrutura recomendada:

```project
project/
├── src/
├── tests/
│   ├── features/
│   │   ├── SADR-001.feature
│   │   ├── SADR-011.feature
│   │   └── SADR-022.feature
│   │
│   └── steps/
│       ├── password.steps.ts
│       ├── api.steps.ts
│       └── ai.steps.ts
│
├── sadr/
│   ├── SADR-001.md
│   ├── SADR-002.md
│   └── ...
│
└── package.json
```

#### Execução:

```npm
npx cucumber-js
```

# Integração entre SADR, Gherkin e Testes TypeScript

Este projeto adota o modelo de **Security Architecture Decision Records (SADR)** para documentar e validar decisões arquiteturais de segurança.

O objetivo é garantir que requisitos arquiteturais não sejam apenas documentados, mas também validados automaticamente por meio de testes executáveis.

## Fluxo de Governança

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
  // Nenhuma preparação adicional necessária
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

# Dependências

Instalação:

```bash
npm install express supertest

npm install --save-dev \
  @cucumber/cucumber \
  typescript \
  ts-node \
  @types/node \
  @types/supertest
```

---

# Configuração do package.json

```json
{
  "scripts": {
    "test:bdd": "cucumber-js --require-module ts-node/register --require tests/steps/**/*.ts tests/features/**/*.feature"
  }
}
```

---

# Estrutura Recomendada do Projeto

```text
project/
│
├── src/
│   └── server.ts
│
├── docs/
│   └── sadr/
│       ├── SADR-001.md
│       ├── SADR-011.md
│       └── SADR-022.md
│
├── tests/
│   ├── features/
│   │   └── SADR-011-api-security.feature
│   │
│   └── steps/
│       └── api-security.steps.ts
│
├── package.json
├── tsconfig.json
└── README.md
```

---

# Executando os Testes

```bash
npm run test:bdd
```

Resultado esperado:

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

# Exemplo de Segurança Avançada

## SADR-001 - Password Storage

### Cenário Gherkin

```gherkin
Feature: Password Storage

  Scenario: Senha armazenada com Argon2id
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

### Step de Teste

```typescript
import { Given, When, Then } from "@cucumber/cucumber";
import assert from "node:assert";
import { PasswordService } from "../../src/password-service";

const service = new PasswordService();

let hash = "";

Given("um novo usuário", function () {
  // setup
});

When("uma senha for persistida", async function () {
  hash = await service.hash("SenhaSegura123!");
});

Then("o hash deverá utilizar Argon2id", function () {
  assert.ok(hash.startsWith("$argon2id$"));
});
```

---

# Regra para Novos SADRs

Toda nova decisão arquitetural deve possuir:

- Documento SADR;
- Critérios de aceite;
- Cenários Gherkin;
- Testes automatizados;
- Evidências de execução no CI/CD.

Checklist:

```text
☐ SADR criado
☐ Critérios de aceite definidos
☐ Cenários Gherkin criados
☐ Steps TypeScript implementados
☐ Pipeline executando testes
☐ Evidências arquivadas
☐ Aprovação arquitetural registrada
```

---

# Benefícios

A adoção deste modelo permite:

- Arquitetura verificável;
- Governança auditável;
- Conformidade contínua;
- Segurança como código;
- Evidências automáticas para auditorias;
- Integração com DevSecOps.

Os SADRs deixam de ser apenas documentação e passam a ser controles executáveis e continuamente validados durante o ciclo de vida do software.

# Configuração do TypeScript

Arquivo:

```text
tsconfig.json
```

Conteúdo:

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "commonjs",
    "moduleResolution": "node",
    "lib": [
      "ES2022"
    ],
    "outDir": "./dist",
    "rootDir": ".",
    "strict": true,
    "esModuleInterop": true,
    "resolveJsonModule": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
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

## Explicação das Principais Configurações

| Configuração | Finalidade |
|-------------|------------|
| `target` | Versão JavaScript gerada pelo compilador |
| `module` | Padrão de módulos utilizado pelo Node.js |
| `moduleResolution` | Estratégia de localização dos módulos |
| `strict` | Habilita verificações rigorosas de tipos |
| `esModuleInterop` | Facilita interoperabilidade com bibliotecas CommonJS |
| `resolveJsonModule` | Permite importar arquivos JSON |
| `outDir` | Diretório de saída da compilação |
| `rootDir` | Diretório raiz do código-fonte |
| `types` | Habilita tipagens do Node.js |

---

# Estrutura Completa do Projeto

```text
project/
│
├── src/
│   ├── server.ts
│   └── password-service.ts
│
├── docs/
│   └── sadr/
│       ├── SADR-001.md
│       ├── SADR-011.md
│       └── SADR-022.md
│
├── tests/
│   ├── features/
│   │   ├── SADR-001-password-storage.feature
│   │   └── SADR-011-api-security.feature
│   │
│   └── steps/
│       ├── password.steps.ts
│       └── api-security.steps.ts
│
├── package.json
├── tsconfig.json
├── README.md
└── .gitignore
```

---

# Arquivo .gitignore

Também é recomendado incluir:

```gitignore
node_modules/
dist/
coverage/
.nyc_output/
.env
.env.*
```

---

# Validação da Configuração

Compilar o projeto:

```bash
npx tsc --noEmit
```

Executar os testes BDD:

```bash
npm run test:bdd
```

Executar a aplicação:

```bash
npm start
```

Executar verificação completa no CI:

```bash
npm run lint
npm run test
npm run test:bdd
npx tsc --noEmit
```

Se todos os comandos forem executados com sucesso, a implementação TypeScript estará adequada para suportar os cenários Gherkin definidos pelos SADRs.
