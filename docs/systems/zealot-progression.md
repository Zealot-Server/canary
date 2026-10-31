# Progressão do Zealot

O Zealot usa estágios de experiência progressivos. Eles são habilitados por
`rateUseStages = true` em `config.lua.dist` e definidos em
`data/stages.lua`.

| Nível | Rate de experiência |
| --- | ---: |
| 1–8 | 50x |
| 9–50 | 80x |
| 51–100 | 60x |
| 101–150 | 40x |
| 151–200 | 30x |
| 201–300 | 15x |
| 301–400 | 12x |
| 401–500 | 10x |
| 501–600 | 7x |
| 601–700 | 6x |
| 701–800 | 5x |
| 801–900 | 4x |
| 901–1000 | 3x |
| 1001–1200 | 2x |
| 1201–1400 | 1,5x |
| 1401+ | 1,2x |

O bônus legado de baixo nível está desativado
(`lowLevelBonusExp = 0`), pois ele não faz parte da tabela acima.

## Stamina e Premium

O multiplicador da stamina é aplicado à experiência recebida de monstros:

| Stamina | Efeito |
| --- | --- |
| 42h até 39h | +50% de XP (1,5x) |
| 38h59 até 14h | XP normal (1x) |
| abaixo de 14h | -50% de XP (0,5x) |
| abaixo de 8h | monstros não concedem loot |

Contas Premium recebem mais 10% de experiência de monstros. Esse bônus é
aplicado separadamente da tabela e da stamina. Por exemplo, no nível 300 a
rate base é 15x; com stamina verde fica 22,5x e a conta Premium acrescenta
10% à experiência base do monstro.

O código de cálculo fica em `data/events/scripts/player.lua`. O bloqueio de
loot abaixo de 8 horas é aplicado pelo servidor ao gerar o cadáver do monstro.
