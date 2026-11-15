<!--
Sync Impact Report
Version change: 1.10.0 → 2.0.0
Modified principles: IV. Cache Local Não Autoritativo (acesso por abstração de infraestrutura).
Added principles: None.
Added sections: None.
Modified sections: Stack e Arquitetura (MongoDB passa a ser implementação padrão, não dependência de negócio).
Removed sections: None.
Follow-up TODOs: Confirm the original ratification date.
-->

# Constituição do MCP para OpenClaw

## Core Principles

### I. Regras de Negócio Testáveis
Toda regra de negócio MUST possuir pelo menos um teste unitário Jest que verifique seu
comportamento esperado e casos-limite relevantes. Alterações em regras de negócio MUST
atualizar ou acrescentar os testes correspondentes.

### II. Integração de Todas as Tools
Cada tool MCP MUST possuir pelo menos um teste de integração que valide sua entrada,
saída e comportamento observável através da interface MCP. Os testes MUST cobrir os
contratos relevantes com dependências externas ou adaptadores usados pela tool.

### III. Intelligence Budget
Cada tool MUST retornar somente as informações necessárias para atender à solicitação,
com saída concisa, estruturada e sem duplicação desnecessária. Quando aplicável, MUST
oferecer filtros, limites ou paginação para evitar respostas excessivas e preservar o
orçamento de contexto e tokens do OpenClaw.

### IV. Cache Local Não Autoritativo
Informações recuperadas via API e armazenadas no cache local MUST ser tratadas como
cache, nunca como fonte autoritativa. A lógica de negócio MUST acessar o cache por
abstrações de infraestrutura, sem dependência direta de sua implementação. O uso do
cache MUST preservar a possibilidade de obter dados atualizados da API conforme as
regras de negócio e a validade dos dados.

### V. Contratos MCP Orientados ao OpenClaw
As tools e seus contratos MUST ser projetados para uso pelo OpenClaw, com nomes,
descrições, parâmetros e resultados claros e previsíveis. Mudanças incompatíveis nos
contratos MUST ser explicitadas e acompanhadas dos ajustes de integração necessários.

### VI. Tool Design First
Toda tool MCP MUST realizar uma única responsabilidade de negócio claramente
identificável. Tools genéricas ou multifuncionais SHOULD ser divididas em operações
menores e previsíveis para maximizar a capacidade de planejamento do OpenClaw.

### VII. Determinismo de Resposta
Toda tool MUST retornar estrutura de dados consistente para sucesso, ausência de
resultado e erro.

### VIII. MCP Resource First
Informações predominantemente consultivas SHOULD ser expostas como MCP Resources
sempre que possível. Tools MUST ser reservadas para operações parametrizadas,
cálculos ou ações.

### IX. Observabilidade Obrigatória
Toda execução de tool MUST produzir logs estruturados contendo a tool executada,
os parâmetros recebidos (com valores sensíveis mascarados), a duração, o resultado e
as falhas ocorridas.

### X. Segurança e Limitação de Escopo
Toda tool MUST expor apenas os dados necessários para a execução da tarefa solicitada.
Dados internos, segredos, credenciais e informações sensíveis MUST NOT ser retornados
ao modelo.

### XI. Versionamento de Contratos MCP
Alterações incompatíveis em parâmetros, nomes ou formatos de retorno MUST resultar em
incremento de versão do contrato MCP e coexistência temporária da versão anterior
quando tecnicamente viável.

### XII. Estratégia de Paginação
Toda consulta que possa retornar coleções superiores a 100 registros MUST implementar
paginação explícita.

### XIII. Princípio de Idempotência
Tools de leitura MUST ser totalmente idempotentes. Tools de escrita SHOULD ser
idempotentes sempre que possível.

### XIV. Testes de Consumo pelo Agente
Toda tool MUST possuir testes que validem sua descoberta e utilização por um cliente
MCP compatível.

## Stack e Arquitetura

O projeto MUST utilizar TypeScript para o código da aplicação. O cache local MUST ser
acessado através de abstrações de infraestrutura. MongoDB é a implementação padrão
atual do cache; a lógica de negócio MUST NOT depender diretamente de MongoDB. A
implementação MUST seguir as práticas recomendadas para servidores MCP e respeitar o
Intelligence Budget: priorizar dados relevantes, limitar respostas excessivas e evitar
trabalho ou contexto redundante.
Docker MUST ser utilizado para executar o MongoDB e os demais sistemas de apoio
necessários ao desenvolvimento ou à execução do projeto.

## Qualidade e Convenções de Contribuição

Os testes unitários MUST utilizar Jest. Toda regra de negócio MUST ser coberta por teste
unitário e todas as tools MUST ser cobertas por testes de integração, conforme os
princípios desta Constituição.

Nomes de classes e arquivos MUST utilizar palavras em português. Mensagens de erro
apresentadas por código do projeto MUST ser escritas em português. Commits MUST seguir
o formato `tipo(escopo): descrição [REQ-identificador]`, incluindo o identificador do
requisito relacionado.

## Governance

Esta Constituição prevalece sobre planos, especificações e práticas locais. Se um plano
contradisser esta Constituição, o plano MUST ser atualizado antes da implementação. Se
uma mudança exigir alteração desta Constituição, sua alteração MUST ser feita em um
commit separado das mudanças de implementação.

Alterações nesta Constituição MUST ser revisadas e registradas com a data da emenda.
A versão MUST seguir SemVer: MAJOR para remoção ou redefinição incompatível de
princípios; MINOR para novos princípios ou expansão material das regras; PATCH para
esclarecimentos sem mudança semântica. Revisões de especificações, planos e mudanças
de código MUST verificar conformidade com os princípios, stack, convenções e requisitos
de teste aqui definidos.

**Version**: 2.0.0 | **Ratified**: TODO(RATIFICATION_DATE): confirmar data original de adoção | **Last Amended**: 2026-11-15
