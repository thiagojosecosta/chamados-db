-- 05: demonstração de VIEWS, FUNÇÕES, TRIGGERS e TRANSAÇÕES
SET search_path TO chamados;

-- ============================================================
-- 1) VIEWS
-- ============================================================
SELECT id_chamado, titulo, status, prioridade, tecnico, situacao_sla FROM vw_chamados_detalhado ORDER BY id_chamado;
SELECT id_chamado, titulo, prioridade, tecnico FROM vw_chamados_pendentes;
SELECT * FROM vw_desempenho_tecnico;
SELECT * FROM vw_resumo_categoria ORDER BY categoria, status;

-- ============================================================
-- 2) FUNÇÕES
-- ============================================================
SELECT fn_horas_resolucao(4)               AS horas_do_chamado_4;
SELECT nome, fn_carga_tecnico(id_usuario)  AS chamados_em_andamento FROM usuario WHERE perfil = 'TECNICO';
SELECT fn_calcula_prazo_sla('ALTA')        AS prazo_se_abrir_agora;

-- ============================================================
-- 3) TRANSAÇÕES
-- ============================================================

-- 3.1) Abrir chamado + comentário inicial.
BEGIN;
    SELECT fn_abrir_chamado('Monitor piscando', 'Tela oscila', 1, 2, 'BAIXA') AS novo_id;
    INSERT INTO comentario(id_chamado, id_usuario, texto)
    VALUES (currval(pg_get_serial_sequence('chamados.chamado', 'id_chamado')), 2, 'Acontece desde ontem.');
COMMIT;
SELECT id_chamado, titulo, status FROM chamado ORDER BY id_chamado DESC LIMIT 1;

-- 3.2) Desfaz o que foi feito dentro da transação.
BEGIN;
    UPDATE chamado SET prioridade = 'CRITICA' WHERE id_chamado = 3;
    SELECT id_chamado, prioridade FROM chamado WHERE id_chamado = 3;
ROLLBACK;
SELECT id_chamado, prioridade FROM chamado WHERE id_chamado = 3;

-- 3.3) Desfaz só uma parte da transação.
BEGIN;
    SELECT fn_atribuir_chamado(3, 5);
    SAVEPOINT antes_comentario;
    INSERT INTO comentario(id_chamado, id_usuario, texto) VALUES (3, 5, 'Comentário errado');
    ROLLBACK TO SAVEPOINT antes_comentario;
    INSERT INTO comentario(id_chamado, id_usuario, texto) VALUES (3, 5, 'Iniciando instalação do Office.');
COMMIT;
SELECT id_chamado, status, tecnico FROM vw_chamados_detalhado WHERE id_chamado = 3;
SELECT texto FROM comentario WHERE id_chamado = 3;

-- 3.4) Reatribuição transfere o chamado de um tecnico para outro.
BEGIN;
    UPDATE chamado SET id_tecnico = 5 WHERE id_tecnico = 4 AND status = 'EM_ATENDIMENTO';
    SELECT nome, fn_carga_tecnico(id_usuario) AS carga FROM usuario WHERE perfil = 'TECNICO';
COMMIT;

-- 3.5) ROLLBACK por ERRO: atribuir a quem não é técnico.
-- (a) Execute este bloco: o erro é ESPERADO e interrompe a execução.
BEGIN;
    UPDATE chamado SET prioridade = 'ALTA' WHERE id_chamado = 1;
    SELECT fn_atribuir_chamado(1, 1);      -- ERRO: usuário 1 é CLIENTE
-- (b) Em seguida execute SOMENTE esta linha para encerrar a transação com falha:
ROLLBACK;

-- ============================================================
-- 4) TRIGGERS
-- ============================================================
UPDATE chamado SET status = 'FECHADO' WHERE id_chamado = 4;
-- O próximo comando deve FALHAR
UPDATE chamado SET status = 'ABERTO'  WHERE id_chamado = 4;
-- Histórico gravado automaticamente pelo trigger:
SELECT id_historico, status_anterior, status_novo, alterado_em FROM historico_status WHERE id_chamado = 4 ORDER BY id_historico;
