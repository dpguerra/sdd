<!--
Sync Impact Report
Version change: 3.5.0 → 4.0.0
Modified principles: None.
Added sections: None.
Modified sections: Qualidade e Convenções de Contribuição (test runner e convenção linguística).
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

### IX. Observabilidade sem Vazamento de Dados
Logs MUST registrar metadados operacionais, identificadores de correlação, duração,
resultado, código de erro, provider e versão do contrato. Payloads completos e parâmetros
sensíveis MUST NOT ser registrados por padrão. A observabilidade MUST utilizar allowlist
de campos seguros, redaction centralizada e correlação por `requestId`, `runId` e
`checkpointId`.

### X. Segurança e Limitação de Escopo
Toda tool MUST expor apenas os dados necessários para a execução da tarefa solicitada.
Dados internos, segredos, credenciais e informações sensíveis MUST NOT ser retornados
ao modelo.

### XI. Versionamento de Contratos MCP
Alterações incompatíveis em parâmetros, nomes ou formatos de retorno MUST resultar em
incremento de versão do contrato MCP e coexistência temporária da versão anterior
quando tecnicamente viável.

### XII. Política Mensurável de Paginação
Toda operação potencialmente não limitada MUST implementar paginação por cursor ou limite
equivalente. O tamanho padrão da página MUST ser definido por domínio e MUST respeitar
limites de payload, latência e contexto. O servidor MUST limitar `pageSize`, mesmo quando
o cliente solicitar valor superior. Respostas truncadas MUST indicar `hasMore` e
`nextCursor`. Paginação por cursor SHOULD ser preferida quando os dados puderem mudar
durante a leitura.

### XIII. Princípio de Idempotência
Tools de leitura MUST ser totalmente idempotentes. Tools de escrita SHOULD ser
idempotentes sempre que possível.

### XIV. Testes de Consumo pelo Agente
Toda tool MUST possuir testes que validem sua descoberta e utilização por um cliente
MCP compatível.

### XV. Evidência por Gate
Uma implementação MUST NOT ser considerada concluída apenas por compilar ou passar em
testes unitários. A homologação MUST registrar separadamente os estados de Design, Code,
Contract, Wiring, Typecheck, Build, Unit Tests, Integration Tests, Regression, Runtime e
Operational. A aprovação de um gate posterior MUST NOT se basear exclusivamente em
evidência de um gate anterior. Uma capability MCP MUST ser considerada homologada
somente após chamada real ao processo runtime usando os argumentos literais previstos no
contrato e validação do resultado observável.

### XVI. Contratos Autossuficientes e Validados na Fonte
Toda Tool, Resource e Prompt MCP MUST declarar schemas explícitos e versionáveis para
entrada e saída. O contrato MUST definir campos obrigatórios e opcionais, enumerações,
limites, formatos, unidades, semântica de ausência e condições de erro. A validação MUST
ocorrer na fronteira mais próxima da fonte do dado. O agente consumidor MUST NOT ser
obrigado a inferir tipos, completar campos ausentes, reconstruir payloads ou interpretar
texto livre para recuperar estrutura que o MCP poderia produzir deterministicamente.
Campos de proveniência, estado, timestamp, confiança ou decisão MUST NOT ser inventados
quando não forem fornecidos ou deterministicamente deriváveis.

### XVII. Persistência Durável e Retomabilidade
Operações compostas, longas ou sujeitas a interrupção MUST persistir estado suficiente
para retomada segura, incluindo identificador da execução, versão do contrato, etapa
atual, etapas concluídas, próximo trabalho elegível, checkpoints, erros terminais e dados
necessários para evitar repetição indevida. A retomada MUST ocorrer a partir do último
checkpoint confirmado, nunca pela reconstrução exclusiva do estado a partir da conversa
do agente. Checkpoints MUST ser persistidos atomicamente; uma interrupção entre
processamento e persistência MUST NOT produzir avanço parcial apresentado como concluído.
O agente e a conversa MUST NOT ser tratados como fonte canônica de estado.
Operações com estado persistido para retomada MUST possuir teste de integração que
interrompa a execução em um checkpoint, reinicie o processo e retome pelo identificador
persistido. O teste MUST demonstrar que o trabalho confirmado não foi repetido e que o
trabalho incompleto não foi marcado como concluído.

### XVIII. Falha Explícita, Retry Controlado e Ausência de Fallback Oculto
Falhas MUST produzir códigos estruturados e acionáveis. Retry MUST ocorrer somente para
falhas classificadas como transitórias, com limite de tentativas, atraso controlado,
idempotência comprovada e registro observável. O MCP MUST NOT executar retry ilimitado,
trocar silenciosamente de provider, reduzir critérios, omitir filtros, reconstruir
argumentos ou usar fonte alternativa sem previsão no contrato. Divergências como
`SCHEMA_MISMATCH`, `TOOL_NOT_FOUND`, `UNKNOWN_CAPABILITY`,
`AUTHORIZATION_REQUIRED` e `AGENT_CONTRACT_GAP` MUST interromper o gate correspondente.

### XIX. Fronteiras de Responsabilidade
Cada capacidade MUST ser implementada na camada de menor variabilidade capaz de executá-la
corretamente:

1. Parsing, validação, cálculo, canonicalização, cache, fingerprint, roteamento, transição
   de estado e seleção de próximo trabalho MUST pertencer à MCP Tool.
2. Contexto estável, contratos, catálogos, documentação e estado corrente MUST ser
   expostos como MCP Resources.
3. Estratégia cognitiva pequena, estável e reutilizável MUST ser expressa como MCP Prompt.
4. Interpretação semântica isolada MUST ocorrer no processamento interno da Tool, com
   saída estruturada e validada.
5. Decisão dependente do contexto global MUST pertencer ao agente consumidor.
6. Ambiguidade residual ou consequência relevante MUST ser encaminhada à decisão humana.

Trabalho determinístico MUST NOT ser transferido ao agente consumidor.

### XX. Capability Design First
Cada capability MUST ser classificada como Tool, Resource ou Prompt antes da
implementação. Resources MUST ser usados para leitura de conteúdo estável, identificável
e endereçável; Tools MUST ser usados para consultas parametrizadas, cálculos, transições
de estado ou ações; Prompts MUST ser usados para estratégia reutilizável que não possa
ser expressa como código determinístico. Operações mutáveis MUST ser Tools explícitas e
MUST NOT ser efeitos colaterais de leitura.

Cada Tool MUST possuir uma responsabilidade de negócio, resultado observável e condição
clara de conclusão. Tools genéricas como `execute`, `query`, `process` ou `manage`
SHOULD NOT ser aceitas sem justificativa arquitetural.

### XXI. Proveniência, Autoridade e Freshness
Resultados derivados de provider, cache, snapshot ou persistência local MUST indicar sua
origem e condição de atualização quando isso afetar a decisão do consumidor. Quando
aplicável, o contrato MUST diferenciar fonte autoritativa, cache não autoritativo,
snapshot histórico, dado calculado, dado indisponível e dado potencialmente desatualizado.
O uso de cache MUST NOT ser apresentado como consulta bem-sucedida à fonte autoritativa.

### XXII. Mutação Segura e Autorização Explícita
Operações de diagnóstico, desenvolvimento e homologação MUST utilizar providers e
credenciais em modo read-only, salvo requisito explícito em contrário. Tools mutáveis
MUST declarar efeito esperado, recurso afetado, pré-condições, autorização requerida,
chave de idempotência, possibilidade de dry-run, mecanismo de rollback ou compensação e
evidência de execução. Uma Tool de leitura MUST NOT produzir efeitos colaterais. Uma
operação mutável MUST NOT ser executada como fallback de uma operação de consulta.

### XXIII. Build Reproduzível e Cadeia de Suprimentos
O projeto MUST fixar versões de runtime e dependências por lockfile. Builds de
homologação MUST ser reproduzíveis e executados a partir de ambiente limpo. Dependências
MUST ser submetidas a análise de vulnerabilidades e licenças. Imagens de contêiner MUST
utilizar versões ou digests explícitos e SHOULD executar como usuário não privilegiado.
O artefato homologado MUST ser identificável por versão e commit.

## Stack e Arquitetura

O projeto MUST utilizar TypeScript para o código da aplicação. O cache local MUST ser
acessado através de abstrações de infraestrutura. MongoDB é a implementação padrão
atual do cache; a lógica de negócio MUST NOT depender diretamente de MongoDB. A
implementação MUST seguir as práticas recomendadas para servidores MCP e respeitar o
Intelligence Budget: priorizar dados relevantes, limitar respostas excessivas e evitar
trabalho ou contexto redundante.
Docker MUST ser utilizado para executar o MongoDB e os demais sistemas de apoio
necessários ao desenvolvimento ou à execução do projeto.
Builds de homologação MUST executar `npm ci`, typecheck, lint, build limpo, testes,
auditoria de dependências e varredura de secrets. MUST ser gerada uma SBOM, preferencialmente
em CycloneDX ou SPDX. Imagens de contêiner MUST ser analisadas com Trivy, Grype ou
ferramenta corporativa equivalente.

## Qualidade e Convenções de Contribuição

O projeto MUST adotar um único framework principal de testes, declarado no plano técnico.
Para projetos TypeScript, Jest ou o test runner nativo do Node.js MAY ser utilizado
conforme a baseline do repositório. Toda regra de negócio MUST ser coberta por teste
unitário e todas as tools MUST ser cobertas por testes de integração, conforme os
princípios desta Constituição.

O projeto MUST adotar convenção linguística consistente. Identificadores públicos,
nomes de Tools, Resources, Prompts, schemas e códigos de erro SHOULD utilizar inglês
técnico quando destinados à interoperabilidade entre clientes e equipes. Documentação
e mensagens destinadas aos operadores MAY utilizar português. Commits MUST seguir o
formato `tipo(escopo): descrição [REQ-identificador]`, incluindo o identificador do
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

**Version**: 4.0.0 | **Ratified**: TODO(RATIFICATION_DATE): confirmar data original de adoção | **Last Amended**: 2026-11-15
