<!--
Sync Impact Report
Version change: 4.0.0 → 5.0.0
Modified principles: I–XI, XIII–XV, XIX.
Added principles: XXIV–XXXIV.
Added sections: Documentação Operacional Obrigatória.
Modified sections: Stack e Arquitetura; Qualidade e Convenções de Contribuição; Governance.
Removed sections: None.
Follow-up TODOs: Confirm the original ratification date.
-->

# Constituição de Engenharia de MCPs para OpenClaw

## Core Principles

### I. Regras de Negócio Testáveis
Toda regra de negócio MUST possuir pelo menos um teste unitário que verifique seu
comportamento esperado e casos-limite relevantes. Alterações em regras de negócio MUST
atualizar ou acrescentar os testes correspondentes.

### II. Integração de Todas as Capabilities
Cada Tool MCP MUST possuir pelo menos um teste de integração que valide sua entrada,
saída e comportamento observável por meio da interface MCP. Os testes MUST cobrir os
contratos relevantes com dependências externas, providers, repositórios, persistência e
adaptadores usados pela Tool. Resources e Prompts externos MUST possuir testes
equivalentes de descoberta, exposição e consumo.

### III. Intelligence Budget
Cada capability MUST retornar somente as informações necessárias para atender à
solicitação, com saída concisa, estruturada e sem duplicação desnecessária. Quando
aplicável, MUST oferecer filtros, limites ou paginação para evitar respostas excessivas e
preservar o orçamento de contexto, decisões e tokens do agente consumidor.

### IV. Cache Local Não Autoritativo
Informações recuperadas de uma fonte externa e armazenadas em cache local MUST ser
tratadas como cache, nunca como fonte autoritativa. A lógica de negócio MUST acessar o
cache por abstrações de infraestrutura, sem dependência direta de sua implementação. O
uso do cache MUST preservar a possibilidade de obter dados atualizados da fonte conforme
as regras de negócio, validade, proveniência e freshness dos dados.

### V. Contratos MCP Orientados ao Consumidor
Tools, Resources, Prompts e seus contratos MUST ser projetados para uso previsível por
OpenClaw e demais clientes MCP compatíveis, com nomes, descrições, parâmetros,
resultados e erros claros. Mudanças incompatíveis MUST ser explicitadas, versionadas e
acompanhadas dos ajustes de integração necessários.

### VI. Tool Design First
Toda Tool MCP MUST realizar uma única responsabilidade de negócio claramente
identificável. Tools genéricas ou multifuncionais SHOULD ser divididas em operações
menores, previsíveis e composáveis para maximizar a capacidade de planejamento do
agente consumidor.

### VII. Determinismo de Resposta
Toda capability MUST produzir estrutura consistente e validável para sucesso, ausência de
resultado e erro. Variações dependentes de transporte MUST NOT alterar a semântica
funcional do contrato.

### VIII. MCP Resource First
Informações predominantemente consultivas SHOULD ser expostas como MCP Resources sempre
que possível. Tools MUST ser reservadas para operações parametrizadas, cálculos,
transições de estado ou ações. Prompts MUST ser reservados para estratégias reutilizáveis
que não possam ser expressas como código determinístico.

### IX. Observabilidade sem Vazamento de Dados
Logs MUST registrar metadados operacionais, identificadores de correlação, duração,
resultado, código de erro, provider, transporte e versão do contrato. Payloads completos e
parâmetros sensíveis MUST NOT ser registrados por padrão. A observabilidade MUST utilizar
allowlist de campos seguros, redaction centralizada e correlação por `requestId`, `runId`,
`sessionId` e `checkpointId`, quando aplicáveis.

### X. Segurança e Limitação de Escopo
Toda capability MUST expor apenas os dados necessários para a tarefa solicitada. Dados
internos, segredos, credenciais e informações sensíveis MUST NOT ser retornados ao modelo
ou registrados indevidamente. O fato de uma fonte ser pública MUST NOT justificar acesso
arbitrário a URLs, ausência de controles contra abuso ou habilitação implícita de
operações mutáveis.

### XI. Versionamento de Contratos MCP
Alterações incompatíveis em parâmetros, nomes, schemas, formatos de retorno, códigos de
erro ou semântica MUST resultar em incremento de versão do contrato MCP e coexistência
temporária da versão anterior quando tecnicamente viável. Os transportes oficiais MUST
expor a mesma versão de contrato para a mesma release.

### XII. Política Mensurável de Paginação
Toda operação potencialmente não limitada MUST implementar paginação por cursor ou limite
equivalente. O tamanho padrão da página MUST ser definido por domínio e MUST respeitar
limites de payload, latência e contexto. O servidor MUST limitar `pageSize`, mesmo quando
o cliente solicitar valor superior. Respostas truncadas MUST indicar `hasMore` e
`nextCursor`. Paginação por cursor SHOULD ser preferida quando os dados puderem mudar
durante a leitura.

### XIII. Princípio de Idempotência
Tools de leitura MUST ser idempotentes. Tools mutáveis SHOULD ser idempotentes sempre
que possível e MUST declarar chave de idempotência ou estratégia equivalente quando
repetição puder causar efeitos indevidos.

### XIV. Testes de Consumo pelo Agente
Toda capability externa MUST possuir testes que validem sua descoberta e utilização por
um cliente MCP compatível. Os testes MUST utilizar os contratos publicados e MUST NOT
depender de conhecimento oculto sobre a implementação.

### XV. Evidência por Gate
Uma implementação MUST NOT ser considerada concluída apenas por compilar ou passar em
testes unitários. A homologação MUST registrar separadamente os estados de Design, Code,
Contract, Wiring, Typecheck, Build, Unit Tests, Integration Tests, Regression, Runtime
stdio, Runtime Streamable HTTP, Parity e Operational. A aprovação de um gate posterior
MUST NOT se basear exclusivamente em evidência de um gate anterior. Uma capability MCP
MUST ser considerada homologada somente após chamada real ao artefato empacotado, com
argumentos literais previstos no contrato e validação do resultado observável.

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
Cada capability MUST ser implementada na camada de menor variabilidade capaz de
executá-la corretamente:

- parsing, validação, cálculo, canonicalização, cache, fingerprint, roteamento, transição
  de estado e seleção de próximo trabalho MUST pertencer ao núcleo MCP;
- contexto estável, contratos, catálogos, documentação e estado corrente MUST ser
  expostos como MCP Resources;
- estratégia cognitiva pequena, estável e reutilizável MUST ser expressa como MCP Prompt;
- interpretação semântica isolada MUST ocorrer no processamento interno do núcleo, com
  saída estruturada e validada;
- decisão dependente do contexto global MUST pertencer ao agente consumidor;
- ambiguidade residual ou consequência relevante MUST ser encaminhada à decisão humana.

Trabalho determinístico MUST NOT ser transferido ao agente consumidor ou aos adaptadores
de transporte.

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

### XXIV. Estratégia Dual de Transportes Oficiais
O produto MCP MUST oferecer simultaneamente dois transportes oficiais:

- stdio, destinado ao desenvolvimento local, depuração, testes automatizados, testes de
  contrato e integração com clientes que iniciam o servidor como subprocesso;
- Streamable HTTP, destinado à homologação e produção, nas quais o MCP é executado como
  serviço independente e acessado por endpoint HTTP.

Os dois transportes MUST pertencer à mesma base de código, ser distribuídos a partir do
mesmo commit, versão e artefato e expor capabilities funcionalmente equivalentes. stdio
MUST NOT ser utilizado como mecanismo de publicação em homologação ou produção.
Streamable HTTP MUST ser exercitado e homologado antes da promoção para produção.

### XXV. Núcleo MCP Único e Independente de Transporte
Tools, Resources, Prompts, schemas, providers, regras de negócio, persistência e políticas
de validação MUST pertencer a um núcleo independente de transporte. Os adaptadores stdio
e Streamable HTTP MUST ser finos e responsáveis somente por inicialização, conexão, ciclo
de vida, controle de sessão, cancelamento e entrega das mensagens MCP.

É proibido:

- duplicar implementação de Tools, Resources ou Prompts por transporte;
- introduzir regras de negócio nos adaptadores stdio ou HTTP;
- manter contratos diferentes para a mesma capability;
- aplicar uma correção funcional somente a um transporte;
- acoplar providers ou persistência ao ciclo de vida de um transporte específico;
- criar divergência semântica de validação, erro ou efeito persistente entre transportes.

### XXVI. EntryPoints Explícitos e Independentes
O projeto MUST disponibilizar entrypoints independentes para stdio e Streamable HTTP. A
seleção do transporte MUST ocorrer por comando explícito, entrypoint dedicado ou
configuração validada, sem autodetecção ambígua.

São exemplos conformes:

- `npm run start:stdio`;
- `npm run start:http`;
- `node dist/stdio.js`;
- `node dist/http.js`.

O mesmo artefato MAY conter os dois entrypoints, mas cada processo MUST iniciar apenas o
transporte explicitamente selecionado. Um processo MUST NOT iniciar simultaneamente
stdio e Streamable HTTP por efeito colateral ou autodetecção.

### XXVII. Isolamento de Ciclo de Vida, Processo e Sessão
Embora os dois transportes sejam suportados pelo mesmo produto, eles MUST NOT
compartilhar a mesma instância ativa de McpServer. Cada processo, conexão ou sessão MUST
criar sua própria instância MCP conforme o modelo exigido pelo SDK adotado.

O encerramento de stdin MUST NOT afetar uma instância HTTP. Falhas, sessões,
cancelamentos, notificações ou buffers HTTP MUST NOT interferir na execução stdio.
Componentes stateless, pools, caches controlados e repositórios persistentes MAY ser
compartilhados somente quando forem seguros para concorrência e não carregarem contexto
de sessão ou transporte.

### XXVIII. Paridade Funcional entre Transportes
Toda Tool, Resource ou Prompt destinada a uso externo MUST estar disponível em stdio e
Streamable HTTP, salvo exceção explicitamente documentada, justificada e aprovada por
decisão arquitetural.

A pipeline MUST possuir gate automatizado de paridade que valide, no mínimo:

- nomes das capabilities expostas;
- schemas de entrada;
- schemas de saída;
- códigos e envelopes de erro;
- validações;
- efeitos persistentes;
- comportamento de cancelamento;
- versão do protocolo e capabilities declaradas;
- resultados de um conjunto determinístico de chamadas.

Compilação bem-sucedida MUST NOT ser aceita como prova de paridade, wiring ou exposição
efetiva.

### XXIX. Estratégia de Transporte por Ambiente
A estratégia padrão MUST ser:

- desenvolvimento: stdio;
- testes locais e testes de contrato: stdio, complementados por testes Streamable HTTP;
- homologação: Streamable HTTP;
- produção: Streamable HTTP.

A aprovação de testes exclusivamente por stdio MUST NOT homologar uma release destinada
a HTTP. O artefato MUST ser exercitado por Streamable HTTP em ambiente equivalente à
produção antes da promoção.

### XXX. Requisitos Mínimos do Streamable HTTP
O transporte Streamable HTTP MUST implementar, mesmo quando autenticação estiver
temporariamente fora do escopo:

- endpoint MCP explícito, preferencialmente `/mcp`;
- validação dos métodos HTTP permitidos e do Content-Type;
- validação estrita de Origin por allowlist;
- limite configurável de tamanho de requisição;
- timeout de conexão e de execução;
- limite de concorrência;
- rate limiting ou proteção equivalente contra abuso;
- validação estrita dos schemas;
- allowlist dos hosts acessados pelos providers;
- proteção contra SSRF;
- tratamento controlado de redirecionamentos, com limite e revalidação do destino;
- IDs de correlação;
- logs estruturados sem conteúdo sensível;
- graceful shutdown;
- health check e readiness check separados do endpoint MCP.

A ausência temporária de autenticação MUST ser registrada em ADR, com escopo, riscos,
controles compensatórios, responsável e condição para revisão. Fonte pública MUST NOT
autorizar Tool mutável, proxy genérico, acesso arbitrário a URL ou remoção de controles
contra abuso.

### XXXI. Disciplina do stdio
No transporte stdio:

- stdout MUST conter exclusivamente mensagens MCP válidas;
- logs, diagnósticos e mensagens operacionais MUST ser enviados para stderr;
- banners, mensagens de inicialização e logs MUST NOT contaminar stdout;
- o processo MUST responder corretamente ao encerramento de stdin e aos sinais de término;
- testes MUST detectar qualquer escrita inválida em stdout;
- falhas de inicialização MUST ser reportadas em stderr e por exit code não zero, sem
  emissão de payload MCP inválido.

### XXXII. Configuração Fail-Closed
Toda configuração MUST ser validada antes da inicialização do transporte e do anúncio de
readiness. Para Streamable HTTP, MUST ser validado no mínimo:

- host de bind;
- porta;
- caminho do endpoint MCP;
- timeouts;
- limite de payload;
- limite de concorrência;
- política e allowlist de Origin;
- allowlist de hosts dos providers;
- política de redirecionamento;
- parâmetros de rate limiting ou proteção equivalente.

Configuração ausente, inválida ou insegura MUST causar falha explícita de inicialização.
O projeto MUST NOT utilizar defaults silenciosos que exponham o servidor em interfaces
de rede não pretendidas. Bind em interfaces não locais, como `0.0.0.0` ou `::`, MUST
exigir configuração explícita adequada ao ambiente.

### XXXIII. Gates Obrigatórios de Transporte e Homologação
A pipeline de qualidade e entrega MUST implementar os seguintes gates:

**Gate A — Build e análise estática**

- build;
- typecheck;
- lint;
- validação dos schemas.

**Gate B — Contrato do núcleo**

- Tools, Resources e Prompts registrados, quando aplicáveis;
- schemas de entrada e saída;
- erros determinísticos;
- providers e persistência corretamente conectados;
- ausência de regras de negócio nos adaptadores de transporte.

**Gate C — Runtime stdio**

- initialize;
- tools/list;
- resources/list, quando aplicável;
- prompts/list, quando aplicável;
- tools/call;
- cancelamento;
- encerramento limpo;
- ausência de logs ou conteúdo inválido em stdout.

**Gate D — Runtime Streamable HTTP**

- inicialização do serviço;
- health e readiness;
- initialize pelo endpoint MCP;
- tools/list;
- resources/list, quando aplicável;
- prompts/list, quando aplicável;
- tools/call;
- sessões, quando habilitadas;
- cancelamento;
- limites de payload, concorrência e timeout;
- Origin permitido e rejeitado;
- proteção contra SSRF e redirecionamentos indevidos;
- encerramento controlado.

**Gate E — Paridade**

- comparação automatizada das capabilities e schemas expostos por stdio e Streamable HTTP;
- comparação dos códigos e envelopes de erro;
- comparação de resultados para conjunto determinístico de chamadas;
- comprovação de que os dois transportes utilizam o mesmo núcleo funcional.

**Gate F — Homologação**

- execução do artefato empacotado, não apenas do código-fonte;
- execução por Streamable HTTP em ambiente equivalente à produção;
- coleta de evidências, logs, versões, comandos, exit codes e resultados;
- promoção somente após aprovação de todos os gates aplicáveis.

Falha em qualquer gate MUST impedir a promoção até correção ou exceção formalmente
aprovada e registrada.

### XXXIV. Empacotamento e Operação Consistentes
A distribuição MUST permitir iniciar stdio e Streamable HTTP a partir do mesmo commit,
versão e artefato. A imagem homologada MUST ser a mesma promovida para produção.
Alterações de comportamento entre ambientes MUST ocorrer apenas por configuração
validada, nunca por recompilação não rastreada ou alteração manual do artefato.

O processo HTTP MUST executar sem privilégios administrativos, ser compatível com
contêiner, expor sinais apropriados para liveness, readiness e graceful shutdown e
preservar correlação observável durante o encerramento. Os entrypoints MUST compartilhar
o núcleo e os contratos, mas MUST manter ciclos de vida independentes.

## Stack e Arquitetura

O projeto MUST utilizar TypeScript para o código da aplicação. A arquitetura MUST
separar explicitamente:

- núcleo MCP independente de transporte;
- factories de McpServer e registro de capabilities;
- adaptador e entrypoint stdio;
- adaptador e entrypoint Streamable HTTP;
- providers e adaptadores externos;
- abstrações de persistência e cache;
- configuração validada;
- observabilidade compartilhada sem estado de sessão.

O cache local MUST ser acessado por abstrações de infraestrutura. MongoDB é a
implementação padrão atual do cache; a lógica de negócio MUST NOT depender diretamente
de MongoDB nem de um transporte específico. Docker MUST ser utilizado para executar
MongoDB e os demais sistemas de apoio necessários ao desenvolvimento, testes,
homologação ou execução.

Builds de homologação MUST executar instalação reproduzível por lockfile, typecheck,
lint, build limpo, testes, auditoria de dependências e varredura de secrets. MUST ser
gerada uma SBOM, preferencialmente em CycloneDX ou SPDX. Imagens de contêiner MUST ser
analisadas com Trivy, Grype ou ferramenta corporativa equivalente.

## Qualidade e Convenções de Contribuição

O projeto MUST adotar um único framework principal de testes, declarado no plano técnico.
Para projetos TypeScript, Jest ou o test runner nativo do Node.js MAY ser utilizado
conforme a baseline do repositório. Toda regra de negócio MUST ser coberta por teste
unitário e todas as capabilities externas MUST ser cobertas por testes de integração e
runtime conforme esta Constituição.

O projeto MUST adotar convenção linguística consistente. Identificadores públicos, nomes
de Tools, Resources, Prompts, schemas e códigos de erro SHOULD utilizar inglês técnico
quando destinados à interoperabilidade entre clientes e equipes. Documentação e
mensagens destinadas aos operadores MAY utilizar português. Commits MUST seguir o
formato `tipo(escopo): descrição [REQ-identificador]`, incluindo o identificador do
requisito relacionado.

## Documentação Operacional Obrigatória

A documentação do projeto MUST incluir:

- comandos de execução stdio e Streamable HTTP;
- matriz ambiente versus transporte;
- variáveis e schemas de configuração;
- endpoints MCP, health e readiness;
- política de Origin, payload, timeout, concorrência e rate limiting;
- allowlist de hosts e política de redirecionamentos dos providers;
- modelo de sessão e cancelamento;
- procedimentos de graceful shutdown;
- definição dos Gates A a F e suas evidências;
- ADRs de exceções, incluindo eventual ausência temporária de autenticação;
- instruções de troubleshooting sem uso indevido de stdout em stdio.

## Governance

Esta Constituição prevalece sobre planos, especificações e práticas locais. Se um plano
contradisser esta Constituição, o plano MUST ser atualizado antes da implementação. Se
uma mudança exigir alteração desta Constituição, sua alteração MUST ser feita em um
commit separado das mudanças de implementação.

Alterações nesta Constituição MUST ser revisadas e registradas com a data da emenda.
A versão MUST seguir SemVer: MAJOR para remoção, redefinição incompatível ou mudança
estrutural de princípios; MINOR para novos princípios ou expansão material compatível;
PATCH para esclarecimentos sem mudança semântica. Revisões de especificações, planos e
mudanças de código MUST verificar conformidade com os princípios, stack, convenções,
transportes e requisitos de teste aqui definidos.

Exceções MUST ser explícitas, limitadas no tempo, aprovadas e registradas em ADR com
justificativa, risco, controles compensatórios, responsável e critério de encerramento.
Nenhuma exceção MAY ser inferida a partir de implementação existente.

**Version**: 5.0.0  
**Ratified**: TODO(RATIFICATION_DATE): confirmar data original de adoção  
**Last Amended**: 2026-11-15
