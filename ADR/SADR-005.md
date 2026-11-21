# SADR-005 - MFA Obrigatorio

| Campo | Valor |
|---|---|
| ID | SADR-005 |
| Status | Aprovado |
| Data | 2026-11-21 |
| Classificacao | Seguranca |

## Contexto
A organizacao necessita padronizar controles de seguranca entre sistemas e equipes.

## Problema
Ausencia de padronizacao gera riscos operacionais, vulnerabilidades e dificuldades de auditoria.

## Drivers Arquiteturais
- Seguranca
- Compliance
- Governanca
- Reducao de riscos

## Decisao
MFA para administradores e contas privilegiadas.

## Regras Mandatorias
- Aplicacao obrigatoria para novos projetos.
- Excecoes exigem aprovacao formal da seguranca.
- Evidencias devem ser mantidas para auditoria.

## Exemplo de Implementacao
Sistema de e-commerce corporativo aplica esta decisao em producao e homologacao.

## Consequencias Positivas
- Padronizacao.
- Melhor postura de seguranca.
- Menor superficie de ataque.

## Consequencias Negativas
- Possivel aumento de custo operacional.
- Maior esforco inicial de implantacao.

## Controles de Validacao
- Revisao arquitetural.
- Code review.
- Verificacao automatizada em pipeline.

## Historico
| Data | Alteracao |
|---|---|
| 2026-11-21 | Criacao |
