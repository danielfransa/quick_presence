# Deploy do QuickPresence em uma VM Oracle

Este documento descreve o deploy recomendado do QuickPresence em uma VM pequena
da Oracle Cloud, usando uma imagem criada fora do servidor, Docker Compose,
SQLite persistente e Caddy para HTTPS gratuito.

## 1. Paralelo com o projeto anterior

Os principais aprendizados do deploy anterior continuam válidos:

| Projeto anterior | QuickPresence |
| --- | --- |
| Build do Rails travava a VM de 1 GB | A imagem também deve ser criada fora da VM |
| Imagem pronta era publicada no Docker Hub | O mesmo fluxo é recomendado |
| Caddy emitia e renovava os certificados | O Caddy continua responsável pelo HTTPS |
| PostgreSQL tinha seu próprio container e volume | SQLite fica em um diretório persistente do host |
| Alterar senha do PostgreSQL não alterava volume existente | Não há senha do SQLite, mas o arquivo não pode ser removido ou sobrescrito |
| Banco não ficava exposto publicamente | O Rails também não fica exposto; apenas o Caddy publica portas |

O QuickPresence usa quatro arquivos SQLite em produção:

- `production.sqlite3`
- `production_cache.sqlite3`
- `production_queue.sqlite3`
- `production_cable.sqlite3`

Todos ficam em `/rails/storage` dentro do container. No host, esse diretório é
montado por padrão em `/var/lib/quick_presence/storage`.

## 2. Arquivos envolvidos

- `Dockerfile`: cria a imagem Rails de produção.
- `compose.production.yml`: executa Rails e Caddy.
- `Caddyfile`: encaminha HTTPS para o container Rails.
- `.env_model`: lista as variáveis necessárias.
- `.env`: contém os valores reais e não vai para o Git.
- `bin/prepare-production-storage`: prepara os diretórios persistentes.

Este fluxo usa Docker Compose diretamente. Não execute o deploy com Kamal e
Docker Compose ao mesmo tempo na mesma VM.

## 3. Arquitetura da VM

Antes de criar a imagem, verifique a arquitetura da VM:

```bash
uname -m
```

Use a plataforma correspondente:

| Resultado na VM | Plataforma Docker |
| --- | --- |
| `x86_64` | `linux/amd64` |
| `aarch64` ou `arm64` | `linux/arm64` |

As VMs Oracle Ampere A1 usam ARM. Não reutilize automaticamente a conclusão do
projeto anterior de que local e servidor são ambos `amd64`.

## 4. DNS e rede

No provedor DNS do domínio, crie registros `A` apontando para o IP público da
VM:

```text
quickpresence.xyz      -> IP_PUBLICO_DA_VM
www.quickpresence.xyz  -> IP_PUBLICO_DA_VM (opcional)
```

O setup atual usa `quickpresence.xyz`. O registro `www` precisa de configuração
adicional no `Caddyfile` caso também deva atender ou redirecionar esse host.

Libere as seguintes portas nas regras de ingress da Oracle Cloud:

- `22/tcp`: SSH, preferencialmente apenas para o seu IP.
- `80/tcp`: validação e redirecionamento HTTP.
- `443/tcp`: HTTPS.
- `443/udp`: HTTP/3, opcional, mas configurado no Compose.

As mesmas portas precisam ser permitidas pelo firewall do sistema operacional.
Não publique portas de SQLite ou a porta interna do Rails.

O Caddy só consegue emitir o certificado depois que:

1. o DNS aponta para o IP público correto;
2. as portas `80` e `443` estão acessíveis;
3. nenhum outro processo está usando essas portas;
4. o container Caddy está em execução.

O certificado é gratuito e renovado automaticamente pelo Caddy. Não é
necessário comprar ou fornecer um certificado.

## 5. Criar e publicar a imagem

Escolha uma tag versionada. Evite depender apenas de `latest`, pois uma tag
imutável facilita rollback:

```bash
export APP_IMAGE="seu-usuario/quick_presence:2026-06-12-1"
```

Para uma VM `amd64`:

```bash
docker login
docker buildx build \
  --platform linux/amd64 \
  --tag "$APP_IMAGE" \
  --push .
```

Para uma VM Oracle Ampere ARM:

```bash
docker login
docker buildx build \
  --platform linux/arm64 \
  --tag "$APP_IMAGE" \
  --push .
```

Se `buildx` não estiver disponível e a máquina local tiver a mesma arquitetura
da VM:

```bash
docker build --tag "$APP_IMAGE" .
docker push "$APP_IMAGE"
```

A VM recebe apenas a imagem pronta. Ela não executa `bundle install`,
`assets:precompile` ou outras etapas pesadas do build.

## 6. Preparar os arquivos na VM

Clone o repositório ou envie pelo menos estes arquivos para uma pasta de deploy:

```text
compose.production.yml
Caddyfile
.env_model
bin/prepare-production-storage
```

Na pasta do projeto:

```bash
cp .env_model .env
chmod 600 .env
```

Configure `.env`:

```dotenv
APP_IMAGE=seu-usuario/quick_presence:2026-06-12-1
APP_DOMAIN=quickpresence.xyz
APP_STORAGE_PATH=/var/lib/quick_presence/storage
CADDY_DATA_PATH=/var/lib/quick_presence/caddy/data
CADDY_CONFIG_PATH=/var/lib/quick_presence/caddy/config
RAILS_MASTER_KEY=valor-real-da-chave
```

Regras importantes:

- `APP_DOMAIN` não leva `https://` nem barra no final.
- `RAILS_MASTER_KEY` deve ser igual à chave usada para criptografar
  `config/credentials.yml.enc`.
- Nunca envie `.env` ao GitHub.
- Guarde `RAILS_MASTER_KEY` também em um gerenciador de senhas.
- Se a imagem for privada, execute `docker login` na VM.

## 7. Preparar persistência

Execute uma vez na VM:

```bash
sudo bin/prepare-production-storage
```

Isso cria:

```text
/var/lib/quick_presence/storage
/var/lib/quick_presence/caddy/data
/var/lib/quick_presence/caddy/config
```

O primeiro diretório contém bancos SQLite e uploads. Os outros dois contêm
certificados e estado do Caddy. Trocar ou remover containers não remove esses
dados.

## 8. Primeira subida

Baixe as imagens e inicie os serviços:

```bash
docker compose -f compose.production.yml pull
docker compose -f compose.production.yml up -d
```

O entrypoint do Rails executa `db:prepare` automaticamente antes de iniciar o
servidor. Isso cria os bancos na primeira execução e aplica migrations nas
atualizações.

Verifique:

```bash
docker compose -f compose.production.yml ps
docker compose -f compose.production.yml logs --tail=200 web
docker compose -f compose.production.yml logs --tail=200 caddy
curl -I https://quickpresence.xyz/up
```

Depois acesse `https://quickpresence.xyz`. Links públicos e QR Codes usarão o
domínio e protocolo da requisição, gerando URLs HTTPS desse domínio.

## 9. Publicar uma nova versão

Crie e publique outra tag no computador local. Na VM, altere apenas
`APP_IMAGE` no `.env`:

```dotenv
APP_IMAGE=seu-usuario/quick_presence:2026-06-20-1
```

Atualize:

```bash
docker compose -f compose.production.yml pull web
docker compose -f compose.production.yml up -d
docker image prune
```

O container Rails será substituído, mas `/var/lib/quick_presence/storage`
continuará montado no novo container.

Não use:

```bash
docker compose down -v
```

Embora este setup use bind mounts em vez de volumes nomeados para os dados
principais, remover dados manualmente em `/var/lib/quick_presence` continua
sendo destrutivo.

## 10. Rollback

Altere `APP_IMAGE` para uma tag anterior:

```dotenv
APP_IMAGE=seu-usuario/quick_presence:2026-06-12-1
```

Depois:

```bash
docker compose -f compose.production.yml pull web
docker compose -f compose.production.yml up -d
```

Rollback de imagem não desfaz migrations. Antes de uma migration destrutiva,
faça backup e planeje compatibilidade entre a versão nova e a anterior.

## 11. Backup do SQLite e uploads

Não copie arquivos SQLite enquanto a aplicação está escrevendo neles. Para um
backup simples e consistente, aceite uma pequena indisponibilidade:

```bash
docker compose -f compose.production.yml stop web
sudo tar -C /var/lib/quick_presence \
  -czf "/var/backups/quick_presence-$(date +%F-%H%M).tar.gz" \
  storage
docker compose -f compose.production.yml start web
```

Copie os backups para outra máquina ou armazenamento. Um backup mantido apenas
na mesma VM não protege contra perda do servidor.

Para restaurar:

1. pare o serviço `web`;
2. preserve ou mova o diretório atual;
3. extraia o backup em `/var/lib/quick_presence`;
4. confirme proprietário e permissões do storage;
5. inicie o serviço `web`.

## 12. Diagnóstico

Estado dos containers:

```bash
docker compose -f compose.production.yml ps
```

Logs:

```bash
docker compose -f compose.production.yml logs -f web
docker compose -f compose.production.yml logs -f caddy
```

Conferir DNS:

```bash
getent hosts quickpresence.xyz
```

Conferir portas ocupadas:

```bash
sudo ss -lntup
```

Erros comuns:

- Caddy não emite certificado: DNS incorreto ou portas `80/443` bloqueadas.
- Imagem não inicia: arquitetura da imagem diferente da arquitetura da VM.
- Compose diz que `APP_IMAGE` não existe: variável ausente ou tag não publicada.
- Rails não lê credentials: `RAILS_MASTER_KEY` não corresponde ao arquivo
  criptografado da imagem.
- SQLite retorna `readonly database`: diretório do storage sem permissão para
  UID/GID `1000`.
- Links ou QR Codes usam host errado: acesso feito por IP ou proxy sem preservar
  `Host` e `X-Forwarded-Proto`.
- VM trava durante deploy: confirme que está usando `image:` e `pull`, sem
  executar `docker compose ... --build` na VM.

## 13. Checklist final

- A imagem foi criada para a arquitetura correta.
- A tag versionada está publicada no registry.
- `.env` existe apenas na VM e tem permissão `600`.
- `APP_DOMAIN=quickpresence.xyz`.
- DNS aponta para o IP público da VM.
- Oracle Cloud e firewall da VM liberam `80/443`.
- O diretório persistente foi preparado.
- Rails e Caddy estão `Up`.
- `https://quickpresence.xyz/up` responde.
- Um link público e seu QR Code abrem usando HTTPS.
- Existe backup fora da VM.
