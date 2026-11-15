-- =====================================================================
-- AgroData - ESQUEMA COMPLETO (banco novo). Rode ANTES de subir a aplicação.
-- Ordem: SQL/AgroData.sql -> SQL/AgroData_NORMALIZACAO.sql -> SQL/AgroData_CARGA.sql (somente teste) -> SQL/AgroData_SEGURANCA.sql.
-- Em banco antigo, use SQL/Irrigacao_AgroData.sql somente para aplicar a parte de irrigação.
-- Este arquivo cria as tabelas principais e inclui alguns registros iniciais de demonstração.
-- =====================================================================
-- Cria o banco apenas se ainda não existir e seleciona-o para os comandos seguintes.
CREATE DATABASE IF NOT EXISTS agrodata;
USE agrodata;

-- Cadastro base do produtor. O CPF é único e aceita máscara temporariamente;
-- o script AgroData_NORMALIZACAO.sql remove a máscara antes de gravar.
CREATE TABLE PRODUTOR (
    id_produtor BIGINT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    cpf VARCHAR(14) NOT NULL UNIQUE
);

-- Um produtor pode ter vários telefones. Ao excluir o produtor, seus telefones
-- também são excluídos (ON DELETE CASCADE).
CREATE TABLE TELEFONE_PRODUTOR (
    id_telefone BIGINT AUTO_INCREMENT PRIMARY KEY,
    id_produtor BIGINT NOT NULL,
    telefone VARCHAR(20) NOT NULL,
    tipo VARCHAR(20) DEFAULT 'Celular',
    CONSTRAINT fk_telefone_produtor FOREIGN KEY (id_produtor) REFERENCES PRODUTOR(id_produtor) ON DELETE CASCADE
);

-- Um produtor pode ter vários e-mails; eles também acompanham a exclusão do produtor.
CREATE TABLE EMAIL_PRODUTOR (
    id_email BIGINT AUTO_INCREMENT PRIMARY KEY,
    id_produtor BIGINT NOT NULL,
    email VARCHAR(100) NOT NULL,
    tipo VARCHAR(20) DEFAULT 'Pessoal',
    CONSTRAINT fk_email_produtor FOREIGN KEY (id_produtor) REFERENCES PRODUTOR(id_produtor) ON DELETE CASCADE
);

-- Endereço e coordenadas opcionais da fazenda; coordenadas habilitam previsão de chuva.
CREATE TABLE LOCALIZACAO (
    id_localizacao BIGINT AUTO_INCREMENT PRIMARY KEY,
    rua VARCHAR(150) NOT NULL,
    numero VARCHAR(20) NOT NULL,
    bairro VARCHAR(100) NOT NULL,
    cep VARCHAR(9) NOT NULL,
    cidade VARCHAR(100) NOT NULL,
    estado CHAR(2) NOT NULL,
    latitude DECIMAL(10,7) NULL,
    longitude DECIMAL(11,7) NULL,
    CONSTRAINT chk_localizacao_coordenadas CHECK (
        (latitude IS NULL AND longitude IS NULL) OR
        (latitude IS NOT NULL AND longitude IS NOT NULL AND
         latitude BETWEEN -90 AND 90 AND longitude BETWEEN -180 AND 180)
    )
);

-- Cada fazenda pertence a um produtor e tem um endereço cadastrado.
-- As chaves estrangeiras impedem referências inexistentes e propagam exclusões.
CREATE TABLE FAZENDA (
    id_fazenda BIGINT AUTO_INCREMENT PRIMARY KEY,
    id_produtor BIGINT NOT NULL,
    id_localizacao BIGINT NOT NULL,
    nome VARCHAR(100) NOT NULL,
    area_total DECIMAL(10,2) NOT NULL,
    CONSTRAINT fk_fazenda_produtor FOREIGN KEY (id_produtor) REFERENCES PRODUTOR(id_produtor) ON DELETE CASCADE,
    CONSTRAINT fk_fazenda_loc FOREIGN KEY (id_localizacao) REFERENCES LOCALIZACAO(id_localizacao) ON DELETE CASCADE
);

-- Parâmetros de umidade do solo (%) adequados para cada cultura.
-- A restrição CHECK limita a faixa a valores coerentes entre 0 e 100.
CREATE TABLE CULTURA (
    id_cultura BIGINT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(50) NOT NULL UNIQUE,
    umidade_minima DOUBLE NOT NULL,   -- abaixo disso: REGAR
    umidade_maxima DOUBLE NOT NULL,   -- acima disso: excesso de água
    CONSTRAINT chk_cultura_faixa CHECK (umidade_minima >= 0 AND umidade_maxima <= 100 AND umidade_minima < umidade_maxima)
);

-- Área de cultivo dentro de uma fazenda. A cultura é opcional para permitir
-- cadastro do talhão antes de definir o que será plantado.
CREATE TABLE TALHAO (
    id_talhao BIGINT AUTO_INCREMENT PRIMARY KEY,
    id_fazenda BIGINT NOT NULL,
    id_cultura BIGINT NULL,
    nome VARCHAR(50) NOT NULL,
    area DECIMAL(10,2) NOT NULL,
    tipo_solo VARCHAR(50),
    CONSTRAINT fk_talhao_fazenda FOREIGN KEY (id_fazenda) REFERENCES FAZENDA(id_fazenda) ON DELETE CASCADE,
    CONSTRAINT fk_talhao_cultura FOREIGN KEY (id_cultura) REFERENCES CULTURA(id_cultura)
);

-- Sensor instalado em um talhão; a data de instalação pode ser desconhecida.
CREATE TABLE SENSOR (
    id_sensor BIGINT AUTO_INCREMENT PRIMARY KEY,
    id_talhao BIGINT NOT NULL,
    tipo_sensor VARCHAR(50) NOT NULL,
    data_instalacao DATE NULL,
    status VARCHAR(20) DEFAULT 'ATIVO',
    CONSTRAINT fk_sensor_talhao FOREIGN KEY (id_talhao) REFERENCES TALHAO(id_talhao) ON DELETE CASCADE
);

-- Leituras coletadas pelos sensores. Se o sensor for excluído, seu histórico
-- também é removido.
CREATE TABLE LEITURA_SENSOR (
    id_leitura BIGINT AUTO_INCREMENT PRIMARY KEY,
    id_sensor BIGINT NOT NULL,
    data_hora DATETIME NOT NULL,
    umidade_solo DOUBLE NOT NULL,
    temperatura DOUBLE NOT NULL,
    CONSTRAINT fk_leitura_sensor FOREIGN KEY (id_sensor) REFERENCES SENSOR(id_sensor) ON DELETE CASCADE
);

-- Ordens de irrigação associadas ao talhão e, quando disponível, à leitura
-- que motivou a ordem. A leitura pode ser removida sem apagar o comando.
CREATE TABLE COMANDO_IRRIGACAO (
    id_comando BIGINT AUTO_INCREMENT PRIMARY KEY,
    id_talhao BIGINT NOT NULL,
    id_leitura BIGINT NULL,
    umidade_atual DOUBLE NOT NULL,
    umidade_minima DOUBLE NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDENTE',   -- PENDENTE | ENVIADO | CONCLUIDO | CANCELADO
    criado_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    enviado_em DATETIME NULL,
    concluido_em DATETIME NULL,
    CONSTRAINT fk_comando_talhao FOREIGN KEY (id_talhao) REFERENCES TALHAO(id_talhao) ON DELETE CASCADE,
    CONSTRAINT fk_comando_leitura FOREIGN KEY (id_leitura) REFERENCES LEITURA_SENSOR(id_leitura) ON DELETE SET NULL
);

-- Dados climáticos opcionais relacionados a um talhão. Se ele for excluído,
-- a leitura climática permanece sem vínculo com talhão.
CREATE TABLE CLIMA (
    id_clima BIGINT AUTO_INCREMENT PRIMARY KEY,
    id_talhao BIGINT NULL,
    probabilidade_chuva DOUBLE NULL,
    temperatura_ambiente DOUBLE NULL,
    umidade_ar DOUBLE NULL,
    data_registro DATETIME NULL,
    CONSTRAINT fk_clima_talhao FOREIGN KEY (id_talhao) REFERENCES TALHAO(id_talhao) ON DELETE SET NULL
);

-- Volume de água usado por talhão em uma data específica.
CREATE TABLE CONSUMO_AGUA (
    id_consumo BIGINT AUTO_INCREMENT PRIMARY KEY,
    id_talhao BIGINT NOT NULL,
    volume_litros DECIMAL(10,2) NOT NULL,
    data_registro DATETIME NOT NULL,
    CONSTRAINT fk_consumo_talhao FOREIGN KEY (id_talhao) REFERENCES TALHAO(id_talhao) ON DELETE CASCADE
);

-- Quantidade colhida por talhão, cultura e data de colheita.
CREATE TABLE PRODUCAO_FAZENDA (
    id_producao BIGINT AUTO_INCREMENT PRIMARY KEY,
    id_talhao BIGINT NOT NULL,
    cultura VARCHAR(50) NOT NULL,
    quantidade_colhida_kg DECIMAL(10,2) NOT NULL,
    data_colheita DATE NOT NULL,
    CONSTRAINT fk_producao_talhao FOREIGN KEY (id_talhao) REFERENCES TALHAO(id_talhao) ON DELETE CASCADE
);

-- Contas para autenticação e autorização. A senha é armazenada como hash BCrypt;
-- dados pessoais são criptografados pela aplicação, portanto ficam NULLáveis.
CREATE TABLE USUARIO (
    id_usuario BIGINT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    senha_hash VARCHAR(100) NOT NULL,
    role VARCHAR(20) NOT NULL,                       -- ADMIN | PRODUTOR | IRRIGACAO
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    senha_temporaria BOOLEAN NOT NULL DEFAULT FALSE,
    nome_completo VARCHAR(255) NULL,                 -- criptografado (AES-GCM)
    cpf VARCHAR(255) NULL,                           -- criptografado
    email VARCHAR(255) NULL,                         -- criptografado
    telefone VARCHAR(255) NULL                       -- criptografado
);

-- Pequeno conjunto inicial para demonstração: produtor, endereço, fazenda,
-- cultura, talhão, sensor, leitura e consumo. A carga de teste substitui
-- esses registros agrícolas, mas preserva as contas da tabela USUARIO.
INSERT INTO PRODUTOR (nome, cpf) VALUES ('Carlos Alberto Silva', '12345678901');
INSERT INTO LOCALIZACAO (rua, numero, bairro, cep, cidade, estado) VALUES ('Rodovia SP-340', 'km 120', 'Zona Rural', '13840000', 'Mogi Mirim', 'SP');
INSERT INTO FAZENDA (id_produtor, id_localizacao, nome, area_total) VALUES (1, 1, 'Fazenda Boa Esperança', 150.50);
INSERT INTO CULTURA (nome, umidade_minima, umidade_maxima) VALUES ('Soja', 40.00, 65.00);
INSERT INTO TALHAO (id_fazenda, id_cultura, nome, area, tipo_solo) VALUES (1, 1, 'Talhão Norte - Soja', 50.00, 'Argiloso');
INSERT INTO SENSOR (id_talhao, tipo_sensor, data_instalacao, status) VALUES (1, 'Umidade do Solo', '2026-08-10', 'ATIVO');
INSERT INTO LEITURA_SENSOR (id_sensor, data_hora, umidade_solo, temperatura) VALUES (1, '2026-11-07 08:00:00', 28.50, 24.00);
INSERT INTO CONSUMO_AGUA (id_talhao, volume_litros, data_registro) VALUES (1, 1500.50, '2026-11-07 10:00:00');
