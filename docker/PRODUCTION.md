# Operação em produção

O arquivo `docker-compose.yml` é o quickstart para desenvolvimento local. Para
o VPS, sempre combine-o com `docker-compose.production.yml`:

```sh
docker compose -f docker-compose.yml -f docker-compose.production.yml up -d --build
```

O override expõe a porta de jogo (`7172`) e a porta de status (`7173`) em todas
as interfaces. A porta de status é necessária para listagens públicas, como o
OTServList, consultarem nome, jogadores e estado do Canary. Banco, login
protocol, MyAAC, login HTTP e gRPC ficam acessíveis somente por `127.0.0.1`.
Não abra essas portas no firewall.

Ao usar uma listagem de servidores, cadastre o host público com a porta de
status `7173` (não a porta de jogo `7172`) e libere apenas `7173/tcp` no
firewall do VPS. A porta de status não fornece acesso administrativo.

Antes da primeira inicialização, crie `docker/.env` a partir de `.env.dist` e
substitua todas as senhas padrão. Para produção, também defina:

```env
CANARY_SERVER_NAME=Zealot
CANARY_SERVER_IP=<IP-ou-host-publico>
CANARY_TEST_ACCOUNTS=false
CANARY_IMAGE=ghcr.io/zealot-server/canary:latest
MYAAC_SITE_URL=https://<dominio>
```

Use uma tag ou digest do Canary quando houver uma release validada. A imagem
`ghcr.io/zealot-server/canary` é publicada pela CI do repositório e incorpora
as alterações do projeto; a imagem pública de terceiros não substitui essa
build.

O override já inclui Caddy como gateway HTTPS. Antes de iniciá-lo, aponte os
registros `A` de `@` e `api` para o VPS e o `CNAME` de `www` para `@`. O
`Caddyfile` encaminha o site a MyAAC e `api.zealot.website` ao login-server,
mantendo ambos fora da Internet direta. Só então o cliente deve usar
`https://api.zealot.website/login`.

Os volumes Docker preservam banco e dados de runtime no mesmo VPS, mas não são
backup externo. Antes de abrir o servidor, automatize uma cópia externa do dump
gerado em `server-data`.
