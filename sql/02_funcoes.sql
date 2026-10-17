-- 02: funções e triggers
SET search_path TO chamados;

-- Calcula o prazo de SLA a partir da prioridade
CREATE OR REPLACE FUNCTION fn_calcula_prazo_sla(p_prioridade prioridade_chamado, p_inicio TIMESTAMP DEFAULT now())
RETURNS TIMESTAMP LANGUAGE sql STABLE AS $$
    SELECT p_inicio + make_interval(hours => horas_resolucao) FROM sla WHERE prioridade = p_prioridade;
$$;

-- Tempo (em horas) de resolução de um chamado; NULL se ainda não resolvido
CREATE OR REPLACE FUNCTION fn_horas_resolucao(p_id INT)
RETURNS NUMERIC LANGUAGE sql STABLE AS $$
    SELECT round(EXTRACT(EPOCH FROM (resolvido_em - aberto_em)) / 3600, 2) FROM chamado WHERE id_chamado = p_id;
$$;

-- Chamados em atendimento de um técnico (carga de trabalho)
CREATE OR REPLACE FUNCTION fn_carga_tecnico(p_id_tecnico INT)
RETURNS INT LANGUAGE sql STABLE AS $$
    SELECT count(*)::INT FROM chamado WHERE id_tecnico = p_id_tecnico AND status IN ('EM_ATENDIMENTO', 'AGUARDANDO_CLIENTE');
$$;

-- Define o prazo de SLA ao abrir o chamado
CREATE OR REPLACE FUNCTION trg_define_sla() RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    NEW.prazo_sla := fn_calcula_prazo_sla(NEW.prioridade, NEW.aberto_em);
    RETURN NEW;
END $$;

CREATE TRIGGER trg_chamado_sla BEFORE INSERT ON chamado
FOR EACH ROW EXECUTE FUNCTION trg_define_sla();

-- Registra histórico e valida transições de status
CREATE OR REPLACE FUNCTION trg_historico_status() RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO historico_status(id_chamado, status_anterior, status_novo) VALUES (NEW.id_chamado, NULL, NEW.status);
    ELSIF NEW.status IS DISTINCT FROM OLD.status THEN
        IF OLD.status IN ('FECHADO', 'CANCELADO') THEN
            RAISE EXCEPTION 'Chamado % está % e não pode mudar de status', OLD.id_chamado, OLD.status;
        END IF;
        IF NEW.status = 'RESOLVIDO' AND NEW.resolvido_em IS NULL THEN
            NEW.resolvido_em := now();
        END IF;
        INSERT INTO historico_status(id_chamado, status_anterior, status_novo) VALUES (NEW.id_chamado, OLD.status, NEW.status);
    END IF;
    RETURN NEW;
END $$;

CREATE TRIGGER trg_chamado_hist_ins AFTER INSERT ON chamado
FOR EACH ROW EXECUTE FUNCTION trg_historico_status();
CREATE TRIGGER trg_chamado_hist_upd BEFORE UPDATE OF status ON chamado
FOR EACH ROW EXECUTE FUNCTION trg_historico_status();

-- Abre um chamado e devolve o id
CREATE OR REPLACE FUNCTION fn_abrir_chamado(p_titulo TEXT, p_descricao TEXT, p_categoria INT, p_solicitante INT, p_prioridade prioridade_chamado DEFAULT 'MEDIA')
RETURNS INT LANGUAGE plpgsql AS $$
DECLARE v_id INT;
BEGIN
    INSERT INTO chamado(titulo, descricao, id_categoria, id_solicitante, prioridade)
    VALUES (p_titulo, p_descricao, p_categoria, p_solicitante, p_prioridade)
    RETURNING id_chamado INTO v_id;
    RETURN v_id;
END $$;

-- Atribui o chamado a um técnico e inicia o atendimento.
-- Bloqueia a linha para evitar dupla atribuição concorrente.
CREATE OR REPLACE FUNCTION fn_atribuir_chamado(p_chamado INT, p_tecnico INT)
RETURNS VOID LANGUAGE plpgsql AS $$
DECLARE v_status status_chamado;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM usuario WHERE id_usuario = p_tecnico AND perfil = 'TECNICO' AND ativo) THEN
        RAISE EXCEPTION 'Usuário % não é um técnico ativo', p_tecnico;
    END IF;
    SELECT status INTO v_status FROM chamado WHERE id_chamado = p_chamado FOR UPDATE;
    IF NOT FOUND THEN RAISE EXCEPTION 'Chamado % não existe', p_chamado; END IF;
    IF v_status <> 'ABERTO' THEN
        RAISE EXCEPTION 'Chamado % não está ABERTO (status atual: %)', p_chamado, v_status;
    END IF;
    UPDATE chamado SET id_tecnico = p_tecnico, status = 'EM_ATENDIMENTO' WHERE id_chamado = p_chamado;
END $$;
