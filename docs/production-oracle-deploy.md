# Deploy do QuickPresence na Oracle Cloud

Este documento registra o processo validado para executar o QuickPresence em
uma VM gratuita e pequena da Oracle Cloud.

Ambiente utilizado:

- Oracle Cloud Compute;
- shape `VM.Standard.E2.1.Micro`, arquitetura `x86_64`;
- Ubuntu Minimal;
- imagem Rails criada localmente para `linux/amd64`;
- Docker Hub como registry;
- Docker Compose na VM;
- Caddy para HTTPS automático;
- domínio administrado na Hostinger;
- SQLite e uploads persistidos fora dos containers.

O objetivo é permitir que containers e imagens sejam substituídos sem perder
bancos, uploads ou certificados.

## 1. Visão geral

O deploy possui três ambientes distintos:

| Local | Responsabilidade |
| --- | --- |
| Computador de desenvolvimento | Testar, criar e publicar a imagem Rails |
| Docker Hub | Armazenar imagens versionadas |
| VM Oracle | Baixar a imagem e executar Rails e Caddy |

A VM não deve executar o build da imagem. Com apenas 1 GB de memória, etapas
como `bundle install`, Bootsnap e precompilação de assets podem travá-la.

O QuickPresence usa quatro arquivos SQLite em produção:

- `production.sqlite3`;
- `production_cache.sqlite3`;
- `production_queue.sqlite3`;
- `production_cable.sqlite3`.

Dentro do container eles ficam em `/rails/storage`. No host, ficam em
`/var/lib/quick_presence/storage`.

## 2. Arquivos do deploy

Na VM, a pasta `~/quick_presence` contém apenas configuração:

```text
~/quick_presence/
├── .env
├── Caddyfile
└── compose.production.yml
```

Os dados persistentes ficam separados:

```text
/var/lib/quick_presence/
├── storage/
└── caddy/
    ├── config/
    └── data/
```

Arquivos do repositório envolvidos:

- `Dockerfile`: cria a imagem Rails;
- `compose.production.yml`: executa Rails e Caddy;
- `Caddyfile`: encaminha o domínio para o Rails;
- `.env_model`: documenta variáveis necessárias;
- `.env`: contém valores reais e nunca vai para o Git;
- `bin/prepare-production-storage`: prepara os diretórios persistentes.

Este fluxo usa Docker Compose diretamente. Não use Kamal e Compose ao mesmo
tempo na mesma VM.

## 3. Criar a VM

Configuração validada:

- shape `VM.Standard.E2.1.Micro`;
- Ubuntu Minimal;
- IP público IPv4;
- arquitetura `x86_64`;
- chave SSH Ed25519;
- boot volume padrão.

Antes de apontar o domínio, reserve o endereço IPv4 público na Oracle. Um IP
efêmero pode mudar quando a instância for interrompida ou recriada. Se o IP
mudar, o registro `A` e qualquer configuração externa também precisarão ser
atualizados.

Depois da criação, confirme:

```bash
uname -m
cat /etc/os-release
free -h
df -h
```

O resultado de `uname -m` deve ser `x86_64`. Para esse servidor, a plataforma
da imagem Docker é `linux/amd64`.

VMs Oracle Ampere A1 usam ARM e exigem `linux/arm64`. Sempre verifique a
arquitetura em vez de inferi-la pelo nome do provedor.

## 4. Acessar por SSH

Para uma imagem Ubuntu, o usuário padrão é `ubuntu`:

```bash
ssh -i ~/.ssh/id_ed25519 ubuntu@IP_PUBLICO_DA_VM
```

O arquivo informado em `-i` é a chave privada, não o arquivo `.pub`.

Se o SSH responder, a VM está ativa mesmo que não responda a `ping`. ICMP pode
estar bloqueado.

## 5. Atualizar o Ubuntu

Na VM:

```bash
sudo apt update
sudo apt upgrade -y
sudo apt install -y ca-certificates curl git gnupg ufw
```

Ubuntu usa `apt`. Imagens Oracle Linux usam `dnf`, mas não fazem parte do
ambiente validado por este runbook.

## 6. Criar swap

A `VM.Standard.E2.1.Micro` possui aproximadamente 1 GB de RAM. Crie 2 GB de
swap:

```bash
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
echo 'vm.swappiness=10' | sudo tee /etc/sysctl.d/99-swappiness.conf
sudo sysctl --system
```

Confirme:

```bash
free -h
swapon --show
```

Swap reduz o risco de encerramento por falta de memória, mas não torna a VM
adequada para buildar a imagem Rails.

## 7. Instalar Docker

Na VM, adicione o repositório oficial:

```bash
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL \
  https://download.docker.com/linux/ubuntu/gpg \
  -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
```

```bash
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" |
  sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
```

```bash
sudo apt update
sudo apt install -y \
  docker-ce \
  docker-ce-cli \
  containerd.io \
  docker-buildx-plugin \
  docker-compose-plugin
```

Permita que o usuário atual use Docker:

```bash
sudo usermod -aG docker "$USER"
```

Saia do SSH e entre novamente. Depois confirme:

```bash
docker version
docker compose version
docker run --rm hello-world
```

Usuários do grupo `docker` possuem privilégios equivalentes a root.

### Limitar logs do Docker

Evite que logs ocupem todo o disco:

```bash
sudo mkdir -p /etc/docker
sudo nano /etc/docker/daemon.json
```

Conteúdo:

```json
{
  "log-driver": "local",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
```

```bash
sudo systemctl restart docker
sudo systemctl enable docker
```

## 8. Liberar portas

Na Oracle Cloud, configure ingress na Security List ou no Network Security Group:

| Protocolo | Porta | Origem |
| --- | ---: | --- |
| TCP | 22 | Seu IP, quando possível |
| TCP | 80 | `0.0.0.0/0` |
| TCP | 443 | `0.0.0.0/0` |
| UDP | 443 | `0.0.0.0/0`, opcional para HTTP/3 |

Na VM, libere as mesmas portas:

```bash
sudo ufw allow OpenSSH
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 443/udp
sudo ufw enable
sudo ufw status verbose
```

Não exponha a porta interna do Rails ou qualquer porta para SQLite.

## 9. Preparar o Docker Desktop local

No Windows com WSL:

1. abra Docker Desktop;
2. entre em `Settings`;
3. abra `Resources > WSL Integration`;
4. habilite a distribuição usada pelo projeto;
5. aplique e reinicie.

Se o WSL ainda não acessar `/var/run/docker.sock`, feche os terminais e execute
no PowerShell:

```powershell
wsl --shutdown
```

Abra novamente o WSL e confirme:

```bash
docker version
docker buildx version
docker run --rm hello-world
```

## 10. Criar e publicar a imagem

Crie no Docker Hub um repositório como:

```text
seu-usuario/quick_presence
```

Use tags versionadas. No computador local, dentro do projeto:

```bash
docker login
```

```bash
docker buildx build \
  --platform linux/amd64 \
  --tag seu-usuario/quick_presence:2026-06-12-1 \
  --push .
```

Confirme a imagem publicada:

```bash
docker buildx imagetools inspect \
  seu-usuario/quick_presence:2026-06-12-1
```

Se `buildx` não estiver disponível e a máquina local também for `amd64`:

```bash
docker build \
  --tag seu-usuario/quick_presence:2026-06-12-1 .
docker push seu-usuario/quick_presence:2026-06-12-1
```

Nunca coloque `.env` ou `config/master.key` na imagem. O `.dockerignore` do
projeto já os exclui.

## 11. Configurar o ambiente

No computador local, o `.env` real deve conter:

```dotenv
APP_IMAGE=seu-usuario/quick_presence:2026-06-12-1
APP_DOMAIN=quickpresence.xyz
APP_STORAGE_PATH=/var/lib/quick_presence/storage
CADDY_DATA_PATH=/var/lib/quick_presence/caddy/data
CADDY_CONFIG_PATH=/var/lib/quick_presence/caddy/config
RAILS_MASTER_KEY=valor-real-da-chave
```

Regras:

- `APP_DOMAIN` não inclui `https://` nem barra final;
- `RAILS_MASTER_KEY` deve abrir o `config/credentials.yml.enc` da imagem;
- `.env` deve ter permissão `600`;
- `.env` nunca entra no Git;
- a chave deve ter uma cópia em gerenciador de senhas.

## 12. Criar a pasta de deploy

Na VM:

```bash
mkdir -p ~/quick_presence
```

No computador local, dentro do projeto:

```bash
scp -i ~/.ssh/id_ed25519 \
  .env Caddyfile compose.production.yml \
  ubuntu@IP_PUBLICO_DA_VM:~/quick_presence/
```

Na VM:

```bash
cd ~/quick_presence
chmod 600 .env
ls -la
```

Devem existir:

```text
.env
Caddyfile
compose.production.yml
```

## 13. Preparar persistência

Na VM:

```bash
sudo mkdir -p \
  /var/lib/quick_presence/storage \
  /var/lib/quick_presence/caddy/data \
  /var/lib/quick_presence/caddy/config

sudo chown -R 1000:1000 /var/lib/quick_presence/storage
sudo chmod 750 /var/lib/quick_presence/storage
```

O usuário do container Rails usa UID/GID `1000`. Os diretórios do Caddy são
gerenciados pelo próprio container.

Como alternativa, envie também `bin/prepare-production-storage` e execute:

```bash
sudo bin/prepare-production-storage
```

## 14. Apontar o domínio na Hostinger

No hPanel:

1. abra `Domínios`;
2. selecione `quickpresence.xyz`;
3. abra `DNS / Nameservers`;
4. entre em `Gerenciar registros DNS`;
5. localize o registro `A` do domínio raiz;
6. substitua o IP antigo pelo IP público da VM.

Configuração:

```text
Tipo: A
Nome: @
Destino: IP_PUBLICO_DA_VM
TTL: padrão ou 300
```

Não mantenha dois registros `A` para `@` apontando para servidores diferentes.
Não altere registros `NS`, `MX` ou `TXT` relacionados a e-mail e validações.

O `Caddyfile` atual atende `quickpresence.xyz`. O host `www` exige configuração
adicional antes de ser usado.

Confirme a propagação:

```bash
dig A +short quickpresence.xyz
```

No PowerShell:

```powershell
nslookup quickpresence.xyz
```

O resultado deve ser o IP público da VM. A propagação pode demorar.

## 15. Baixar e executar

Na VM:

```bash
cd ~/quick_presence
docker compose -f compose.production.yml config
```

Baixe as imagens:

```bash
docker compose -f compose.production.yml pull
```

O `docker pull` pode ser executado em qualquer pasta, porque imagens são
armazenadas pelo Docker. Usar `~/quick_presence` é conveniente para os comandos
do Compose.

Suba os containers:

```bash
docker compose -f compose.production.yml up -d
```

O entrypoint executa `db:prepare`, criando bancos e aplicando migrations antes
de iniciar o Rails.

Verifique:

```bash
docker compose -f compose.production.yml ps
docker compose -f compose.production.yml logs --tail=200 web
docker compose -f compose.production.yml logs --tail=200 caddy
```

Teste:

```bash
curl -I https://quickpresence.xyz/up
```

O resultado esperado é uma resposta HTTP de sucesso.

## 16. HTTPS e acesso pelo IP

O Caddy solicita e renova gratuitamente o certificado quando:

1. DNS aponta para a VM;
2. portas `80` e `443` estão acessíveis;
3. nenhum outro processo ocupa essas portas;
4. o container Caddy está em execução.

Não teste o certificado acessando `https://IP_PUBLICO_DA_VM`. O certificado é
emitido para `quickpresence.xyz`, não para o endereço IP. O navegador pode
mostrar falha de conexão segura ao usar o IP.

Para testar conectividade no PowerShell:

```powershell
ping IP_PUBLICO_DA_VM
Test-NetConnection IP_PUBLICO_DA_VM -Port 22
Test-NetConnection IP_PUBLICO_DA_VM -Port 80
Test-NetConnection IP_PUBLICO_DA_VM -Port 443
```

O comando `ping` recebe apenas o IP, sem `http://`. Ele pode falhar por bloqueio
de ICMP mesmo com a VM funcionando. Os testes TCP são mais úteis.

## 17. Publicar uma nova versão

No computador local, gere uma nova tag:

```bash
docker buildx build \
  --platform linux/amd64 \
  --tag seu-usuario/quick_presence:2026-06-20-1 \
  --push .
```

Na VM, altere somente `APP_IMAGE` em `.env`:

```dotenv
APP_IMAGE=seu-usuario/quick_presence:2026-06-20-1
```

Atualize:

```bash
cd ~/quick_presence
docker compose -f compose.production.yml pull web
docker compose -f compose.production.yml up -d
docker compose -f compose.production.yml ps
```

O container Rails será substituído, mas o diretório
`/var/lib/quick_presence/storage` continuará montado.

Remova imagens antigas somente depois de confirmar a nova versão:

```bash
docker image prune
```

## 18. Rollback

Altere `APP_IMAGE` para uma tag anterior:

```dotenv
APP_IMAGE=seu-usuario/quick_presence:2026-06-12-1
```

```bash
docker compose -f compose.production.yml pull web
docker compose -f compose.production.yml up -d
```

Rollback de imagem não desfaz migrations. Antes de migration destrutiva, faça
backup e mantenha compatibilidade com a versão anterior quando possível.

## 19. Backup

Para backup simples e consistente, pare temporariamente o Rails:

```bash
sudo mkdir -p /var/backups
docker compose -f compose.production.yml stop web
sudo tar -C /var/lib/quick_presence \
  -czf "/var/backups/quick_presence-$(date +%F-%H%M).tar.gz" \
  storage
docker compose -f compose.production.yml start web
```

Copie o backup para fora da VM. Um backup armazenado apenas no mesmo servidor
não protege contra perda da instância.

Para restaurar:

1. pare `web`;
2. preserve o diretório atual;
3. extraia o backup em `/var/lib/quick_presence`;
4. aplique proprietário `1000:1000` e permissão `750`;
5. inicie `web`.

## 20. Diagnóstico

Estado e logs:

```bash
cd ~/quick_presence
docker compose -f compose.production.yml ps
docker compose -f compose.production.yml logs -f web
docker compose -f compose.production.yml logs -f caddy
```

DNS e portas:

```bash
getent hosts quickpresence.xyz
sudo ss -lntup
```

Recursos:

```bash
free -h
df -h
docker system df
```

Erros comuns:

- Caddy não emite certificado: DNS incorreto ou portas bloqueadas;
- imagem não inicia: plataforma diferente da arquitetura da VM;
- `APP_IMAGE` ausente: `.env` incompleto ou tag não publicada;
- credentials não abrem: `RAILS_MASTER_KEY` incorreta;
- `readonly database`: storage sem permissão para UID/GID `1000`;
- QR Code usa host errado: acesso por IP ou proxy sem preservar host/protocolo;
- Docker não funciona no WSL: integração desabilitada ou sessão não reiniciada;
- VM fica sem memória: swap ausente, build feito na VM ou serviços extras;
- acesso HTTPS pelo IP falha: comportamento esperado para certificado de domínio.

Não execute sem compreender o impacto:

```bash
docker compose down -v
docker volume prune
docker system prune --volumes
```

Não remova manualmente `/var/lib/quick_presence`.

## 21. Checklist final

- VM `x86_64` usando imagem `linux/amd64`;
- swap de 2 GB ativo;
- Docker e Compose instalados;
- portas liberadas na Oracle e no `ufw`;
- imagem versionada publicada no Docker Hub;
- `.env` apenas no computador seguro e na VM, com permissão `600`;
- pasta `~/quick_presence` contém os três arquivos de deploy;
- storage persistente preparado;
- registro `A` aponta para o IP público da VM;
- containers `web` e `caddy` estão ativos;
- `https://quickpresence.xyz/up` responde;
- link público e QR Code usam HTTPS;
- backup externo planejado.
