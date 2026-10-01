-- Clinica del Sur - Esquema para Amazon RDS MySQL
-- Motor objetivo: MySQL 8.0.16 o superior
-- Incluye tablas, relaciones, restricciones, indices, vistas KPI y triggers.

CREATE DATABASE IF NOT EXISTS clinica
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_0900_ai_ci;

USE clinica;

-- 1. Pacientes
CREATE TABLE IF NOT EXISTS paciente (
    paciente_id       BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    ci                VARCHAR(20) NOT NULL,
    nombre            VARCHAR(100) NOT NULL,
    apellido          VARCHAR(100) NOT NULL,
    fecha_nacimiento  DATE NOT NULL,
    telefono          VARCHAR(20) NULL,
    email             VARCHAR(150) NULL,
    fecha_registro    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    activo            BOOLEAN NOT NULL DEFAULT TRUE,
    PRIMARY KEY (paciente_id),
    UNIQUE KEY uq_paciente_ci (ci),
    CONSTRAINT ck_paciente_email
        CHECK (email IS NULL OR LOCATE('@', email) > 1)
) ENGINE = InnoDB;

-- 2. Especialidades medicas
CREATE TABLE IF NOT EXISTS especialidad (
    especialidad_id  BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    nombre           VARCHAR(100) NOT NULL,
    descripcion      VARCHAR(255) NULL,
    estado           VARCHAR(20) NOT NULL DEFAULT 'ACTIVA',
    PRIMARY KEY (especialidad_id),
    UNIQUE KEY uq_especialidad_nombre (nombre),
    CONSTRAINT ck_especialidad_estado
        CHECK (estado IN ('ACTIVA', 'INACTIVA'))
) ENGINE = InnoDB;

-- 3. Medicos
CREATE TABLE IF NOT EXISTS medico (
    medico_id        BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    especialidad_id  BIGINT UNSIGNED NOT NULL,
    nombre           VARCHAR(100) NOT NULL,
    apellido         VARCHAR(100) NOT NULL,
    matricula        VARCHAR(50) NOT NULL,
    estado           VARCHAR(20) NOT NULL DEFAULT 'ACTIVO',
    PRIMARY KEY (medico_id),
    UNIQUE KEY uq_medico_matricula (matricula),
    KEY ix_medico_especialidad (especialidad_id),
    CONSTRAINT fk_medico_especialidad
        FOREIGN KEY (especialidad_id)
        REFERENCES especialidad (especialidad_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT ck_medico_estado
        CHECK (estado IN ('ACTIVO', 'INACTIVO'))
) ENGINE = InnoDB;

-- 4. Consultorios
CREATE TABLE IF NOT EXISTS consultorio (
    consultorio_id  BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    nombre          VARCHAR(50) NOT NULL,
    ubicacion       VARCHAR(100) NULL,
    estado          VARCHAR(20) NOT NULL DEFAULT 'DISPONIBLE',
    PRIMARY KEY (consultorio_id),
    UNIQUE KEY uq_consultorio_nombre (nombre),
    CONSTRAINT ck_consultorio_estado
        CHECK (estado IN ('DISPONIBLE', 'NO_DISPONIBLE'))
) ENGINE = InnoDB;

-- 5. Citas
CREATE TABLE IF NOT EXISTS cita (
    cita_id              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    paciente_id          BIGINT UNSIGNED NOT NULL,
    medico_id            BIGINT UNSIGNED NOT NULL,
    consultorio_id       BIGINT UNSIGNED NOT NULL,
    fecha_cita           DATE NOT NULL,
    hora_programada      TIME NOT NULL,
    fecha_hora           DATETIME GENERATED ALWAYS AS (
        TIMESTAMP(fecha_cita, hora_programada)
    ) STORED,
    fecha_llegada        DATETIME NULL,
    estado               VARCHAR(20) NOT NULL DEFAULT 'PROGRAMADA',
    motivo               VARCHAR(255) NULL,
    fecha_creacion       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
                         ON UPDATE CURRENT_TIMESTAMP,
    -- Reemplaza el indice parcial de PostgreSQL. Los valores NULL pueden repetirse.
    fecha_hora_activa    DATETIME GENERATED ALWAYS AS (
        CASE
            WHEN estado IN ('PROGRAMADA', 'CONFIRMADA')
                THEN TIMESTAMP(fecha_cita, hora_programada)
            ELSE NULL
        END
    ) STORED,
    PRIMARY KEY (cita_id),
    UNIQUE KEY uq_cita_medico_fecha_activa (medico_id, fecha_hora_activa),
    KEY ix_cita_paciente_fecha (paciente_id, fecha_hora),
    KEY ix_cita_medico_fecha (medico_id, fecha_hora),
    KEY ix_cita_consultorio_fecha (consultorio_id, fecha_hora),
    KEY ix_cita_estado_fecha (estado, fecha_hora),
    CONSTRAINT fk_cita_paciente
        FOREIGN KEY (paciente_id)
        REFERENCES paciente (paciente_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT fk_cita_medico
        FOREIGN KEY (medico_id)
        REFERENCES medico (medico_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT fk_cita_consultorio
        FOREIGN KEY (consultorio_id)
        REFERENCES consultorio (consultorio_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT ck_cita_estado
        CHECK (estado IN (
            'PROGRAMADA', 'CONFIRMADA', 'ATENDIDA',
            'CANCELADA', 'NO_ATENDIDA'
        )),
    CONSTRAINT ck_cita_motivo_cancelacion
        CHECK (estado <> 'CANCELADA' OR motivo IS NOT NULL),
    CONSTRAINT ck_cita_fecha_llegada
        CHECK (fecha_llegada IS NULL OR estado IN ('CONFIRMADA', 'ATENDIDA'))
) ENGINE = InnoDB;

-- 6. Atenciones. Una cita puede generar como maximo una atencion.
CREATE TABLE IF NOT EXISTS atencion (
    atencion_id      BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    cita_id          BIGINT UNSIGNED NOT NULL,
    fecha_atencion   DATETIME NOT NULL,
    estado           VARCHAR(20) NOT NULL DEFAULT 'EN_CURSO',
    observacion      VARCHAR(255) NULL,
    PRIMARY KEY (atencion_id),
    UNIQUE KEY uq_atencion_cita (cita_id),
    KEY ix_atencion_fecha_estado (fecha_atencion, estado),
    CONSTRAINT fk_atencion_cita
        FOREIGN KEY (cita_id)
        REFERENCES cita (cita_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT ck_atencion_estado
        CHECK (estado IN ('EN_CURSO', 'COMPLETADA', 'ANULADA'))
) ENGINE = InnoDB;

-- 7. Registro clinico asociado a la atencion.
-- Ampliacion respaldada por el acceso medico al historial clinico.
CREATE TABLE IF NOT EXISTS registro_clinico (
    registro_clinico_id  BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    atencion_id          BIGINT UNSIGNED NOT NULL,
    motivo_consulta      VARCHAR(500) NULL,
    diagnostico          VARCHAR(1000) NULL,
    tratamiento          VARCHAR(1000) NULL,
    indicaciones         VARCHAR(1000) NULL,
    fecha_registro       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (registro_clinico_id),
    UNIQUE KEY uq_registro_clinico_atencion (atencion_id),
    CONSTRAINT fk_registro_clinico_atencion
        FOREIGN KEY (atencion_id)
        REFERENCES atencion (atencion_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
) ENGINE = InnoDB;

-- 8. Pagos mencionados en el caso de negocio.
-- Ampliacion respaldada por la descripcion del negocio: consultas y pagos.
CREATE TABLE IF NOT EXISTS pago (
    pago_id          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    atencion_id      BIGINT UNSIGNED NOT NULL,
    monto            DECIMAL(12, 2) NOT NULL,
    moneda           CHAR(3) NOT NULL DEFAULT 'BOB',
    metodo           VARCHAR(20) NOT NULL,
    estado           VARCHAR(20) NOT NULL DEFAULT 'PENDIENTE',
    fecha_pago       DATETIME NULL,
    referencia       VARCHAR(100) NULL,
    fecha_registro   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (pago_id),
    KEY ix_pago_atencion (atencion_id),
    CONSTRAINT fk_pago_atencion
        FOREIGN KEY (atencion_id)
        REFERENCES atencion (atencion_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT ck_pago_monto
        CHECK (monto > 0),
    CONSTRAINT ck_pago_moneda
        CHECK (CHAR_LENGTH(moneda) = 3 AND moneda = UPPER(moneda)),
    CONSTRAINT ck_pago_metodo
        CHECK (metodo IN ('EFECTIVO', 'TARJETA', 'TRANSFERENCIA', 'QR', 'OTRO')),
    CONSTRAINT ck_pago_estado
        CHECK (estado IN ('PENDIENTE', 'PAGADO', 'ANULADO', 'REEMBOLSADO')),
    CONSTRAINT ck_pago_fecha
        CHECK (estado <> 'PAGADO' OR fecha_pago IS NOT NULL)
) ENGINE = InnoDB;

-- 9. Metadatos de archivos clinicos y reportes almacenados en Amazon S3.
-- El archivo binario permanece en S3; MySQL solo conserva su referencia y metadatos.
CREATE TABLE IF NOT EXISTS documento_s3 (
    documento_id     BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    paciente_id      BIGINT UNSIGNED NULL,
    atencion_id      BIGINT UNSIGNED NULL,
    categoria        VARCHAR(30) NOT NULL,
    nombre_archivo   VARCHAR(255) NOT NULL,
    s3_bucket        VARCHAR(63) NOT NULL,
    s3_object_key    VARCHAR(1024) NOT NULL,
    -- El hash permite unicidad sin exceder el limite de longitud de indices InnoDB.
    s3_object_hash   BINARY(32) GENERATED ALWAYS AS (
        UNHEX(SHA2(CONCAT(s3_bucket, '/', s3_object_key), 256))
    ) STORED,
    s3_etag          VARCHAR(128) NULL,
    tipo_mime        VARCHAR(100) NULL,
    visibilidad      VARCHAR(20) NOT NULL DEFAULT 'PRIVADO',
    fecha_carga      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (documento_id),
    UNIQUE KEY uq_documento_s3_hash (s3_object_hash),
    KEY ix_documento_paciente (paciente_id),
    KEY ix_documento_atencion (atencion_id),
    CONSTRAINT fk_documento_paciente
        FOREIGN KEY (paciente_id)
        REFERENCES paciente (paciente_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT fk_documento_atencion
        FOREIGN KEY (atencion_id)
        REFERENCES atencion (atencion_id)
        ON UPDATE CASCADE
        ON DELETE SET NULL,
    CONSTRAINT ck_documento_categoria
        CHECK (categoria IN (
            'LABORATORIO', 'RECETA', 'INFORME_MEDICO',
            'IMAGEN_MEDICA', 'REPORTE', 'OTRO'
        )),
    CONSTRAINT ck_documento_visibilidad
        CHECK (visibilidad IN ('PRIVADO', 'INTERNO')),
    CONSTRAINT ck_documento_propietario
        CHECK (categoria = 'REPORTE' OR paciente_id IS NOT NULL)
) ENGINE = InnoDB;

-- 10. Auditoria tecnica sin copiar datos clinicos sensibles.
-- Control tecnico para trazabilidad de accesos y operaciones administrativas.
CREATE TABLE IF NOT EXISTS auditoria_evento (
    auditoria_id     BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    tabla_afectada   VARCHAR(63) NOT NULL,
    registro_id      VARCHAR(100) NOT NULL,
    operacion        VARCHAR(10) NOT NULL,
    usuario_bd       VARCHAR(100) NOT NULL,
    fecha_evento     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (auditoria_id),
    KEY ix_auditoria_tabla_fecha (tabla_afectada, fecha_evento DESC),
    CONSTRAINT ck_auditoria_operacion
        CHECK (operacion IN ('INSERT', 'UPDATE', 'DELETE'))
) ENGINE = InnoDB;

-- Vistas de KPI

CREATE OR REPLACE VIEW kpi_pacientes_atendidos_mes AS
SELECT
    CAST(DATE_FORMAT(a.fecha_atencion, '%Y-%m-01') AS DATE) AS mes,
    COUNT(DISTINCT c.paciente_id) AS pacientes_atendidos
FROM atencion AS a
JOIN cita AS c ON c.cita_id = a.cita_id
WHERE a.estado = 'COMPLETADA'
GROUP BY CAST(DATE_FORMAT(a.fecha_atencion, '%Y-%m-01') AS DATE);

CREATE OR REPLACE VIEW kpi_citas_canceladas_mes AS
SELECT
    CAST(DATE_FORMAT(c.fecha_hora, '%Y-%m-01') AS DATE) AS mes,
    COUNT(*) AS total_citas,
    SUM(CASE WHEN c.estado = 'CANCELADA' THEN 1 ELSE 0 END) AS citas_canceladas,
    ROUND(
        100.0 * SUM(CASE WHEN c.estado = 'CANCELADA' THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0),
        2
    ) AS porcentaje_canceladas
FROM cita AS c
GROUP BY CAST(DATE_FORMAT(c.fecha_hora, '%Y-%m-01') AS DATE);

CREATE OR REPLACE VIEW kpi_atenciones_especialidad_mes AS
SELECT
    CAST(DATE_FORMAT(a.fecha_atencion, '%Y-%m-01') AS DATE) AS mes,
    e.especialidad_id,
    e.nombre AS especialidad,
    COUNT(*) AS total_atenciones
FROM atencion AS a
JOIN cita AS c ON c.cita_id = a.cita_id
JOIN medico AS m ON m.medico_id = c.medico_id
JOIN especialidad AS e ON e.especialidad_id = m.especialidad_id
WHERE a.estado = 'COMPLETADA'
GROUP BY
    CAST(DATE_FORMAT(a.fecha_atencion, '%Y-%m-01') AS DATE),
    e.especialidad_id,
    e.nombre;

CREATE OR REPLACE VIEW kpi_tiempo_espera_mes AS
SELECT
    CAST(DATE_FORMAT(a.fecha_atencion, '%Y-%m-01') AS DATE) AS mes,
    ROUND(AVG(TIMESTAMPDIFF(SECOND, c.fecha_llegada, a.fecha_atencion)) / 60.0, 2)
        AS minutos_promedio_espera
FROM atencion AS a
JOIN cita AS c ON c.cita_id = a.cita_id
WHERE a.estado = 'COMPLETADA'
  AND c.fecha_llegada IS NOT NULL
  AND a.fecha_atencion >= c.fecha_llegada
GROUP BY CAST(DATE_FORMAT(a.fecha_atencion, '%Y-%m-01') AS DATE);

CREATE OR REPLACE VIEW kpi_pacientes_recurrentes_mes AS
SELECT
    actual.mes,
    COUNT(*) AS pacientes_atendidos,
    SUM(
        CASE WHEN EXISTS (
            SELECT 1
            FROM atencion AS a_anterior
            JOIN cita AS c_anterior ON c_anterior.cita_id = a_anterior.cita_id
            WHERE c_anterior.paciente_id = actual.paciente_id
              AND a_anterior.estado = 'COMPLETADA'
              AND a_anterior.fecha_atencion < actual.mes
        ) THEN 1 ELSE 0 END
    ) AS pacientes_recurrentes,
    ROUND(
        100.0 * SUM(
            CASE WHEN EXISTS (
                SELECT 1
                FROM atencion AS a_anterior
                JOIN cita AS c_anterior ON c_anterior.cita_id = a_anterior.cita_id
                WHERE c_anterior.paciente_id = actual.paciente_id
                  AND a_anterior.estado = 'COMPLETADA'
                  AND a_anterior.fecha_atencion < actual.mes
            ) THEN 1 ELSE 0 END
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS porcentaje_recurrentes
FROM (
    SELECT DISTINCT
        c.paciente_id,
        CAST(DATE_FORMAT(a.fecha_atencion, '%Y-%m-01') AS DATE) AS mes
    FROM atencion AS a
    JOIN cita AS c ON c.cita_id = a.cita_id
    WHERE a.estado = 'COMPLETADA'
) AS actual
GROUP BY actual.mes;

-- Triggers y procedimientos
DELIMITER $$

DROP PROCEDURE IF EXISTS registrar_auditoria$$
CREATE PROCEDURE registrar_auditoria(
    IN p_tabla VARCHAR(63),
    IN p_registro_id VARCHAR(100),
    IN p_operacion VARCHAR(10)
)
BEGIN
    INSERT INTO auditoria_evento (
        tabla_afectada,
        registro_id,
        operacion,
        usuario_bd
    ) VALUES (
        p_tabla,
        p_registro_id,
        p_operacion,
        CURRENT_USER()
    );
END$$

-- Valida que la fecha de nacimiento no sea futura.
DROP TRIGGER IF EXISTS trg_paciente_fecha_insert$$
CREATE TRIGGER trg_paciente_fecha_insert
BEFORE INSERT ON paciente
FOR EACH ROW
BEGIN
    IF NEW.fecha_nacimiento > CURRENT_DATE() THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'La fecha de nacimiento no puede ser futura';
    END IF;
END$$

DROP TRIGGER IF EXISTS trg_paciente_fecha_update$$
CREATE TRIGGER trg_paciente_fecha_update
BEFORE UPDATE ON paciente
FOR EACH ROW
BEGIN
    IF NEW.fecha_nacimiento > CURRENT_DATE() THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'La fecha de nacimiento no puede ser futura';
    END IF;
END$$

-- Impide atenciones para citas canceladas, no asistidas o inexistentes.
DROP TRIGGER IF EXISTS trg_atencion_validar_insert$$
CREATE TRIGGER trg_atencion_validar_insert
BEFORE INSERT ON atencion
FOR EACH ROW
BEGIN
    DECLARE v_estado VARCHAR(20);

    SELECT estado INTO v_estado
    FROM cita
    WHERE cita_id = NEW.cita_id;

    IF v_estado IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'La cita indicada no existe';
    END IF;

    IF v_estado IN ('CANCELADA', 'NO_ATENDIDA') THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'La cita no puede generar una atencion';
    END IF;
END$$

DROP TRIGGER IF EXISTS trg_atencion_validar_update$$
CREATE TRIGGER trg_atencion_validar_update
BEFORE UPDATE ON atencion
FOR EACH ROW
BEGIN
    DECLARE v_estado VARCHAR(20);

    SELECT estado INTO v_estado
    FROM cita
    WHERE cita_id = NEW.cita_id;

    IF v_estado IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'La cita indicada no existe';
    END IF;

    IF v_estado IN ('CANCELADA', 'NO_ATENDIDA') THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'La cita no puede generar una atencion';
    END IF;
END$$

-- Sincroniza el estado de la cita cuando la atencion se completa.
DROP TRIGGER IF EXISTS trg_atencion_sincronizar_insert$$
CREATE TRIGGER trg_atencion_sincronizar_insert
AFTER INSERT ON atencion
FOR EACH ROW
BEGIN
    IF NEW.estado = 'COMPLETADA' THEN
        UPDATE cita
        SET estado = 'ATENDIDA'
        WHERE cita_id = NEW.cita_id
          AND estado <> 'ATENDIDA';
    END IF;
END$$

DROP TRIGGER IF EXISTS trg_atencion_sincronizar_update$$
CREATE TRIGGER trg_atencion_sincronizar_update
AFTER UPDATE ON atencion
FOR EACH ROW
BEGIN
    IF NEW.estado = 'COMPLETADA' AND OLD.estado <> 'COMPLETADA' THEN
        UPDATE cita
        SET estado = 'ATENDIDA'
        WHERE cita_id = NEW.cita_id
          AND estado <> 'ATENDIDA';
    END IF;
END$$

-- Evita asociar un documento S3 con un paciente diferente al de la atencion.
DROP TRIGGER IF EXISTS trg_documento_validar_insert$$
CREATE TRIGGER trg_documento_validar_insert
BEFORE INSERT ON documento_s3
FOR EACH ROW
BEGIN
    DECLARE v_paciente BIGINT UNSIGNED;

    IF NEW.atencion_id IS NOT NULL THEN
        SELECT c.paciente_id INTO v_paciente
        FROM atencion AS a
        JOIN cita AS c ON c.cita_id = a.cita_id
        WHERE a.atencion_id = NEW.atencion_id;

        IF v_paciente IS NULL THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'La atencion indicada no existe';
        END IF;

        IF NEW.paciente_id IS NULL OR v_paciente <> NEW.paciente_id THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'El documento no pertenece al paciente de la atencion';
        END IF;
    END IF;
END$$

DROP TRIGGER IF EXISTS trg_documento_validar_update$$
CREATE TRIGGER trg_documento_validar_update
BEFORE UPDATE ON documento_s3
FOR EACH ROW
BEGIN
    DECLARE v_paciente BIGINT UNSIGNED;

    IF NEW.atencion_id IS NOT NULL THEN
        SELECT c.paciente_id INTO v_paciente
        FROM atencion AS a
        JOIN cita AS c ON c.cita_id = a.cita_id
        WHERE a.atencion_id = NEW.atencion_id;

        IF v_paciente IS NULL THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'La atencion indicada no existe';
        END IF;

        IF NEW.paciente_id IS NULL OR v_paciente <> NEW.paciente_id THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'El documento no pertenece al paciente de la atencion';
        END IF;
    END IF;
END$$

-- Auditoria de tablas sensibles. No copia valores clinicos.
DROP TRIGGER IF EXISTS trg_aud_paciente_insert$$
CREATE TRIGGER trg_aud_paciente_insert AFTER INSERT ON paciente
FOR EACH ROW CALL registrar_auditoria('paciente', NEW.paciente_id, 'INSERT')$$
DROP TRIGGER IF EXISTS trg_aud_paciente_update$$
CREATE TRIGGER trg_aud_paciente_update AFTER UPDATE ON paciente
FOR EACH ROW CALL registrar_auditoria('paciente', NEW.paciente_id, 'UPDATE')$$
DROP TRIGGER IF EXISTS trg_aud_paciente_delete$$
CREATE TRIGGER trg_aud_paciente_delete AFTER DELETE ON paciente
FOR EACH ROW CALL registrar_auditoria('paciente', OLD.paciente_id, 'DELETE')$$

DROP TRIGGER IF EXISTS trg_aud_cita_insert$$
CREATE TRIGGER trg_aud_cita_insert AFTER INSERT ON cita
FOR EACH ROW CALL registrar_auditoria('cita', NEW.cita_id, 'INSERT')$$
DROP TRIGGER IF EXISTS trg_aud_cita_update$$
CREATE TRIGGER trg_aud_cita_update AFTER UPDATE ON cita
FOR EACH ROW CALL registrar_auditoria('cita', NEW.cita_id, 'UPDATE')$$
DROP TRIGGER IF EXISTS trg_aud_cita_delete$$
CREATE TRIGGER trg_aud_cita_delete AFTER DELETE ON cita
FOR EACH ROW CALL registrar_auditoria('cita', OLD.cita_id, 'DELETE')$$

DROP TRIGGER IF EXISTS trg_aud_atencion_insert$$
CREATE TRIGGER trg_aud_atencion_insert AFTER INSERT ON atencion
FOR EACH ROW CALL registrar_auditoria('atencion', NEW.atencion_id, 'INSERT')$$
DROP TRIGGER IF EXISTS trg_aud_atencion_update$$
CREATE TRIGGER trg_aud_atencion_update AFTER UPDATE ON atencion
FOR EACH ROW CALL registrar_auditoria('atencion', NEW.atencion_id, 'UPDATE')$$
DROP TRIGGER IF EXISTS trg_aud_atencion_delete$$
CREATE TRIGGER trg_aud_atencion_delete AFTER DELETE ON atencion
FOR EACH ROW CALL registrar_auditoria('atencion', OLD.atencion_id, 'DELETE')$$

DROP TRIGGER IF EXISTS trg_aud_registro_insert$$
CREATE TRIGGER trg_aud_registro_insert AFTER INSERT ON registro_clinico
FOR EACH ROW CALL registrar_auditoria('registro_clinico', NEW.registro_clinico_id, 'INSERT')$$
DROP TRIGGER IF EXISTS trg_aud_registro_update$$
CREATE TRIGGER trg_aud_registro_update AFTER UPDATE ON registro_clinico
FOR EACH ROW CALL registrar_auditoria('registro_clinico', NEW.registro_clinico_id, 'UPDATE')$$
DROP TRIGGER IF EXISTS trg_aud_registro_delete$$
CREATE TRIGGER trg_aud_registro_delete AFTER DELETE ON registro_clinico
FOR EACH ROW CALL registrar_auditoria('registro_clinico', OLD.registro_clinico_id, 'DELETE')$$

DROP TRIGGER IF EXISTS trg_aud_pago_insert$$
CREATE TRIGGER trg_aud_pago_insert AFTER INSERT ON pago
FOR EACH ROW CALL registrar_auditoria('pago', NEW.pago_id, 'INSERT')$$
DROP TRIGGER IF EXISTS trg_aud_pago_update$$
CREATE TRIGGER trg_aud_pago_update AFTER UPDATE ON pago
FOR EACH ROW CALL registrar_auditoria('pago', NEW.pago_id, 'UPDATE')$$
DROP TRIGGER IF EXISTS trg_aud_pago_delete$$
CREATE TRIGGER trg_aud_pago_delete AFTER DELETE ON pago
FOR EACH ROW CALL registrar_auditoria('pago', OLD.pago_id, 'DELETE')$$

DROP TRIGGER IF EXISTS trg_aud_documento_insert$$
CREATE TRIGGER trg_aud_documento_insert AFTER INSERT ON documento_s3
FOR EACH ROW CALL registrar_auditoria('documento_s3', NEW.documento_id, 'INSERT')$$
DROP TRIGGER IF EXISTS trg_aud_documento_update$$
CREATE TRIGGER trg_aud_documento_update AFTER UPDATE ON documento_s3
FOR EACH ROW CALL registrar_auditoria('documento_s3', NEW.documento_id, 'UPDATE')$$
DROP TRIGGER IF EXISTS trg_aud_documento_delete$$
CREATE TRIGGER trg_aud_documento_delete AFTER DELETE ON documento_s3
FOR EACH ROW CALL registrar_auditoria('documento_s3', OLD.documento_id, 'DELETE')$$

DELIMITER ;

-- Relaciones principales:
-- especialidad 1 ---- N medico
-- paciente     1 ---- N cita
-- medico       1 ---- N cita
-- consultorio  1 ---- N cita
-- cita         1 ---- 0..1 atencion
-- atencion     1 ---- 0..1 registro_clinico
-- atencion     1 ---- N pago
-- paciente     1 ---- N documento_s3
-- atencion     1 ---- N documento_s3 (opcional)
--
-- AWS IAM se administra fuera de MySQL. El sitio web publico y los documentos
-- clinicos privados deben usar buckets o prefijos con politicas separadas.
