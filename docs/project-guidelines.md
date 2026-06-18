# Regras e aprendizados do QuickPresence

Este documento é a fonte central das decisões de arquitetura, regras de
engenharia e aprendizados operacionais do QuickPresence. Ele deve ser atualizado
quando uma decisão importante mudar ou quando um problema gerar um aprendizado
reutilizável.

Em caso de conflito:

1. segurança e integridade dos dados têm prioridade;
2. o comportamento coberto por testes representa o contrato atual;
3. este documento orienta novas implementações;
4. o escopo do produto está em `docs/quick_presence_escopo_cs50.md`;
5. o deploy está detalhado em `docs/production-oracle-deploy.md`.

## 1. Objetivos do projeto

O QuickPresence deve continuar sendo uma aplicação simples para criar listas de
presença temporárias, compartilhar formulários por link ou QR Code, receber
respostas e exportar dados.

Princípios do produto:

- participantes não precisam criar conta;
- apenas o proprietário acessa e administra suas listas;
- cada lista aceita no máximo cinco campos personalizados;
- datas são armazenadas em UTC e apresentadas no fuso da lista;
- respostas expiram conforme a política de retenção definida pelo produto;
- links públicos usam tokens difíceis de adivinhar;
- o fluxo principal deve funcionar bem em dispositivos móveis;
- simplicidade operacional tem prioridade sobre escalabilidade prematura.

## 2. Arquitetura atual

Stack principal:

- Ruby on Rails full-stack;
- ERB, Turbo e Stimulus;
- Bootstrap e Tailwind CSS;
- Devise para autenticação;
- SQLite para banco principal, cache, fila e Action Cable;
- Solid Cache e Solid Queue;
- Active Storage local;
- Caddy como proxy reverso e terminador HTTPS;
- Docker Compose para execução em produção.

Responsabilidades por camada:

- `controllers`: recebem requisições, autorizam o acesso, coordenam operações e
  escolhem a resposta;
- `models`: representam dados, relacionamentos, validações e regras diretamente
  ligadas ao estado da entidade;
- `services`: executam operações ou transformações com responsabilidade própria,
  como exportação, geração de PDF e limpeza de respostas;
- `jobs`: agendam e iniciam trabalho assíncrono, delegando lógica complexa;
- `views` e `helpers`: apresentam dados sem concentrar regras de negócio;
- `app/javascript/controllers`: comportamento progressivo da interface;
- `config/locales`: todo texto apresentado ao usuário;
- `docs`: decisões, regras, escopo, operação e aprendizados versionados.

## 3. SOLID

Toda nova arquitetura e alteração relevante deve considerar os princípios SOLID.
Eles orientam decisões, mas não justificam abstrações desnecessárias. Uma solução
simples e clara é preferível a uma hierarquia criada apenas para parecer
flexível.

### 3.1 Responsabilidade única

Cada classe ou módulo deve ter um motivo principal para mudar.

- controllers não devem gerar CSV, XLSX, PDF ou QR Code diretamente;
- jobs não devem duplicar regras presentes em services ou models;
- services devem representar uma operação coesa;
- helpers não devem consultar ou modificar o banco;
- models não devem conhecer detalhes de HTTP ou renderização.

Quando uma classe acumular validação, persistência, formatação e integração,
separe responsabilidades apenas onde houver uma fronteira clara.

### 3.2 Aberto para extensão, fechado para modificação

Novos comportamentos devem ser adicionados sem espalhar condicionais por várias
camadas.

- formatos de exportação devem compartilhar uma representação comum dos dados;
- novos serviços de armazenamento devem usar a interface do Active Storage;
- novos idiomas devem ser adicionados por arquivos de locale;
- novos comportamentos de entrega devem respeitar interfaces do Rails.

Não é necessário criar plugins ou registries antes de existir uma segunda
implementação real.

### 3.3 Substituição de Liskov

Implementações que respeitam o mesmo contrato devem poder ser trocadas sem
surpresas.

- subclasses e adapters devem preservar entradas, saídas e erros esperados;
- doubles de teste devem reproduzir o contrato utilizado pelo código;
- uma implementação não deve exigir pré-condições mais restritivas que a
  abstração que substitui.

Herança deve ser usada com cautela. Composição e objetos pequenos normalmente
são mais claros.

### 3.4 Segregação de interfaces

Objetos não devem depender de métodos que não utilizam.

- passe para um service apenas os dados ou objetos necessários;
- evite objetos genéricos que conhecem toda a aplicação;
- prefira APIs pequenas e explícitas, como `call`, `render` ou `to_csv`, quando
  elas descrevem corretamente a operação;
- não use concerns extensos para compartilhar responsabilidades sem relação.

### 3.5 Inversão de dependência

Regras de negócio não devem ficar presas a detalhes externos quando uma
dependência substituível trouxer benefício real.

- use APIs do Rails para armazenamento, jobs, e-mail e tempo;
- injete relógio, renderer ou gateway quando isso tornar uma regra testável ou
  permitir implementações reais diferentes;
- evite acessar serviços externos diretamente em controllers e models;
- não crie interfaces artificiais para dependências estáveis e triviais.

## 4. Regras de implementação

- seguir os padrões e convenções existentes do Rails antes de criar estrutura
  própria;
- manter alterações pequenas e relacionadas ao requisito;
- evitar duplicação significativa, sem abstrair coincidências superficiais;
- usar APIs estruturadas para CSV, YAML, JSON, datas e URLs;
- usar nomes em inglês no código, banco, testes, commits e documentação pública;
- documentos em `docs/` podem ser escritos em português;
- adicionar comentários apenas quando explicarem uma decisão não evidente;
- não incluir código morto, segredos, chaves reais ou exemplos inseguros;
- migrations aplicadas em produção devem ser tratadas como histórico imutável;
- mudanças destrutivas de banco exigem backup e plano de rollback;
- dependências novas precisam de justificativa, manutenção ativa e impacto
  aceitável na imagem.

Antes de criar uma nova abstração, confirme pelo menos um destes benefícios:

- reduz complexidade observável;
- remove duplicação relevante;
- isola uma integração externa;
- estabelece um contrato que possui mais de uma implementação;
- melhora de forma concreta a testabilidade.

## 5. Controllers, autorização e parâmetros

- toda ação autenticada deve partir de `current_user`;
- listas devem ser carregadas por `current_user.attendance_lists`, nunca por uma
  busca global seguida de comparação;
- rotas públicas só podem encontrar listas pelo `public_token`;
- parâmetros recebidos devem passar por Strong Parameters;
- controllers devem permanecer focados em fluxo HTTP;
- operações com várias etapas ou formatos devem ser delegadas a services;
- mensagens e redirects devem usar I18n.

Uma alteração não pode permitir que um usuário consulte, altere, exporte ou
exclua dados pertencentes a outro usuário.

## 6. Models e integridade dos dados

- validações de domínio devem existir no model mesmo que a interface também
  valide;
- associações e exclusões em cascata devem ser deliberadas;
- regras críticas devem ser reforçadas por constraints ou índices no banco
  quando possível;
- tokens públicos devem ser gerados com fonte criptograficamente segura e ter
  índice único;
- timestamps enviados pelo participante não são confiáveis; `submitted_at` é
  definido pelo servidor;
- datas devem ser persistidas em UTC;
- o fuso original da lista deve permanecer salvo;
- consultas repetidas devem evitar N+1 e carregar somente os dados necessários;
- alterações envolvendo retenção devem preservar o prazo de 48 horas definido
  pelo produto, salvo mudança explícita do requisito.

## 7. Services e jobs

Um service é apropriado quando existe uma operação coesa que não pertence
naturalmente a um único model ou controller.

Regras:

- nomear pelo resultado ou operação;
- expor uma API pequena;
- receber dependências pelo inicializador ou método principal;
- evitar estado global;
- retornar resultado previsível ou lançar erro específico;
- não esconder efeitos colaterais importantes;
- cobrir a regra principal com teste unitário.

Jobs devem:

- ser seguros para repetição sempre que possível;
- delegar a operação principal a models ou services;
- trabalhar em lotes quando o volume puder crescer;
- registrar falhas sem expor dados pessoais;
- não assumir que dados ainda existem quando forem executados.

## 8. Interface e internacionalização

- nenhum texto visível ao usuário deve ser inserido diretamente em controllers,
  views ou JavaScript quando puder usar I18n;
- inglês é o locale padrão;
- `pt-BR` deve manter paridade de chaves com inglês;
- novos textos exigem atualização dos dois catálogos;
- formulários devem manter labels, mensagens de erro e estados acessíveis;
- envios públicos bem-sucedidos devem redirecionar para uma página final de
  confirmação, sem renderizar novamente o formulário vazio;
- JavaScript deve melhorar a experiência, não impedir o fluxo básico;
- links públicos e QR Codes devem usar URLs absolutas derivadas do host e
  protocolo corretos;
- a interface deve priorizar telas pequenas e ações claras.

## 9. Segurança e privacidade

- `.env`, `config/master.key` e credenciais reais nunca entram no Git;
- `.env_model` documenta nomes e valores fictícios;
- parâmetros sensíveis devem ser filtrados dos logs;
- produção deve usar HTTPS e cookies seguros;
- `APP_DOMAIN` define o host permitido em produção;
- somente Caddy expõe portas públicas; Rails permanece na rede interna;
- não expor SQLite, consoles, debug ou endpoints administrativos;
- o projeto deve informar o uso de cookies e armazenamento essenciais em
  `/privacy`;
- cookies, pixels, analytics ou armazenamento não essencial devem ser
  desativados por padrão e carregados somente após consentimento claro;
- o aviso de privacidade pode gravar apenas uma preferência local para lembrar
  que o usuário já reconheceu o aviso;
- não confiar em IDs, tokens, locale, timezone ou campos enviados pelo cliente
  sem validação;
- evitar registrar respostas de presença e outros dados pessoais;
- atualizar gems e imagens base após verificar compatibilidade e testes;
- rotação de `secret_key_base` invalida cookies, sessões e tokens assinados;
- rotação de `RAILS_MASTER_KEY` exige recriptografar credentials e preservar a
  nova chave fora do repositório.

## 10. Testes e qualidade

Toda correção de bug deve incluir um teste que falharia antes da correção quando
isso for viável.

Cobertura esperada:

- models: validações, associações, estados e regras de tempo;
- controllers: autenticação, autorização, respostas e formatos;
- services: transformação, ordenação e efeitos da operação;
- jobs: seleção dos registros e delegação;
- I18n: paridade entre catálogos;
- fluxos públicos: lista aberta, fechada, futura, expirada e parâmetros
  inválidos.

Antes de integrar uma alteração:

```bash
bin/rails test
```

Em ambientes que bloqueiam sockets usados pelos testes paralelos:

```bash
PARALLEL_WORKERS=1 bin/rails test
```

Também devem ser executadas as verificações específicas disponíveis no projeto,
como análise de segurança, lint e validação de assets, quando a área alterada
for afetada.

## 11. Produção, containers e persistência

Aprendizados obrigatórios:

- não construir a imagem Rails em VM com pouca memória;
- criar a imagem em máquina adequada ou CI e publicar uma tag versionada;
- confirmar a arquitetura da VM antes do build (`amd64` ou `arm64`);
- o ambiente de produção validado atualmente usa Oracle
  `VM.Standard.E2.1.Micro`, Ubuntu Minimal e imagem `linux/amd64`;
- a `VM.Standard.E2.1.Micro` deve ter swap configurada, mas swap não substitui
  memória suficiente para realizar builds;
- domínios em produção devem apontar para um IP público reservado, não para um
  endereço efêmero;
- os arquivos operacionais ficam em `~/quick_presence`, enquanto dados
  persistentes permanecem em `/var/lib/quick_presence`;
- Docker Desktop no Windows precisa ter integração com a distribuição WSL;
- não depender somente de `latest`;
- o container é descartável, mas os dados não são;
- SQLite e uploads ficam no host em
  `/var/lib/quick_presence/storage`;
- dados e certificados do Caddy devem persistir fora dos containers;
- trocar a imagem não pode substituir o diretório de storage;
- o Caddy emite e renova certificados gratuitamente depois que DNS e firewall
  estão corretos;
- portas `80` e `443` precisam estar abertas na Oracle Cloud e na VM;
- apenas o Caddy publica portas para a internet;
- certificados devem ser testados pelo domínio, não pelo endereço IP;
- DNS deve possuir um único registro `A` ativo para o domínio raiz;
- `db:prepare` aplica migrations na inicialização do container Rails;
- rollback de imagem não reverte migrations;
- backups devem existir fora da VM.

Não executar em produção sem compreender o efeito:

```bash
docker compose down -v
docker volume prune
docker system prune --volumes
```

O procedimento completo está em `docs/production-oracle-deploy.md`.

## 12. SQLite

SQLite atende ao escopo atual porque a aplicação roda em uma única VM com carga
moderada.

Regras:

- não compartilhar o arquivo por filesystem de rede entre vários servidores;
- manter somente uma instância web gravando no banco, salvo validação técnica
  específica;
- preservar arquivos auxiliares de WAL durante operação e backup;
- fazer backup consistente com a aplicação parada ou usando ferramenta própria
  do SQLite;
- monitorar espaço em disco;
- preparar diretório com permissão para UID/GID `1000`;
- considerar PostgreSQL antes de usar múltiplas VMs, alta concorrência de
  escrita ou alta disponibilidade.

## 13. Git e documentação

- todo o diretório `docs/` é versionado;
- documentos não devem conter segredos ou caminhos privados desnecessários;
- uma decisão arquitetural relevante deve atualizar este arquivo;
- mudanças no deploy devem atualizar o runbook correspondente;
- mudanças no produto devem atualizar o escopo;
- documentação obsoleta deve ser corrigida ou removida;
- exemplos devem utilizar valores fictícios;
- arquivos gerados, bancos, uploads e segredos continuam ignorados.

Ao revisar uma mudança, verificar:

1. o comportamento está testado;
2. os princípios SOLID foram considerados sem excesso de abstração;
3. autorização e integridade dos dados foram preservadas;
4. novos textos estão internacionalizados;
5. secrets não foram incluídos;
6. migrations e deploy possuem caminho seguro;
7. documentação relevante foi atualizada.

## 14. Processo para novas decisões

Antes de implementar uma mudança de arquitetura:

1. registrar o problema concreto;
2. identificar quais camadas são responsáveis;
3. avaliar a solução mais simples compatível com SOLID;
4. considerar segurança, dados, deploy e rollback;
5. implementar com testes proporcionais ao risco;
6. atualizar este documento quando surgir uma regra reutilizável.

SOLID não significa criar muitas classes. Para o QuickPresence, boa arquitetura
significa responsabilidades claras, dependências controladas, regras protegidas
por testes e operação compreensível em uma VM pequena.
