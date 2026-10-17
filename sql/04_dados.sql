-- 04: dados de exemplo
SET search_path TO chamados;

INSERT INTO departamento(nome) VALUES ('TI'), ('Financeiro'), ('RH'), ('Comercial');

INSERT INTO usuario(nome, email, perfil, id_departamento) VALUES
 ('Ana Souza',    'ana@empresa.com',    'CLIENTE', 2),
 ('Bruno Lima',   'bruno@empresa.com',  'CLIENTE', 3),
 ('Carla Dias',   'carla@empresa.com',  'CLIENTE', 4),
 ('Diego Alves',  'diego@empresa.com',  'TECNICO', 1),
 ('Elisa Nunes',  'elisa@empresa.com',  'TECNICO', 1),
 ('Fábio Rocha',  'fabio@empresa.com',  'ADMIN',   1);

INSERT INTO categoria(nome, descricao) VALUES
 ('Hardware', 'Computadores, impressoras e periféricos'),
 ('Software', 'Instalação e erros de aplicações'),
 ('Rede',     'Internet, VPN e acesso a servidores'),
 ('Acesso',   'Senhas e permissões');

INSERT INTO sla(prioridade, horas_resolucao) VALUES ('CRITICA', 4), ('ALTA', 8), ('MEDIA', 24), ('BAIXA', 72);

SELECT fn_abrir_chamado('Impressora não imprime', 'Fila travada no setor financeiro', 1, 1, 'MEDIA');
SELECT fn_abrir_chamado('VPN fora do ar', 'Ninguém consegue conectar', 3, 2, 'CRITICA');
SELECT fn_abrir_chamado('Instalar Office', 'Novo notebook', 2, 3, 'BAIXA');
SELECT fn_abrir_chamado('Resetar senha do ERP', 'Esqueci a senha', 4, 1, 'ALTA');

SELECT fn_atribuir_chamado(2, 4);
SELECT fn_atribuir_chamado(4, 5);
UPDATE chamado SET status = 'RESOLVIDO' WHERE id_chamado = 4;

INSERT INTO comentario(id_chamado, id_usuario, texto) VALUES
 (2, 4, 'Reiniciando o concentrador de VPN.'),
 (4, 5, 'Senha redefinida e enviada por e-mail.');
