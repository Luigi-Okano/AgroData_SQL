USE agrodata;

-- Cria a tabela de contas caso não exista. A senha é um hash BCrypt; dados
-- pessoais são armazenados criptografados pela aplicação.
CREATE TABLE IF NOT EXISTS USUARIO (
    id_usuario    BIGINT AUTO_INCREMENT PRIMARY KEY,
    username      VARCHAR(50)  NOT NULL UNIQUE,
    senha_hash    VARCHAR(100) NOT NULL,
    role          VARCHAR(20)  NOT NULL,   -- ADMIN | PRODUTOR | IRRIGACAO
    ativo         BOOLEAN      NOT NULL DEFAULT TRUE,
    nome_completo VARCHAR(255) NULL,       -- criptografado (AES-GCM) pela aplicação
    cpf           VARCHAR(255) NULL,       -- criptografado
    email         VARCHAR(255) NULL,       -- criptografado
    telefone      VARCHAR(255) NULL        -- criptografado
);

-- Compatibilidade com bancos antigos: para cada coluna pessoal, consulta o
-- catálogo do MySQL e executa ALTER TABLE somente quando ela ainda não existe.
SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'USUARIO' AND COLUMN_NAME = 'nome_completo');
SET @q := IF(@c = 0, 'ALTER TABLE USUARIO ADD COLUMN nome_completo VARCHAR(255) NULL', 'SELECT 1');
PREPARE s FROM @q; EXECUTE s; DEALLOCATE PREPARE s;

SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'USUARIO' AND COLUMN_NAME = 'cpf');
SET @q := IF(@c = 0, 'ALTER TABLE USUARIO ADD COLUMN cpf VARCHAR(255) NULL', 'SELECT 1');
PREPARE s FROM @q; EXECUTE s; DEALLOCATE PREPARE s;

SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'USUARIO' AND COLUMN_NAME = 'email');
SET @q := IF(@c = 0, 'ALTER TABLE USUARIO ADD COLUMN email VARCHAR(255) NULL', 'SELECT 1');
PREPARE s FROM @q; EXECUTE s; DEALLOCATE PREPARE s;

SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'USUARIO' AND COLUMN_NAME = 'telefone');
SET @q := IF(@c = 0, 'ALTER TABLE USUARIO ADD COLUMN telefone VARCHAR(255) NULL', 'SELECT 1');
PREPARE s FROM @q; EXECUTE s; DEALLOCATE PREPARE s;

-- Adiciona a flag que a aplicação usa para exigir troca da senha provisória
-- no primeiro acesso; em contas antigas, o valor inicial fica FALSE.
SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'USUARIO' AND COLUMN_NAME = 'senha_temporaria');
SET @q := IF(@c = 0, 'ALTER TABLE USUARIO ADD COLUMN senha_temporaria BOOLEAN NOT NULL DEFAULT FALSE', 'SELECT 1');
PREPARE s FROM @q; EXECUTE s; DEALLOCATE PREPARE s;

-- Não insere uma conta ADMIN com credenciais fixas.
-- Defina ADMIN_USERNAME e ADMIN_PASSWORD antes do primeiro início da aplicação.
-- AdminBootstrap cria o primeiro ADMIN somente se USUARIO estiver vazia.
-- Não grave CPF/e-mail/telefone direto por SQL: a aplicação os criptografa
-- (valores em texto puro ainda são lidos, mas devem ser regravados pelo painel para ficarem criptografados).

-- Recomendação: crie uma conta exclusiva para a aplicação com privilégios mínimos.
-- Execute CREATE USER/GRANT com uma conta administrativa e substitua a senha
-- de exemplo; não use root na configuração normal da aplicação.
-- CREATE USER 'agrodata_app'@'localhost' IDENTIFIED BY 'TROQUE_POR_SENHA_FORTE';
-- GRANT SELECT, INSERT, UPDATE, DELETE ON agrodata.* TO 'agrodata_app'@'localhost';
