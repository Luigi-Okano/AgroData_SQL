-- Atualização de bancos legados que ainda não têm as tabelas/coluna de irrigação.
-- Não substitui o esquema completo SQL/AgroData.sql.
-- CREATE TABLE IF NOT EXISTS e a verificação de coluna permitem reaplicar
-- as partes de criação sem recriar estruturas que já existam.
USE agrodata;

-- 1) Catálogo das culturas e seus limites de umidade do solo (%).
CREATE TABLE IF NOT EXISTS CULTURA (
    id_cultura     INT AUTO_INCREMENT PRIMARY KEY,
    nome           VARCHAR(50) NOT NULL UNIQUE,
    umidade_minima DOUBLE NOT NULL,  -- abaixo disso: REGAR
    umidade_maxima DOUBLE NOT NULL,  -- acima disso: excesso de água
    CONSTRAINT chk_cultura_faixa CHECK (umidade_minima >= 0 AND umidade_maxima <= 100 AND umidade_minima < umidade_maxima)
);

-- 2) Fila/histórico de ordens de irrigação. A ordem referencia o talhão e,
-- opcionalmente, a leitura que motivou a irrigação.
CREATE TABLE IF NOT EXISTS COMANDO_IRRIGACAO (
    id_comando     INT AUTO_INCREMENT PRIMARY KEY,
    id_talhao      INT NOT NULL,
    id_leitura     INT NULL,
    umidade_atual  DOUBLE NOT NULL,
    umidade_minima DOUBLE NOT NULL,
    status         VARCHAR(20) NOT NULL DEFAULT 'PENDENTE',  -- PENDENTE | ENVIADO | CONCLUIDO | CANCELADO
    criado_em      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    enviado_em     DATETIME NULL,
    concluido_em   DATETIME NULL,
    CONSTRAINT fk_comando_talhao FOREIGN KEY (id_talhao) REFERENCES TALHAO(id_talhao) ON DELETE CASCADE
);

-- 3) Associa uma cultura ao talhão. Consulta information_schema para evitar
-- adicionar novamente a coluna e a chave estrangeira quando já existem.
SET @existe := (SELECT COUNT(*) FROM information_schema.COLUMNS
                WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'TALHAO' AND COLUMN_NAME = 'id_cultura');
SET @ddl := IF(@existe = 0,
    'ALTER TABLE TALHAO ADD COLUMN id_cultura INT NULL, ADD CONSTRAINT fk_talhao_cultura FOREIGN KEY (id_cultura) REFERENCES CULTURA(id_cultura)',
    'SELECT ''coluna id_cultura já existe''');
PREPARE stmt FROM @ddl; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 4) Faixa de umidade opcional para a cultura definida como "Outro".
SET @existe := (SELECT COUNT(*) FROM information_schema.COLUMNS
                WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'TALHAO'
                  AND COLUMN_NAME = 'umidade_minima_personalizada');
SET @ddl := IF(@existe = 0,
    'ALTER TABLE TALHAO ADD COLUMN umidade_minima_personalizada DOUBLE NULL',
    'SELECT ''coluna umidade_minima_personalizada já existe''');
PREPARE stmt FROM @ddl; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @existe := (SELECT COUNT(*) FROM information_schema.COLUMNS
                WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'TALHAO'
                  AND COLUMN_NAME = 'umidade_maxima_personalizada');
SET @ddl := IF(@existe = 0,
    'ALTER TABLE TALHAO ADD COLUMN umidade_maxima_personalizada DOUBLE NULL',
    'SELECT ''coluna umidade_maxima_personalizada já existe''');
PREPARE stmt FROM @ddl; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 5) Insere limites de referência. ON DUPLICATE KEY UPDATE atualiza os valores
-- se a cultura já existir, evitando duplicidade pelo nome único.
INSERT INTO CULTURA (nome, umidade_minima, umidade_maxima) VALUES
 ('Soja',             40.00, 65.00),
 ('Milho',            45.00, 70.00),
 ('Cana-de-açúcar',   40.00, 65.00),
 ('Café',             35.00, 60.00),
 ('Feijão',           45.00, 70.00),
 ('Pastagem',         30.00, 60.00)
ON DUPLICATE KEY UPDATE umidade_minima = VALUES(umidade_minima), umidade_maxima = VALUES(umidade_maxima);

-- 6) Vincula automaticamente talhões cujo nome indica a cultura plantada.
-- LIKE também encontra sufixos e numeração, por exemplo "Talhão Soja 01".
UPDATE TALHAO SET id_cultura = (SELECT id_cultura FROM CULTURA WHERE nome = 'Soja')           WHERE nome LIKE '%Soja%';
UPDATE TALHAO SET id_cultura = (SELECT id_cultura FROM CULTURA WHERE nome = 'Milho')          WHERE nome LIKE '%Milho%';
UPDATE TALHAO SET id_cultura = (SELECT id_cultura FROM CULTURA WHERE nome = 'Cana-de-açúcar') WHERE nome LIKE '%Cana%';
UPDATE TALHAO SET id_cultura = (SELECT id_cultura FROM CULTURA WHERE nome = 'Café')           WHERE nome LIKE '%Café%';
UPDATE TALHAO SET id_cultura = (SELECT id_cultura FROM CULTURA WHERE nome = 'Feijão')         WHERE nome LIKE '%Feij%';
UPDATE TALHAO SET id_cultura = (SELECT id_cultura FROM CULTURA WHERE nome = 'Pastagem')       WHERE nome LIKE '%Pastagem%';

-- Talhões sem indicação da cultura no nome (ex.: "Talhão Norte A") precisam
-- ser associados manualmente, usando seu id_talhao:
-- UPDATE TALHAO SET id_cultura = (SELECT id_cultura FROM CULTURA WHERE nome = 'Soja') WHERE id_talhao = 1;
