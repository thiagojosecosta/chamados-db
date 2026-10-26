# Sistema de Gerenciamento de Chamados — Banco de Dados PostgreSQL

<p align="center">
  <img src="https://img.shields.io/badge/PostgreSQL-18-4169E1?logo=postgresql&logoColor=white" alt="PostgreSQL 18">
  <img src="https://img.shields.io/badge/pgAdmin-4-336791?logo=postgresql&logoColor=white" alt="pgAdmin 4">
  <img src="https://img.shields.io/badge/Docker-cont%C3%AAiner-2496ED?logo=docker&logoColor=white" alt="Docker">
  <img src="https://img.shields.io/badge/draw.io-diagrama-F08705?logo=diagramsdotnet&logoColor=white" alt="draw.io">
</p>

**Instituto Federal do Paraná (IFPR) — Campus Palmas/PR**
Disciplina: **Banco de Dados 2** · Professora: **Bruna Francieli Kwiatkovski**
Aluno: **Thiago J. Costa**

---

## Sobre o trabalho

Banco de dados de um sistema de **chamados de suporte (help desk)**, como o que uma empresa usa para o setor de TI atender pedidos dos funcionários: alguém abre um chamado (impressora parada, VPN fora do ar, senha esquecida), um técnico assume, acompanha e resolve, e tudo fica registrado.

O trabalho exige três recursos do PostgreSQL, implementados e demonstrados:

| Requisito | Arquivo | Aplicação no tema |
|---|---|---|
| **Views** | `sql/03_views.sql` | Consultas prontas para o dia a dia da equipe de suporte |
| **Funções** | `sql/02_funcoes.sql` | Regras de negócio no banco: abrir e atribuir chamados, calcular SLA |
| **Transações** | `sql/05_demonstracao.sql` | Operações "tudo ou nada", com `COMMIT`, `ROLLBACK` e `SAVEPOINT` |

## Ferramentas utilizadas

- **[PostgreSQL 18](https://hub.docker.com/_/postgres)**, em contêiner Docker (`docker_Db`);
- **[pgAdmin 4](https://hub.docker.com/r/dpage/pgadmin4)**, também em contêiner, para criar o banco e executar os scripts;
- **[draw.io](https://www.drawio.com)**, para o diagrama do modelo de dados (`docs/modelo_chamados.drawio`);
- **Git / GitHub**, para versionamento e entrega.

## Como executar

1. Suba o PostgreSQL e o pgAdmin e crie o banco `chamados_db`.
2. Abra o **Query Tool** do pgAdmin no banco `chamados_db` e execute os scripts de `sql/`, **na ordem numérica** (`01` a `04`). O `01` recria o schema `chamados` do zero, então pode ser reexecutado quando quiser.
3. Execute o `05_demonstracao.sql` **por blocos** (selecione o trecho e rode com F5), pois ele mostra transações e erros propositais.

| Ordem | Arquivo | Conteúdo |
|---|---|---|
| 1 | `sql/01_schema.sql` | Tabelas, tipos, restrições e índices (schema `chamados`) |
| 2 | `sql/02_funcoes.sql` | Funções e triggers |
| 3 | `sql/03_views.sql` | Views |
| 4 | `sql/04_dados.sql` | Dados de exemplo |
| 5 | `sql/05_demonstracao.sql` | Demonstração de views, funções, triggers e transações |

## Modelo de dados

![Modelo de dados do sistema de chamados](docs/modelo_chamados.png)

*PK = chave primária · FK = chave estrangeira · UK = valor único. O arquivo editável está em [`docs/modelo_chamados.drawio`](docs/modelo_chamados.drawio).*

- Cada chamado tem categoria (Hardware, Software, Rede, Acesso), prioridade (`BAIXA`, `MEDIA`, `ALTA`, `CRITICA`) e status (`ABERTO`, `EM_ATENDIMENTO`, `AGUARDANDO_CLIENTE`, `RESOLVIDO`, `FECHADO`, `CANCELADO`).
- Usuários têm perfil `CLIENTE`, `TECNICO` ou `ADMIN`.
- `CHAMADO` se liga duas vezes a `USUARIO`: o **solicitante** (quem abriu) e o **técnico** (quem atende, opcional até ser atribuído).
- A tabela `SLA` define o prazo de resolução, em horas, de cada prioridade.

## Funcionalidades

### Views — o painel da equipe de suporte
| View | Para que serviria no dia a dia |
|---|---|
| `vw_chamados_detalhado` | Tela principal do help desk: chamado, solicitante, técnico e se o prazo (SLA) está em dia ou atrasado |
| `vw_chamados_pendentes` | Fila de trabalho do técnico, dos mais críticos para os menos |
| `vw_desempenho_tecnico` | Relatório do gestor: quanto cada técnico resolveu e em quanto tempo |
| `vw_resumo_categoria` | Onde estão os problemas: quantos chamados por categoria e status |

### Funções e triggers — regras que o banco aplica sozinho
| Objeto | O que faz |
|---|---|
| `fn_abrir_chamado` | Registra um novo chamado e devolve o número |
| `fn_atribuir_chamado` | Passa o chamado a um técnico, recusando quem não é técnico ativo ou chamado que já foi assumido |
| `fn_calcula_prazo_sla` | Calcula o prazo de resolução pela prioridade (ex.: crítico = 4 h, baixo = 72 h) |
| `fn_carga_tecnico` | Quantos chamados o técnico tem em andamento, útil para distribuir o trabalho |
| `fn_horas_resolucao` | Tempo gasto para resolver um chamado |
| Triggers | Definem o prazo ao abrir o chamado, gravam o histórico de cada mudança de status e impedem alterar o status de um chamado já fechado ou cancelado |

### Transações — nada fica pela metade
| Caso | Exemplo prático |
|---|---|
| `COMMIT` | Abrir o chamado e o comentário inicial juntos |
| `ROLLBACK` | Desfazer uma alteração de prioridade feita por engano |
| `SAVEPOINT` | Descartar só um comentário errado sem perder a atribuição do chamado |
| Reatribuição | Passar todos os chamados de um técnico para outro de uma vez |
| `ROLLBACK` por erro | Tentar atribuir um chamado a um cliente: a função recusa e a alteração anterior é desfeita |
