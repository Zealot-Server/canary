# Daily Boosts

O Canary mantém a criatura e o boss do dia nas tabelas `boosted_creature` e
`boosted_boss`. O MyAAC lê essas tabelas diretamente para montar o card da
página inicial.

Na inicialização e a cada minuto, o servidor compara a data persistida com a
data local completa (`AAAAMMDD`). Ao mudar o dia, sorteia uma nova criatura
entre os monstros válidos do bestiário e um novo boss entre os Archfoes. O
sorteio é uniforme e exclui a escolha anterior quando há mais de uma opção.
Se o banco ainda guarda apenas o número do dia do mês, o primeiro carregamento
após esta mudança faz a rotação automaticamente.

A rotação usa o fuso horário do processo do Canary. Na stack de produção atual,
o container usa UTC. O site mostra os valores persistidos pelo servidor; não
faz sorteio próprio. O sorteio também roda sem reiniciar o servidor.
