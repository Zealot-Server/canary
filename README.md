# Canary

Canary e o servidor principal do projeto OpenTibia. Ele executa o mundo do jogo, carrega os scripts Lua, usa o banco de dados MySQL/MariaDB e expõe as portas usadas pelo client e pelos servicos de login/status.

Este repositorio contem o core em C++20, datapack, scripts Lua, schema SQL, configuracoes CMake/vcpkg, Docker e ferramentas de desenvolvimento.

## Estrutura Importante

| Caminho | Descricao |
| --- | --- |
| `canary` | Binario local ja compilado, usado para iniciar o servidor com `./canary`. |
| `config.lua` | Configuracao principal do servidor: IP, portas, banco de dados, rates e recursos. |
| `config.lua.dist` | Modelo original de configuracao. |
| `schema.sql` | Estrutura inicial do banco de dados. |
| `data/` | Scripts, configuracoes e conteudo do jogo. |
| `src/` | Codigo-fonte C++ do servidor. |
| `docker/` | Stack Docker com banco, Canary, MyAAC e login-server. |
| `start.sh` | Script auxiliar que cria logs e reinicia o servidor em loop. |

## Requisitos

Para executar o binario ja existente:

- macOS ou Linux compativel com o binario presente no projeto.
- MySQL ou MariaDB.
- Banco importado com `schema.sql`.
- `config.lua` ajustado para o seu ambiente.

Para compilar:

- CMake 3.24 ou superior.
- Ninja.
- Compilador C++20.
- vcpkg, normalmente usando o `vcpkg/` incluido no repositorio.

## Configuracao

Edite `config.lua` antes de iniciar. Os campos mais importantes para ambiente local sao:

```lua
ip = "127.0.0.1"
loginProtocolPort = 7171
gameProtocolPort = 7172
statusProtocolPort = 7171

mysqlHost = "127.0.0.1"
mysqlUser = "canary"
mysqlPass = "canary123"
mysqlDatabase = "canary_db"
mysqlPort = 3306
```

Crie o banco e importe o schema:

```bash
mysql -u root -p -e "CREATE DATABASE canary_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql -u root -p canary_db < schema.sql
```

Depois, garanta que o usuario definido em `mysqlUser` tenha acesso ao banco.

## Como Iniciar

Na raiz deste diretorio:

```bash
chmod +x ./canary
./canary
```

Ou usando o script auxiliar com logs:

```bash
chmod +x ./start.sh
./start.sh
```

O `start.sh` executa `./canary`, cria a pasta `logs/` quando necessario e registra a saida do servidor em arquivos de log.

Portas padrao:

| Porta | Uso |
| --- | --- |
| `7171` | Login protocol e status no `config.lua` local. |
| `7172` | Game server. |
| `7173` | Status quando usado pela stack Docker, conforme variaveis `CANARY_STATUS_PORT`/`OT_SERVER_STATUS_PORT`. |

## Docker

O diretorio `docker/` possui uma stack pronta com:

- MariaDB.
- Canary.
- MyAAC.
- Login Server.

Para subir tudo:

```bash
cd docker
cp .env.dist .env
docker compose up -d --build
```

Endpoints padrao da stack:

| Servico | URL/porta |
| --- | --- |
| MyAAC | `http://localhost:8080` |
| Login Server HTTP | `http://localhost:8088/login` |
| Game Server | `127.0.0.1:7172` |

Para acompanhar logs:

```bash
docker compose logs -f
```

Para parar:

```bash
docker compose down
```

## Compilacao Local

Exemplo no macOS:

```bash
export VCPKG_ROOT="$PWD/vcpkg"
./vcpkg/bootstrap-vcpkg.sh
cmake --preset macos-release
cmake --build --preset macos-release
```

Exemplo no Linux:

```bash
export VCPKG_ROOT="$PWD/vcpkg"
./vcpkg/bootstrap-vcpkg.sh
cmake --preset linux-release
cmake --build --preset linux-release
```

O binario compilado sera gerado dentro de `build/<preset>/`.

## Testes

Para compilar e executar testes no Linux:

```bash
export VCPKG_ROOT="$PWD/vcpkg"
cmake --preset linux-debug
cmake --build --preset linux-debug
ctest --preset linux-debug
```

No macOS:

```bash
export VCPKG_ROOT="$PWD/vcpkg"
cmake --preset macos-debug
cmake --build --preset macos-debug
ctest --preset macos-debug
```

## Integracao com os Outros Projetos

- `login-server` deve apontar para o mesmo banco do Canary e publicar o endpoint HTTP usado pelo OTClient.
- `myaac-main` deve usar o mesmo banco para criar contas, personagens e painel web.
- `otclient` deve apontar para o IP/porta do login server ou para a porta de login configurada no servidor.

### Desconexao por inatividade

`kickIdlePlayerAfterMinutes` em `config.lua.dist` define o limite de inatividade. No Zealot, `0` desativa a desconexao por inatividade para permitir treino AFK. Com um valor positivo, o Canary avisa um minuto antes e envia o motivo de fim de sessao `SESSION_END_IDLE = 4` ao OTClient ao desconectar. Perda de ping e timeout de rede seguem caminhos separados; nao devem ser apresentados como inatividade.

## Solucao de Problemas

| Problema | Verificacao |
| --- | --- |
| Servidor fecha ao iniciar | Confira `logs/`, credenciais do MySQL e se o schema foi importado. |
| Client nao conecta | Confira `ip`, portas `7171/7172`, firewall e configuracao do `login-server`. |
| Erro de banco | Verifique `mysqlHost`, `mysqlUser`, `mysqlPass`, `mysqlDatabase` e permissoes do usuario. |
| Mapa/scripts nao carregam | Confira se a execucao esta ocorrendo na raiz do diretorio `canary`. |

## Licenca

Distribuido sob a licenca GPL-2.0. Consulte `LICENSE` para detalhes.
