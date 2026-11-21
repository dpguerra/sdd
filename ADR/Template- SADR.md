# SADR-XXX - <Título da Decisão>

| Campo | Valor |
|---------|---------|
| ID | SADR-XXX |
| Título | <Título da decisão> |
| Status | Proposto / Em Revisão / Aprovado / Obsoleto / Substituído |
| Data | YYYY-MM-DD |
| Autor | <Nome ou Área> |
| Revisores | <Arquitetura, Segurança, Compliance etc.> |
| Sistemas Impactados | <Lista ou Todos> |
| Classificação | Segurança / Privacidade / IAM / Criptografia / DevSecOps / IA |
| Referências | <Normas, padrões ou documentos relacionados> |

---

# Contexto

Descreva o problema, risco ou necessidade que motivou a decisão.

Exemplos:

- Exposição de credenciais.
- Requisitos regulatórios.
- Vulnerabilidades recorrentes.
- Requisitos de conformidade.
- Padronização tecnológica.

---

# Problema

Descreva qual problema arquitetural precisa ser resolvido.

Exemplo:

Atualmente os sistemas utilizam múltiplos algoritmos para armazenamento de senhas, gerando inconsistência e dificultando a governança de segurança.

---

# Drivers Arquiteturais

## Segurança

- Confidencialidade
- Integridade
- Disponibilidade

## Compliance

- LGPD
- ISO 27001
- PCI-DSS
- NIST
- OWASP ASVS

## Negócio

- Padronização corporativa
- Redução de riscos
- Redução de custos operacionais

---

# Opções Avaliadas

## Opção 1

### Descrição

<Descrição>

### Vantagens

- Item 1
- Item 2

### Desvantagens

- Item 1
- Item 2

---

## Opção 2

### Descrição

<Descrição>

### Vantagens

- Item 1
- Item 2

### Desvantagens

- Item 1
- Item 2

---

# Decisão

Descreva claramente a decisão tomada.

Exemplo:

Todas as senhas de usuários deverão ser armazenadas utilizando Argon2id com salt único por credencial e pepper corporativo armazenado em serviço de Secret Management.

---

# Regras Mandatórias

## Obrigatório

- Regra 1
- Regra 2
- Regra 3

## Proibido

- Prática 1
- Prática 2
- Prática 3

---

# Requisitos de Implementação

## Aplicação

- Requisito
- Requisito

## Infraestrutura

- Requisito
- Requisito

## Operação

- Requisito
- Requisito

---

# Controles de Verificação

| Controle | Método |
|-----------|-----------|
| Code Review | Obrigatório |
| SAST | Obrigatório |
| Pentest | Quando aplicável |
| Arquitetura | Validação em ARB |
| Auditoria | Evidência obrigatória |

---

# Consequências Positivas

- Benefício 1
- Benefício 2
- Benefício 3

---

# Consequências Negativas

- Trade-off 1
- Trade-off 2
- Trade-off 3

---

# Exceções

Descreva as condições sob as quais a decisão pode ser flexibilizada.

Toda exceção deve possuir:

- Justificativa formal.
- Avaliação de risco.
- Aprovação da área de Segurança.

---

# Riscos Residuals

| Risco | Mitigação |
|---------|---------|
| Risco 1 | Controle |
| Risco 2 | Controle |

---

# Métricas

| Indicador | Meta |
|------------|----------|
| Cobertura | 100% |
| Conformidade | >95% |
| Vulnerabilidades críticas | 0 |

---

# Decisões Relacionadas

- SADR-001
- SADR-005
- SADR-014

---

# Histórico

| Data | Alteração | Responsável |
|--------|------------|-------------|
| YYYY-MM-DD | Criação | Nome |
| YYYY-MM-DD | Revisão | Nome |
