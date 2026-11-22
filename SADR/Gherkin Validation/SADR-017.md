# SADR-017 - Supply Chain Security

## Contexto
Padrão corporativo obrigatório para Supply Chain Security.

## Critérios de Aceite
- CA-001 Controle implementado.
- CA-002 Evidência auditável disponível.
- CA-003 Validação automatizada executada.
- CA-004 Aprovação arquitetural registrada.
- CA-005 Monitoramento ativo.

## Testes Gherkin

```gherkin
Feature: Supply Chain Security

Scenario: Validar implementação do controle
  Given um sistema corporativo sujeito ao SADR-017
  When a solução for implantada em produção
  Then o controle definido em Supply Chain Security deverá estar implementado

Scenario: Validar evidência de conformidade
  Given uma auditoria de segurança
  When as evidências forem solicitadas
  Then a organização deverá apresentar documentação comprobatória

Scenario: Validar automação
  Given um pipeline DevSecOps
  When a validação automática for executada
  Then o controle deverá ser verificado sem intervenção manual

Scenario: Validar exceções
  Given uma solicitação de exceção
  When o risco residual for avaliado
  Then a aprovação formal da Segurança da Informação deverá existir

Scenario: Validar monitoramento
  Given o ambiente produtivo
  When eventos relacionados ao controle ocorrerem
  Then registros auditáveis deverão ser gerados
```

## Evidências
- Documento de arquitetura
- Logs
- Relatórios de segurança
- Resultados de testes

## Referências
- OWASP ASVS
- NIST SSDF
- ISO 27001
