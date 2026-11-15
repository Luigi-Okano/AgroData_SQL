-- =====================================================================
-- AgroData - CARGA DE TESTE (destrutiva para os dados agrícolas).
-- Use somente em banco de desenvolvimento. Mantém a tabela USUARIO e suas contas.
-- Rode depois de SQL/AgroData.sql e SQL/AgroData_NORMALIZACAO.sql.
-- =====================================================================
USE agrodata;

-- Desativa temporariamente a checagem de chaves estrangeiras para permitir
-- limpar tabelas relacionadas; as tabelas são truncadas em sequência.
SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE COMANDO_IRRIGACAO;
TRUNCATE TABLE CLIMA;
TRUNCATE TABLE LEITURA_SENSOR;
TRUNCATE TABLE SENSOR;
TRUNCATE TABLE CONSUMO_AGUA;
TRUNCATE TABLE PRODUCAO_FAZENDA;
TRUNCATE TABLE TALHAO;
TRUNCATE TABLE CULTURA;
TRUNCATE TABLE FAZENDA;
TRUNCATE TABLE EMAIL_PRODUTOR;
TRUNCATE TABLE TELEFONE_PRODUTOR;
TRUNCATE TABLE PRODUTOR;
TRUNCATE TABLE LOCALIZACAO;
SET FOREIGN_KEY_CHECKS = 1;

-- Endereços fictícios de demonstração; cidade e CEP não são consultados em bases externas.
INSERT INTO LOCALIZACAO (rua, numero, bairro, cep, cidade, estado) VALUES
('Rodovia BR-163', 'km 500', 'Zona Rural', '78550000', 'Sinop', 'MT'),
('Estrada Municipal dos Pires', 's/n', 'Área Rural', '13400000', 'Piracicaba', 'SP'),
('Rodovia do Café', 'km 12', 'Distrito Industrial', '86900000', 'Jandaia do Sul', 'PR'),
('Av. Central das Lavouras', '1500', 'Vale Verde', '75700000', 'Catalão', 'GO'),
('Rodovia Anhanguera', 'km 320', 'Área Rural', '14000000', 'Ribeirão Preto', 'SP'),
('Estrada Vicinal do Produtor', 'km 8', 'Serrinha', '77800000', 'Araguaína', 'TO'),
('BR-364', 'km 450', 'Baixada', '78820000', 'Jaciara', 'MT');

-- Produtores de teste; após os TRUNCATE, os IDs são gerados na ordem destas linhas.
INSERT INTO PRODUTOR (nome, cpf) VALUES
('João da Silva Santos', '04918273645'),
('Maria Oliveira Souza', '19283746509'),
('Carlos Eduardo Lima', '88473625143'),
('Ana Paula Ferreira', '55443322109'),
('Roberto Carlos Mendes', '11223344556'),
('Juliana Ribeiro Costa', '99887766554'),
('Fernando Alves Rocha', '33445566778');

-- Telefones de teste associados aos produtores de mesmo ID.
INSERT INTO TELEFONE_PRODUTOR (id_produtor, telefone, tipo) VALUES
(1, '(66) 99123-4567', 'Celular'),
(2, '(19) 98877-6655', 'Celular'),
(3, '(43) 97766-5544', 'Celular'),
(4, '(64) 96655-4433', 'Celular'),
(5, '(16) 99555-1122', 'Celular'),
(6, '(63) 98444-3322', 'Celular'),
(7, '(65) 97333-2211', 'Celular');

-- E-mails de teste com domínio fictício e final .com, aceitos pela validação SQL.
INSERT INTO EMAIL_PRODUTOR (id_produtor, email, tipo) VALUES
(1, 'joao.silva.teste@agrodata-mock.com', 'Principal'),
(2, 'maria.souza.teste@agrodata-mock.com', 'Principal'),
(3, 'carlos.lima.teste@agrodata-mock.com', 'Principal'),
(4, 'ana.ferreira.teste@agrodata-mock.com', 'Principal'),
(5, 'roberto.mendes.teste@agrodata-mock.com', 'Principal'),
(6, 'juliana.costa.teste@agrodata-mock.com', 'Principal'),
(7, 'fernando.rocha.teste@agrodata-mock.com', 'Principal');

-- Fazendas de teste; cada linha referencia o produtor e o endereço correspondentes.
INSERT INTO FAZENDA (id_produtor, id_localizacao, nome, area_total) VALUES
(1, 1, 'Fazenda Santa Rita', 550.00),
(2, 2, 'Sítio Boa Vista', 120.50),
(3, 3, 'Fazenda AgroGold', 890.00),
(4, 4, 'Estância Alvorada', 340.20),
(5, 5, 'Fazenda Canaã', 1200.00),
(6, 6, 'Rancho Fundo', 450.75),
(7, 7, 'Fazenda Sol Nascente', 780.30);

-- Limites de umidade (%) por cultura. São valores demonstrativos; ajuste-os com
-- orientação agronômica para cada solo, estágio da planta e sensor utilizado.
INSERT INTO CULTURA (nome, umidade_minima, umidade_maxima) VALUES
('Soja',           40.00, 65.00),   -- id 1
('Milho',          45.00, 70.00),   -- id 2
('Cana-de-açúcar', 40.00, 65.00),   -- id 3
('Café',           35.00, 60.00),   -- id 4
('Feijão',         45.00, 70.00),   -- id 5
('Pastagem',       30.00, 60.00);   -- id 6

-- Talhões = áreas de cultivo dentro das fazendas. As culturas são exemplos
-- escolhidos para esta carga de teste.
INSERT INTO TALHAO (id_fazenda, id_cultura, nome, area, tipo_solo) VALUES
(1, 1, 'Talhão Norte A', 150.00, 'Argiloso'),
(1, 2, 'Talhão Sul B', 200.00, 'Arenoso'),
(2, 5, 'Talhão Principal', 120.50, 'Humífero'),
(3, 1, 'Talhão Soja 01', 400.00, 'Argiloso'),
(3, 2, 'Talhão Milho 02', 490.00, 'Médio'),
(4, 6, 'Talhão Pastagem', 340.20, 'Arenoso'),
(5, 3, 'Talhão Cana 01', 600.00, 'Argiloso'),
(5, 3, 'Talhão Cana 02', 600.00, 'Argiloso'),
(6, 5, 'Talhão Feijão', 450.75, 'Humífero'),
(7, 4, 'Talhão Café 01', 380.15, 'Argiloso'),
(7, 4, 'Talhão Café 02', 400.15, 'Médio');

-- Sensores de demonstração associados aos talhões inseridos acima.
INSERT INTO SENSOR (id_talhao, tipo_sensor, data_instalacao, status) VALUES
(1, 'Umidade e Temperatura do Solo', '2025-01-10', 'ATIVO'),
(2, 'Umidade e Temperatura do Solo', '2025-01-12', 'ATIVO'),
(3, 'Umidade do Solo', '2025-02-01', 'ATIVO'),
(4, 'Multissensores Climáticos', '2025-01-15', 'ATIVO'),
(5, 'Umidade e Temperatura do Solo', '2025-01-20', 'MANUTENCAO'),
(6, 'Umidade do Solo', '2025-02-10', 'ATIVO'),
(7, 'Multissensores Climáticos', '2025-01-05', 'ATIVO'),
(8, 'Umidade do Solo', '2025-02-15', 'ATIVO'),
(9, 'Umidade e Temperatura do Solo', '2025-01-28', 'ATIVO'),
(10, 'Multissensores Climáticos', '2025-02-05', 'ATIVO');

-- Procedimento temporário para gerar leituras históricas aleatórias de teste.
DELIMITER //

DROP PROCEDURE IF EXISTS GerarLeiturasMassaGrande//

CREATE PROCEDURE GerarLeiturasMassaGrande()
BEGIN
  DECLARE i INT DEFAULT 1;

  -- Gera 2.000 leituras distribuídas aleatoriamente nos últimos 90 dias.
  WHILE i <= 2000 DO
    INSERT INTO LEITURA_SENSOR (id_sensor, data_hora, umidade_solo, temperatura)
    VALUES (
      FLOOR(1 + (RAND() * 10)),                                   -- sensores de 1 a 10
      DATE_SUB(NOW(), INTERVAL FLOOR(RAND() * 2160) HOUR),
      ROUND(10 + (RAND() * 80), 2),
      ROUND(15 + (RAND() * 25), 2)
    );
    SET i = i + 1;
  END WHILE;

  -- Acrescenta uma leitura atual por sensor para o painel mostrar dados recentes.
  INSERT INTO LEITURA_SENSOR (id_sensor, data_hora, umidade_solo, temperatura)
  SELECT id_sensor, NOW(), ROUND(10 + (RAND() * 80), 2), ROUND(15 + (RAND() * 25), 2)
  FROM SENSOR;
END //

DELIMITER ;

CALL GerarLeiturasMassaGrande();
DROP PROCEDURE GerarLeiturasMassaGrande;

-- Cria comandos PENDENTES quando a leitura mais recente de um sensor ATIVO
-- está abaixo do limite mínimo da cultura associada ao talhão.
INSERT INTO COMANDO_IRRIGACAO (id_talhao, id_leitura, umidade_atual, umidade_minima, status)
SELECT t.id_talhao, l.id_leitura, l.umidade_solo, c.umidade_minima, 'PENDENTE'
FROM LEITURA_SENSOR l
JOIN SENSOR s  ON s.id_sensor = l.id_sensor AND s.status = 'ATIVO'
JOIN TALHAO t  ON t.id_talhao = s.id_talhao
JOIN CULTURA c ON c.id_cultura = t.id_cultura
WHERE l.data_hora = (SELECT MAX(l2.data_hora) FROM LEITURA_SENSOR l2 WHERE l2.id_sensor = l.id_sensor)
  AND l.umidade_solo < c.umidade_minima;
