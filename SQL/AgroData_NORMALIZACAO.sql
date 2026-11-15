-- =====================================================================
-- AgroData - NORMALIZACAO E VALIDACAO NO BANCO
-- Execute depois de AgroData.sql e antes de AgroData_CARGA.sql.
-- Em banco existente, faça backup e execute este arquivo para proteger
-- os próximos INSERTs/UPDATEs; ele não reescreve os registros antigos.
-- Requer MySQL 8.0+ (REGEXP_REPLACE).
-- Execute com uma conta administrativa que possa alterar tabelas e criar gatilhos.
-- Para o PostgreSQL do Render, as regras equivalentes ficam em
-- AgroData-master/agrodata/src/main/resources/data-render.sql.
-- =====================================================================
USE agrodata;

-- A largura aceita os formatos com máscara antes que os gatilhos os convertam
-- para 11 dígitos de CPF e 8 dígitos de CEP.
ALTER TABLE PRODUTOR MODIFY COLUMN cpf VARCHAR(14) NOT NULL;
ALTER TABLE LOCALIZACAO MODIFY COLUMN cep VARCHAR(9) NOT NULL;

-- Compatibilidade para bancos criados antes da cultura "Outro".
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

-- DELIMITER troca temporariamente o terminador do cliente SQL: assim os pontos
-- e vírgulas dentro de cada bloco BEGIN/END não encerram o CREATE TRIGGER.
DELIMITER $$

-- PRODUTOR: os gatilhos BEFORE INSERT/UPDATE limpam espaços repetidos do nome,
-- removem a máscara do CPF e rejeitam nome vazio ou CPF diferente de 11 dígitos.
DROP TRIGGER IF EXISTS bi_produtor_normalizar$$
CREATE TRIGGER bi_produtor_normalizar
BEFORE INSERT ON PRODUTOR
FOR EACH ROW
BEGIN
    SET NEW.nome = TRIM(REGEXP_REPLACE(COALESCE(NEW.nome, ''), '[[:space:]]+', ' '));
    SET NEW.cpf = REGEXP_REPLACE(COALESCE(NEW.cpf, ''), '[^0-9]', '');

    IF NEW.nome = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'O nome do produtor e obrigatorio.';
    END IF;
    IF CHAR_LENGTH(NEW.cpf) <> 11 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'O CPF deve conter 11 digitos.';
    END IF;
END$$

DROP TRIGGER IF EXISTS bu_produtor_normalizar$$
CREATE TRIGGER bu_produtor_normalizar
BEFORE UPDATE ON PRODUTOR
FOR EACH ROW
BEGIN
    SET NEW.nome = TRIM(REGEXP_REPLACE(COALESCE(NEW.nome, ''), '[[:space:]]+', ' '));
    SET NEW.cpf = REGEXP_REPLACE(COALESCE(NEW.cpf, ''), '[^0-9]', '');

    IF NEW.nome = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'O nome do produtor e obrigatorio.';
    END IF;
    IF CHAR_LENGTH(NEW.cpf) <> 11 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'O CPF deve conter 11 digitos.';
    END IF;
END$$

-- LOCALIZACAO: normaliza espaços e UF, deixa somente dígitos no CEP e exige
-- rua, número, bairro, cidade, CEP com 8 dígitos e uma UF brasileira válida.
DROP TRIGGER IF EXISTS bi_localizacao_normalizar$$
CREATE TRIGGER bi_localizacao_normalizar
BEFORE INSERT ON LOCALIZACAO
FOR EACH ROW
BEGIN
    SET NEW.rua = TRIM(REGEXP_REPLACE(COALESCE(NEW.rua, ''), '[[:space:]]+', ' '));
    SET NEW.numero = TRIM(REGEXP_REPLACE(COALESCE(NEW.numero, ''), '[[:space:]]+', ' '));
    SET NEW.bairro = TRIM(REGEXP_REPLACE(COALESCE(NEW.bairro, ''), '[[:space:]]+', ' '));
    SET NEW.cidade = TRIM(REGEXP_REPLACE(COALESCE(NEW.cidade, ''), '[[:space:]]+', ' '));
    SET NEW.cep = REGEXP_REPLACE(COALESCE(NEW.cep, ''), '[^0-9]', '');
    SET NEW.estado = UPPER(TRIM(COALESCE(NEW.estado, '')));

    IF NEW.rua = '' OR NEW.numero = '' OR NEW.bairro = '' OR NEW.cidade = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Rua, numero, bairro e cidade sao obrigatorios.';
    END IF;
    IF NEW.cep NOT REGEXP '^[0-9]{8}$' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'O CEP deve conter 8 digitos.';
    END IF;
    IF NEW.estado NOT IN ('AC','AL','AM','AP','BA','CE','DF','ES','GO','MA','MG','MS','MT',
                          'PA','PB','PE','PI','PR','RJ','RN','RO','RR','RS','SC','SE','SP','TO') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Informe uma sigla de estado brasileira valida.';
    END IF;
END$$

DROP TRIGGER IF EXISTS bu_localizacao_normalizar$$
CREATE TRIGGER bu_localizacao_normalizar
BEFORE UPDATE ON LOCALIZACAO
FOR EACH ROW
BEGIN
    SET NEW.rua = TRIM(REGEXP_REPLACE(COALESCE(NEW.rua, ''), '[[:space:]]+', ' '));
    SET NEW.numero = TRIM(REGEXP_REPLACE(COALESCE(NEW.numero, ''), '[[:space:]]+', ' '));
    SET NEW.bairro = TRIM(REGEXP_REPLACE(COALESCE(NEW.bairro, ''), '[[:space:]]+', ' '));
    SET NEW.cidade = TRIM(REGEXP_REPLACE(COALESCE(NEW.cidade, ''), '[[:space:]]+', ' '));
    SET NEW.cep = REGEXP_REPLACE(COALESCE(NEW.cep, ''), '[^0-9]', '');
    SET NEW.estado = UPPER(TRIM(COALESCE(NEW.estado, '')));

    IF NEW.rua = '' OR NEW.numero = '' OR NEW.bairro = '' OR NEW.cidade = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Rua, numero, bairro e cidade sao obrigatorios.';
    END IF;
    IF NEW.cep NOT REGEXP '^[0-9]{8}$' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'O CEP deve conter 8 digitos.';
    END IF;
    IF NEW.estado NOT IN ('AC','AL','AM','AP','BA','CE','DF','ES','GO','MA','MG','MS','MT',
                          'PA','PB','PE','PI','PR','RJ','RN','RO','RR','RS','SC','SE','SP','TO') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Informe uma sigla de estado brasileira valida.';
    END IF;
END$$

-- FAZENDA: limpa espaços do nome e impede nome vazio ou área nula/não positiva.
DROP TRIGGER IF EXISTS bi_fazenda_normalizar$$
CREATE TRIGGER bi_fazenda_normalizar
BEFORE INSERT ON FAZENDA
FOR EACH ROW
BEGIN
    SET NEW.nome = TRIM(REGEXP_REPLACE(COALESCE(NEW.nome, ''), '[[:space:]]+', ' '));
    IF NEW.nome = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'O nome da fazenda e obrigatorio.';
    END IF;
    IF NEW.area_total IS NULL OR NEW.area_total <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'A area da fazenda deve ser maior que zero.';
    END IF;
END$$

DROP TRIGGER IF EXISTS bu_fazenda_normalizar$$
CREATE TRIGGER bu_fazenda_normalizar
BEFORE UPDATE ON FAZENDA
FOR EACH ROW
BEGIN
    SET NEW.nome = TRIM(REGEXP_REPLACE(COALESCE(NEW.nome, ''), '[[:space:]]+', ' '));
    IF NEW.nome = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'O nome da fazenda e obrigatorio.';
    END IF;
    IF NEW.area_total IS NULL OR NEW.area_total <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'A area da fazenda deve ser maior que zero.';
    END IF;
END$$

-- TALHAO: limpa o nome e o tipo de solo (vazio vira NULL); exige nome e área
-- positiva. O tipo de solo continua opcional.
DROP TRIGGER IF EXISTS bi_talhao_normalizar$$
CREATE TRIGGER bi_talhao_normalizar
BEFORE INSERT ON TALHAO
FOR EACH ROW
BEGIN
    SET NEW.nome = TRIM(REGEXP_REPLACE(COALESCE(NEW.nome, ''), '[[:space:]]+', ' '));
    IF NEW.tipo_solo IS NOT NULL THEN
        SET NEW.tipo_solo = NULLIF(TRIM(REGEXP_REPLACE(NEW.tipo_solo, '[[:space:]]+', ' ')), '');
    END IF;
    IF NEW.nome = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'O nome do talhao e obrigatorio.';
    END IF;
    IF NEW.area IS NULL OR NEW.area <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'A area do talhao deve ser maior que zero.';
    END IF;
    IF (NEW.umidade_minima_personalizada IS NULL) <> (NEW.umidade_maxima_personalizada IS NULL)
       OR (NEW.umidade_minima_personalizada IS NOT NULL AND
           (NEW.umidade_minima_personalizada < 0 OR NEW.umidade_maxima_personalizada > 100
            OR NEW.umidade_minima_personalizada >= NEW.umidade_maxima_personalizada)) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'A faixa de umidade personalizada e invalida.';
    END IF;
END$$

DROP TRIGGER IF EXISTS bu_talhao_normalizar$$
CREATE TRIGGER bu_talhao_normalizar
BEFORE UPDATE ON TALHAO
FOR EACH ROW
BEGIN
    SET NEW.nome = TRIM(REGEXP_REPLACE(COALESCE(NEW.nome, ''), '[[:space:]]+', ' '));
    IF NEW.tipo_solo IS NOT NULL THEN
        SET NEW.tipo_solo = NULLIF(TRIM(REGEXP_REPLACE(NEW.tipo_solo, '[[:space:]]+', ' ')), '');
    END IF;
    IF NEW.nome = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'O nome do talhao e obrigatorio.';
    END IF;
    IF NEW.area IS NULL OR NEW.area <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'A area do talhao deve ser maior que zero.';
    END IF;
    IF (NEW.umidade_minima_personalizada IS NULL) <> (NEW.umidade_maxima_personalizada IS NULL)
       OR (NEW.umidade_minima_personalizada IS NOT NULL AND
           (NEW.umidade_minima_personalizada < 0 OR NEW.umidade_maxima_personalizada > 100
            OR NEW.umidade_minima_personalizada >= NEW.umidade_maxima_personalizada)) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'A faixa de umidade personalizada e invalida.';
    END IF;
END$$

-- TELEFONE_PRODUTOR: remove pontuação, fornece "Celular" como tipo padrão e
-- aceita somente números com 10 a 13 dígitos.
DROP TRIGGER IF EXISTS bi_telefone_produtor_normalizar$$
CREATE TRIGGER bi_telefone_produtor_normalizar
BEFORE INSERT ON TELEFONE_PRODUTOR
FOR EACH ROW
BEGIN
    SET NEW.telefone = REGEXP_REPLACE(COALESCE(NEW.telefone, ''), '[^0-9]', '');
    SET NEW.tipo = COALESCE(NULLIF(TRIM(REGEXP_REPLACE(NEW.tipo, '[[:space:]]+', ' ')), ''), 'Celular');
    IF CHAR_LENGTH(NEW.telefone) NOT BETWEEN 10 AND 13 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'O telefone deve conter de 10 a 13 digitos.';
    END IF;
END$$

DROP TRIGGER IF EXISTS bu_telefone_produtor_normalizar$$
CREATE TRIGGER bu_telefone_produtor_normalizar
BEFORE UPDATE ON TELEFONE_PRODUTOR
FOR EACH ROW
BEGIN
    SET NEW.telefone = REGEXP_REPLACE(COALESCE(NEW.telefone, ''), '[^0-9]', '');
    SET NEW.tipo = COALESCE(NULLIF(TRIM(REGEXP_REPLACE(NEW.tipo, '[[:space:]]+', ' ')), ''), 'Celular');
    IF CHAR_LENGTH(NEW.telefone) NOT BETWEEN 10 AND 13 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'O telefone deve conter de 10 a 13 digitos.';
    END IF;
END$$

-- EMAIL_PRODUTOR: remove espaços externos, converte para minúsculas, fornece
-- um tipo padrão e exige @ com final .com ou .com.br.
DROP TRIGGER IF EXISTS bi_email_produtor_normalizar$$
CREATE TRIGGER bi_email_produtor_normalizar
BEFORE INSERT ON EMAIL_PRODUTOR
FOR EACH ROW
BEGIN
    SET NEW.email = LOWER(TRIM(COALESCE(NEW.email, '')));
    SET NEW.tipo = COALESCE(NULLIF(TRIM(REGEXP_REPLACE(NEW.tipo, '[[:space:]]+', ' ')), ''), 'Pessoal');
    IF NOT (NEW.email REGEXP '^[^[:space:]@]+@[^[:space:]@]+[.]com([.]br)?$') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'O e-mail deve conter @ e terminar em .com ou .com.br.';
    END IF;
END$$

DROP TRIGGER IF EXISTS bu_email_produtor_normalizar$$
CREATE TRIGGER bu_email_produtor_normalizar
BEFORE UPDATE ON EMAIL_PRODUTOR
FOR EACH ROW
BEGIN
    SET NEW.email = LOWER(TRIM(COALESCE(NEW.email, '')));
    SET NEW.tipo = COALESCE(NULLIF(TRIM(REGEXP_REPLACE(NEW.tipo, '[[:space:]]+', ' ')), ''), 'Pessoal');
    IF NOT (NEW.email REGEXP '^[^[:space:]@]+@[^[:space:]@]+[.]com([.]br)?$') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'O e-mail deve conter @ e terminar em .com ou .com.br.';
    END IF;
END$$

-- CULTURA: limpa espaços no nome e valida que os limites de umidade estejam
-- ordenados e dentro da faixa de 0 a 100 por cento.
DROP TRIGGER IF EXISTS bi_cultura_normalizar$$
CREATE TRIGGER bi_cultura_normalizar
BEFORE INSERT ON CULTURA
FOR EACH ROW
BEGIN
    SET NEW.nome = TRIM(REGEXP_REPLACE(COALESCE(NEW.nome, ''), '[[:space:]]+', ' '));
    IF NEW.nome = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'O nome da cultura e obrigatorio.';
    END IF;
    IF NEW.umidade_minima IS NULL OR NEW.umidade_maxima IS NULL
       OR NEW.umidade_minima < 0 OR NEW.umidade_maxima > 100
       OR NEW.umidade_minima >= NEW.umidade_maxima THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'A faixa de umidade da cultura e invalida.';
    END IF;
END$$

DROP TRIGGER IF EXISTS bu_cultura_normalizar$$
CREATE TRIGGER bu_cultura_normalizar
BEFORE UPDATE ON CULTURA
FOR EACH ROW
BEGIN
    SET NEW.nome = TRIM(REGEXP_REPLACE(COALESCE(NEW.nome, ''), '[[:space:]]+', ' '));
    IF NEW.nome = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'O nome da cultura e obrigatorio.';
    END IF;
    IF NEW.umidade_minima IS NULL OR NEW.umidade_maxima IS NULL
       OR NEW.umidade_minima < 0 OR NEW.umidade_maxima > 100
       OR NEW.umidade_minima >= NEW.umidade_maxima THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'A faixa de umidade da cultura e invalida.';
    END IF;
END$$

-- SENSOR: limpa o tipo, define ATIVO quando o status está ausente/vazio e
-- rejeita tipo de sensor vazio. O campo status é convertido para maiúsculas.
DROP TRIGGER IF EXISTS bi_sensor_normalizar$$
CREATE TRIGGER bi_sensor_normalizar
BEFORE INSERT ON SENSOR
FOR EACH ROW
BEGIN
    SET NEW.tipo_sensor = TRIM(REGEXP_REPLACE(COALESCE(NEW.tipo_sensor, ''), '[[:space:]]+', ' '));
    SET NEW.status = UPPER(TRIM(COALESCE(NEW.status, 'ATIVO')));
    IF NEW.status = '' THEN
        SET NEW.status = 'ATIVO';
    END IF;
    IF NEW.tipo_sensor = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'O tipo do sensor e obrigatorio.';
    END IF;
END$$

DROP TRIGGER IF EXISTS bu_sensor_normalizar$$
CREATE TRIGGER bu_sensor_normalizar
BEFORE UPDATE ON SENSOR
FOR EACH ROW
BEGIN
    SET NEW.tipo_sensor = TRIM(REGEXP_REPLACE(COALESCE(NEW.tipo_sensor, ''), '[[:space:]]+', ' '));
    SET NEW.status = UPPER(TRIM(COALESCE(NEW.status, 'ATIVO')));
    IF NEW.status = '' THEN
        SET NEW.status = 'ATIVO';
    END IF;
    IF NEW.tipo_sensor = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'O tipo do sensor e obrigatorio.';
    END IF;
END$$

-- USUARIO: limpa espaços do nome de usuário, converte o perfil para maiúsculas
-- e exige identificador válido, senha hash e perfil reconhecido. Campos pessoais
-- não são alterados aqui porque a aplicação os armazena criptografados.
DROP TRIGGER IF EXISTS bi_usuario_normalizar$$
CREATE TRIGGER bi_usuario_normalizar
BEFORE INSERT ON USUARIO
FOR EACH ROW
BEGIN
    SET NEW.username = TRIM(COALESCE(NEW.username, ''));
    SET NEW.role = UPPER(TRIM(COALESCE(NEW.role, '')));
    IF NEW.username NOT REGEXP '^[A-Za-z0-9._-]{3,50}$' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'O nome de usuario e obrigatorio e deve ter de 3 a 50 caracteres validos.';
    END IF;
    IF NEW.senha_hash IS NULL OR TRIM(NEW.senha_hash) = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'A senha criptografada e obrigatoria.';
    END IF;
    IF NEW.role NOT IN ('ADMIN', 'PRODUTOR', 'IRRIGACAO') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'O perfil do usuario e invalido.';
    END IF;
END$$

DROP TRIGGER IF EXISTS bu_usuario_normalizar$$
CREATE TRIGGER bu_usuario_normalizar
BEFORE UPDATE ON USUARIO
FOR EACH ROW
BEGIN
    SET NEW.username = TRIM(COALESCE(NEW.username, ''));
    SET NEW.role = UPPER(TRIM(COALESCE(NEW.role, '')));
    IF NEW.username NOT REGEXP '^[A-Za-z0-9._-]{3,50}$' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'O nome de usuario e obrigatorio e deve ter de 3 a 50 caracteres validos.';
    END IF;
    IF NEW.senha_hash IS NULL OR TRIM(NEW.senha_hash) = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'A senha criptografada e obrigatoria.';
    END IF;
    IF NEW.role NOT IN ('ADMIN', 'PRODUTOR', 'IRRIGACAO') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'O perfil do usuario e invalido.';
    END IF;
END$$

DELIMITER ;
