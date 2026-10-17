-- 03: views
SET search_path TO chamados;

-- Visão dos chamados com solicitante, técnico, categoria e situação do SLA
CREATE OR REPLACE VIEW vw_chamados_detalhado AS
SELECT c.id_chamado, c.titulo, c.status, c.prioridade,
       cat.nome AS categoria,
       s.nome  AS solicitante,
       t.nome  AS tecnico,
       c.aberto_em, c.prazo_sla, c.resolvido_em,
       CASE
           WHEN c.status IN ('RESOLVIDO', 'FECHADO') THEN
               CASE WHEN c.resolvido_em <= c.prazo_sla THEN 'NO PRAZO' ELSE 'FORA DO PRAZO' END
           WHEN c.status = 'CANCELADO' THEN 'N/A'
           WHEN now() > c.prazo_sla THEN 'ATRASADO'
           ELSE 'NO PRAZO'
       END AS situacao_sla
FROM chamado c
JOIN categoria cat ON cat.id_categoria = c.id_categoria
JOIN usuario s ON s.id_usuario = c.id_solicitante
LEFT JOIN usuario t ON t.id_usuario = c.id_tecnico;

-- Chamados em aberto ainda sem solução, mais críticos primeiro
CREATE OR REPLACE VIEW vw_chamados_pendentes AS
SELECT * FROM vw_chamados_detalhado
WHERE status IN ('ABERTO', 'EM_ATENDIMENTO', 'AGUARDANDO_CLIENTE')
ORDER BY prioridade DESC, prazo_sla;

-- Produtividade por técnico
CREATE OR REPLACE VIEW vw_desempenho_tecnico AS
SELECT u.id_usuario, u.nome AS tecnico,
       count(c.id_chamado)                                         AS total_atribuidos,
       count(*) FILTER (WHERE c.status IN ('RESOLVIDO', 'FECHADO')) AS resolvidos,
       count(*) FILTER (WHERE c.status IN ('EM_ATENDIMENTO', 'AGUARDANDO_CLIENTE')) AS em_andamento,
       round(avg(EXTRACT(EPOCH FROM (c.resolvido_em - c.aberto_em)) / 3600)::numeric, 2) AS media_horas_resolucao
FROM usuario u
LEFT JOIN chamado c ON c.id_tecnico = u.id_usuario
WHERE u.perfil = 'TECNICO'
GROUP BY u.id_usuario, u.nome;

-- Resumo por categoria e status
CREATE OR REPLACE VIEW vw_resumo_categoria AS
SELECT cat.nome AS categoria, c.status, count(*) AS quantidade
FROM chamado c JOIN categoria cat ON cat.id_categoria = c.id_categoria
GROUP BY cat.nome, c.status;
