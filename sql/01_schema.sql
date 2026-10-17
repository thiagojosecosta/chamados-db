
DROP SCHEMA IF EXISTS chamados CASCADE;
CREATE SCHEMA chamados;
SET search_path TO chamados;

CREATE TYPE status_chamado AS ENUM ('ABERTO', 'EM_ATENDIMENTO', 'AGUARDANDO_CLIENTE', 'RESOLVIDO', 'FECHADO', 'CANCELADO');
CREATE TYPE prioridade_chamado AS ENUM ('BAIXA', 'MEDIA', 'ALTA', 'CRITICA');
CREATE TYPE perfil_usuario AS ENUM ('CLIENTE', 'TECNICO', 'ADMIN');

CREATE TABLE departamento (
    id_departamento SERIAL PRIMARY KEY,
    nome            VARCHAR(80) NOT NULL UNIQUE
);

CREATE TABLE usuario (
    id_usuario      SERIAL PRIMARY KEY,
    nome            VARCHAR(120) NOT NULL,
    email           VARCHAR(160) NOT NULL UNIQUE CHECK (email ~* '^[^@\s]+@[^@\s]+\.[^@\s]+$'),
    perfil          perfil_usuario NOT NULL,
    id_departamento INT REFERENCES departamento(id_departamento),
    ativo           BOOLEAN NOT NULL DEFAULT TRUE,
    criado_em       TIMESTAMP NOT NULL DEFAULT now()
);

CREATE TABLE categoria (
    id_categoria SERIAL PRIMARY KEY,
    nome         VARCHAR(80) NOT NULL UNIQUE,
    descricao    TEXT
);

-- SLA: prazo (horas) de resolução por prioridade
CREATE TABLE sla (
    prioridade     prioridade_chamado PRIMARY KEY,
    horas_resolucao INT NOT NULL CHECK (horas_resolucao > 0)
);

CREATE TABLE chamado (
    id_chamado    SERIAL PRIMARY KEY,
    titulo        VARCHAR(150) NOT NULL,
    descricao     TEXT NOT NULL,
    status        status_chamado NOT NULL DEFAULT 'ABERTO',
    prioridade    prioridade_chamado NOT NULL DEFAULT 'MEDIA',
    id_categoria  INT NOT NULL REFERENCES categoria(id_categoria),
    id_solicitante INT NOT NULL REFERENCES usuario(id_usuario),
    id_tecnico    INT REFERENCES usuario(id_usuario),
    aberto_em     TIMESTAMP NOT NULL DEFAULT now(),
    prazo_sla     TIMESTAMP,
    resolvido_em  TIMESTAMP,
    CHECK (id_tecnico IS NULL OR id_tecnico <> id_solicitante),
    CHECK (resolvido_em IS NULL OR resolvido_em >= aberto_em)
);

CREATE TABLE comentario (
    id_comentario SERIAL PRIMARY KEY,
    id_chamado    INT NOT NULL REFERENCES chamado(id_chamado) ON DELETE CASCADE,
    id_usuario    INT NOT NULL REFERENCES usuario(id_usuario),
    texto         TEXT NOT NULL,
    criado_em     TIMESTAMP NOT NULL DEFAULT now()
);

CREATE TABLE historico_status (
    id_historico    SERIAL PRIMARY KEY,
    id_chamado      INT NOT NULL REFERENCES chamado(id_chamado) ON DELETE CASCADE,
    status_anterior status_chamado,
    status_novo     status_chamado NOT NULL,
    alterado_em     TIMESTAMP NOT NULL DEFAULT now()
);

CREATE INDEX idx_chamado_status      ON chamado(status);
CREATE INDEX idx_chamado_tecnico     ON chamado(id_tecnico);
CREATE INDEX idx_chamado_solicitante ON chamado(id_solicitante);
CREATE INDEX idx_comentario_chamado  ON comentario(id_chamado);
