# Security Architecture Decisions (SAD)

## 1. Gestão de Credenciais e Senhas
### SAD-001 Armazenamento de senhas

Senhas devem ser armazenadas utilizando Argon2id, com salt único por credencial e pepper armazenado em serviço de gerenciamento de segredos (Vault, Key Vault, Secrets Manager etc.).

### SAD-002 Política de senha

O sistema não deve impor regras complexas de composição (caracteres especiais, letras maiúsculas etc.), mas deve exigir comprimento mínimo de 12 caracteres e verificar senhas comprometidas em bases conhecidas de vazamento.

### SAD-003 MFA

Autenticação multifator deve ser obrigatória para acessos administrativos e altamente recomendada para usuários finais.

## 2. Gestão de Segredos
### SAD-004 Proibição de segredos em código

Chaves, tokens, certificados e credenciais não devem ser armazenados em código-fonte, arquivos de configuração versionados ou pipelines.

### SAD-005 Secret Management

Todos os segredos devem ser armazenados em solução centralizada de gerenciamento de segredos com versionamento, auditoria e rotação automatizada.

### SAD-006 Rotação de credenciais

Credenciais de serviços devem possuir política de rotação automática e validade limitada.

## 3. Autenticação e Autorização
### SAD-007 Identity Provider

Autenticação deve ser centralizada em um Identity Provider compatível com OAuth2/OIDC.

### SAD-008 Menor privilégio

Todas as permissões devem seguir o princípio de Least Privilege.

### SAD-009 RBAC ou ABAC

O sistema deve implementar autorização baseada em papéis (RBAC) ou atributos (ABAC), evitando verificações de perfil espalhadas no código.

### SAD-010 JWT

Tokens JWT devem possuir curta duração, assinatura forte (RS256 ou superior) e revogação suportada por refresh tokens.

## 4. Proteção de APIs
### SAD-011 TLS obrigatório

Todo tráfego entre clientes, APIs e serviços internos deve utilizar TLS 1.2+ (preferencialmente TLS 1.3).

### SAD-012 Rate Limiting

APIs expostas devem implementar rate limiting e proteção contra abuso.

### SAD-013 Validação de entrada

Toda entrada deve ser validada por whitelist, nunca apenas por blacklist.

### SAD-014 Proteção contra OWASP API Top 10

O projeto deve contemplar controles específicos para os riscos do OWASP API Security Top 10.

## 5. Criptografia de Dados
### SAD-015 Dados em repouso

Dados classificados como sensíveis devem ser criptografados em repouso utilizando algoritmos aprovados (AES-256 ou equivalente).

### SAD-016 Gestão de chaves

Chaves criptográficas devem ser armazenadas em HSM ou serviço gerenciado de Key Management.

### SAD-017 Criptografia de campo

Dados pessoais sensíveis (CPF, passaporte, informações bancárias, prontuários etc.) devem possuir criptografia em nível de campo.

## 6. Logs e Auditoria
### SAD-018 Auditoria obrigatória

Todas as operações sensíveis devem gerar trilha de auditoria imutável.

### SAD-019 Não registrar segredos

Logs não devem conter senhas, tokens, chaves, cookies de sessão ou dados pessoais desnecessários.

### SAD-020 Correlação

Todas as transações devem possuir Correlation ID para rastreabilidade.

## 7. Segurança de Desenvolvimento
### SAD-021 SAST obrigatório

Todo código deve passar por análise estática automatizada antes do merge.

### SAD-022 SCA obrigatório

Dependências devem ser verificadas continuamente para vulnerabilidades conhecidas.

### SAD-023 Pipeline seguro

Builds só podem ser promovidos após aprovação das verificações de segurança configuradas.

### SAD-024 Assinatura de artefatos

Artefatos de software devem ser assinados digitalmente antes da distribuição.

## 8. Arquitetura Zero Trust
### SAD-025 Nunca confiar pela rede

A confiança não deve ser concedida com base apenas na localização da rede.

### SAD-026 Autorização contínua

Toda requisição deve ser autenticada e autorizada independentemente de sua origem.

### SAD-027 Segmentação

Componentes críticos devem operar em segmentos lógicos independentes.

## 9. Privacidade e LGPD
### SAD-028 Minimização de dados

Apenas dados estritamente necessários para o propósito de negócio devem ser coletados.

### SAD-029 Privacy by Design

Requisitos de privacidade devem ser definidos desde a etapa de concepção da solução.

### SAD-030 Retenção

Dados devem possuir política explícita de retenção e descarte.

## 10. Decisões modernas para IA e LLMs

Caso o SDD contemple sistemas com IA:

### SAD-031 Proteção contra Prompt Injection

Entradas fornecidas ao modelo devem ser tratadas como conteúdo não confiável.

### SAD-032 Proteção de dados sensíveis

Informações classificadas como confidenciais não devem ser enviadas para LLMs públicos sem aprovação formal.

### SAD-033 Validação de respostas

Respostas produzidas por IA que acionem processos críticos devem passar por validações determinísticas antes da execução.
