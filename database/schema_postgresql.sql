-- Clinica del Sur - Esquema para Amazon RDS PostgreSQL
-- Motor objetivo: PostgreSQL 15 o superior
-- Este archivo crea tablas, relaciones, restricciones, indices y vistas para KPI.

BEGIN;

CREATE SCHEMA IF NOT EXISTS clinica;
SET search_path TO clinica, public;

-- 1. Pacientes
CREATE TABLE IF NOT EXISTS paciente (
    paciente_id       BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ci                VARCHAR(20) NOT NULL UNIQUE,
    nombre            VARCHAR(100) NOT NULL,
    apellido          VARCHAR(100) NOT NULL,
    fecha_nacimiento  DATE NOT NULL,
    telefono          VARCHAR(20),
    email             VARCHAR(150),
    fecha_registro    TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    activo            BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT ck_paciente_email
        CHECK (email IS NULL OR position('@' IN email) > 1),
    CONSTRAINT ck_paciente_fecha_nacimiento
        CHECK (fecha_nacimiento <= CURRENT_DATE)
);

-- 2. Especialidades medicas
CREATE TABLE IF NOT EXISTS especialidad (
    especialidad_id  BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre           VARCHAR(100) NOT NULL UNIQUE,
    descripcion      VARCHAR(255),
    estado           VARCHAR(20) NOT NULL DEFAULT 'ACTIVA',
    CONSTRAINT ck_especialidad_estado
        CHECK (estado IN ('ACTIVA', 'INACTIVA'))
);

-- 3. Medicos
CREATE TABLE IF NOT EXISTS medico (
    medico_id        BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    especialidad_id  BIGINT NOT NULL,
    nombre           VARCHAR(100) NOT NULL,
    apellido         VARCHAR(100) NOT NULL,
    matricula        VARCHAR(50) NOT NULL UNIQUE,
    estado           VARCHAR(20) NOT NULL DEFAULT 'ACTIVO',
    CONSTRAINT fk_medico_especialidad
        FOREIGN KEY (especialidad_id)
        REFERENCES especialidad (especialidad_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT ck_medico_estado
        CHECK (estado IN ('ACTIVO', 'INACTIVO'))
);

-- 4. Citas
CREATE TABLE IF NOT EXISTS cita (
    cita_id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    paciente_id          BIGINT NOT NULL,
    medico_id            BIGINT NOT NULL,
    fecha_hora           TIMESTAMPTZ NOT NULL,
    fecha_llegada        TIMESTAMPTZ,
    estado               VARCHAR(20) NOT NULL DEFAULT 'PROGRAMADA',
    motivo_cancelacion   VARCHAR(255),
    fecha_creacion       TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion  TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
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
    CONSTRAINT ck_cita_estado
        CHECK (estado IN (
            'PROGRAMADA', 'CONFIRMADA', 'ATENDIDA',
            'CANCELADA', 'NO_ASISTIO'
        )),
    CONSTRAINT ck_cita_motivo_cancelacion
        CHECK (estado <> 'CANCELADA' OR motivo_cancelacion IS NOT NULL),
    CONSTRAINT ck_cita_fecha_llegada
        CHECK (fecha_llegada IS NULL OR estado IN ('CONFIRMADA', 'ATENDIDA'))
);

-- Evita reservar al mismo medico dos veces en el mismo instante.
CREATE UNIQUE INDEX IF NOT EXISTS uq_cita_medico_fecha_activa
    ON cita (medico_id, fecha_hora)
    WHERE estado IN ('PROGRAMADA', 'CONFIRMADA');

-- 5. Atenciones realizadas. Una cita puede generar como maximo una atencion.
CREATE TABLE IF NOT EXISTS atencion (
    atencion_id      BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    cita_id          BIGINT NOT NULL UNIQUE,
    inicio_atencion  TIMESTAMPTZ NOT NULL,
    fin_atencion     TIMESTAMPTZ,
    estado           VARCHAR(20) NOT NULL DEFAULT 'EN_CURSO',
    observacion      VARCHAR(1000),
    CONSTRAINT fk_atencion_cita
        FOREIGN KEY (cita_id)
        REFERENCES cita (cita_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT ck_atencion_estado
        CHECK (estado IN ('EN_CURSO', 'COMPLETADA', 'ANULADA')),
    CONSTRAINT ck_atencion_fechas
        CHECK (fin_atencion IS NULL OR fin_atencion >= inicio_atencion),
    CONSTRAINT ck_atencion_completada
        CHECK (estado <> 'COMPLETADA' OR fin_atencion IS NOT NULL)
);

-- 6. Registro clinico asociado a la atencion.
CREATE TABLE IF NOT EXISTS registro_clinico (
    registro_clinico_id  BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    atencion_id          BIGINT NOT NULL UNIQUE,
    motivo_consulta      VARCHAR(500),
    diagnostico          VARCHAR(1000),
    tratamiento          VARCHAR(1000),
    indicaciones         VARCHAR(1000),
    fecha_registro       TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_registro_clinico_atencion
        FOREIGN KEY (atencion_id)
        REFERENCES atencion (atencion_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
);

-- 7. Pagos mencionados en el caso de negocio.
CREATE TABLE IF NOT EXISTS pago (
    pago_id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    atencion_id      BIGINT NOT NULL,
    monto            NUMERIC(12, 2) NOT NULL,
    moneda           CHAR(3) NOT NULL DEFAULT 'BOB',
    metodo           VARCHAR(20) NOT NULL,
    estado           VARCHAR(20) NOT NULL DEFAULT 'PENDIENTE',
    fecha_pago       TIMESTAMPTZ,
    referencia       VARCHAR(100),
    fecha_registro   TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_pago_atencion
        FOREIGN KEY (atencion_id)
        REFERENCES atencion (atencion_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT ck_pago_monto
        CHECK (monto > 0),
    CONSTRAINT ck_pago_moneda
        CHECK (moneda ~ '^[A-Z]{3}$'),
    CONSTRAINT ck_pago_metodo
        CHECK (metodo IN ('EFECTIVO', 'TARJETA', 'TRANSFERENCIA', 'QR', 'OTRO')),
    CONSTRAINT ck_pago_estado
        CHECK (estado IN ('PENDIENTE', 'PAGADO', 'ANULADO', 'REEMBOLSADO')),
    CONSTRAINT ck_pago_fecha
        CHECK (estado <> 'PAGADO' OR fecha_pago IS NOT NULL)
);

-- 8. Metadatos de archivos clinicos privados almacenados en Amazon S3.
-- El archivo binario no se guarda en RDS; RDS conserva su ubicacion y relacion.
CREATE TABLE IF NOT EXISTS documento_s3 (
    documento_id     BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    paciente_id      BIGINT NOT NULL,
    atencion_id      BIGINT,
    categoria        VARCHAR(30) NOT NULL,
    nombre_archivo   VARCHAR(255) NOT NULL,
    s3_bucket        VARCHAR(63) NOT NULL,
    s3_object_key    VARCHAR(1024) NOT NULL,
    s3_etag          VARCHAR(128),
    tipo_mime        VARCHAR(100),
    visibilidad      VARCHAR(20) NOT NULL DEFAULT 'PRIVADO',
    fecha_carga      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
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
    CONSTRAINT uq_documento_s3
        UNIQUE (s3_bucket, s3_object_key),
    CONSTRAINT ck_documento_categoria
        CHECK (categoria IN (
            'LABORATORIO', 'RECETA', 'INFORME_MEDICO',
            'IMAGEN_MEDICA', 'REPORTE', 'OTRO'
        )),
    CONSTRAINT ck_documento_visibilidad
        CHECK (visibilidad IN ('PRIVADO', 'INTERNO'))
);

-- 9. Auditoria tecnica. Registra quien modifico cada registro y cuando,
-- sin duplicar diagnosticos, observaciones ni otros datos clinicos sensibles.
CREATE TABLE IF NOT EXISTS auditoria_evento (
    auditoria_id     BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tabla_afectada   VARCHAR(63) NOT NULL,
    registro_id      VARCHAR(100) NOT NULL,
    operacion        VARCHAR(10) NOT NULL,
    usuario_bd       VARCHAR(100) NOT NULL DEFAULT CURRENT_USER,
    fecha_evento     TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT ck_auditoria_operacion
        CHECK (operacion IN ('INSERT', 'UPDATE', 'DELETE'))
);

-- Indices para claves foraneas y consultas operativas.
CREATE INDEX IF NOT EXISTS ix_medico_especialidad
    ON medico (especialidad_id);

CREATE INDEX IF NOT EXISTS ix_cita_paciente_fecha
    ON cita (paciente_id, fecha_hora);

CREATE INDEX IF NOT EXISTS ix_cita_medico_fecha
    ON cita (medico_id, fecha_hora);

CREATE INDEX IF NOT EXISTS ix_cita_estado_fecha
    ON cita (estado, fecha_hora);

CREATE INDEX IF NOT EXISTS ix_atencion_inicio_estado
    ON atencion (inicio_atencion, estado);

CREATE INDEX IF NOT EXISTS ix_pago_atencion
    ON pago (atencion_id);

CREATE INDEX IF NOT EXISTS ix_documento_paciente
    ON documento_s3 (paciente_id);

CREATE INDEX IF NOT EXISTS ix_documento_atencion
    ON documento_s3 (atencion_id);

CREATE INDEX IF NOT EXISTS ix_auditoria_tabla_fecha
    ON auditoria_evento (tabla_afectada, fecha_evento DESC);

-- Mantiene fecha_actualizacion de CITA sin depender de la aplicacion.
CREATE OR REPLACE FUNCTION actualizar_fecha_modificacion()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.fecha_actualizacion := CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_cita_fecha_actualizacion ON cita;
CREATE TRIGGER trg_cita_fecha_actualizacion
BEFORE UPDATE ON cita
FOR EACH ROW
EXECUTE FUNCTION actualizar_fecha_modificacion();

-- Impide registrar una atencion para una cita cancelada o marcada como no asistida.
CREATE OR REPLACE FUNCTION validar_cita_para_atencion()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    estado_cita VARCHAR(20);
BEGIN
    SELECT estado
      INTO estado_cita
      FROM cita
     WHERE cita_id = NEW.cita_id
     FOR UPDATE;

    IF estado_cita IS NULL THEN
        RAISE EXCEPTION 'La cita % no existe', NEW.cita_id;
    END IF;

    IF estado_cita IN ('CANCELADA', 'NO_ASISTIO') THEN
        RAISE EXCEPTION 'La cita % no puede generar una atencion porque esta %',
            NEW.cita_id, estado_cita;
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_validar_cita_para_atencion ON atencion;
CREATE TRIGGER trg_validar_cita_para_atencion
BEFORE INSERT OR UPDATE OF cita_id ON atencion
FOR EACH ROW
EXECUTE FUNCTION validar_cita_para_atencion();

-- Cuando una atencion se completa, actualiza automaticamente la cita relacionada.
CREATE OR REPLACE FUNCTION sincronizar_cita_atendida()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.estado = 'COMPLETADA' THEN
        UPDATE cita
           SET estado = 'ATENDIDA'
         WHERE cita_id = NEW.cita_id
           AND estado <> 'ATENDIDA';
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_sincronizar_cita_atendida ON atencion;
CREATE TRIGGER trg_sincronizar_cita_atendida
AFTER INSERT OR UPDATE OF estado ON atencion
FOR EACH ROW
EXECUTE FUNCTION sincronizar_cita_atendida();

-- Evita asociar un archivo de S3 con un paciente distinto al de la atencion.
CREATE OR REPLACE FUNCTION validar_documento_s3_paciente()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    paciente_de_atencion BIGINT;
BEGIN
    IF NEW.atencion_id IS NULL THEN
        RETURN NEW;
    END IF;

    SELECT c.paciente_id
      INTO paciente_de_atencion
      FROM atencion AS a
      JOIN cita AS c ON c.cita_id = a.cita_id
     WHERE a.atencion_id = NEW.atencion_id;

    IF paciente_de_atencion IS NULL THEN
        RAISE EXCEPTION 'La atencion % no existe', NEW.atencion_id;
    END IF;

    IF paciente_de_atencion <> NEW.paciente_id THEN
        RAISE EXCEPTION
            'El documento no puede asociarse con un paciente distinto al de la atencion';
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_validar_documento_s3_paciente ON documento_s3;
CREATE TRIGGER trg_validar_documento_s3_paciente
BEFORE INSERT OR UPDATE OF paciente_id, atencion_id ON documento_s3
FOR EACH ROW
EXECUTE FUNCTION validar_documento_s3_paciente();

-- Funcion generica de auditoria. TG_ARGV[0] contiene la clave primaria.
CREATE OR REPLACE FUNCTION registrar_evento_auditoria()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    id_afectado TEXT;
BEGIN
    IF TG_OP = 'DELETE' THEN
        id_afectado := to_jsonb(OLD) ->> TG_ARGV[0];
    ELSE
        id_afectado := to_jsonb(NEW) ->> TG_ARGV[0];
    END IF;

    INSERT INTO auditoria_evento (
        tabla_afectada,
        registro_id,
        operacion,
        usuario_bd
    ) VALUES (
        TG_TABLE_NAME,
        id_afectado,
        TG_OP,
        CURRENT_USER
    );

    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_auditar_paciente ON paciente;
CREATE TRIGGER trg_auditar_paciente
AFTER INSERT OR UPDATE OR DELETE ON paciente
FOR EACH ROW EXECUTE FUNCTION registrar_evento_auditoria('paciente_id');

DROP TRIGGER IF EXISTS trg_auditar_cita ON cita;
CREATE TRIGGER trg_auditar_cita
AFTER INSERT OR UPDATE OR DELETE ON cita
FOR EACH ROW EXECUTE FUNCTION registrar_evento_auditoria('cita_id');

DROP TRIGGER IF EXISTS trg_auditar_atencion ON atencion;
CREATE TRIGGER trg_auditar_atencion
AFTER INSERT OR UPDATE OR DELETE ON atencion
FOR EACH ROW EXECUTE FUNCTION registrar_evento_auditoria('atencion_id');

DROP TRIGGER IF EXISTS trg_auditar_registro_clinico ON registro_clinico;
CREATE TRIGGER trg_auditar_registro_clinico
AFTER INSERT OR UPDATE OR DELETE ON registro_clinico
FOR EACH ROW EXECUTE FUNCTION registrar_evento_auditoria('registro_clinico_id');

DROP TRIGGER IF EXISTS trg_auditar_pago ON pago;
CREATE TRIGGER trg_auditar_pago
AFTER INSERT OR UPDATE OR DELETE ON pago
FOR EACH ROW EXECUTE FUNCTION registrar_evento_auditoria('pago_id');

DROP TRIGGER IF EXISTS trg_auditar_documento_s3 ON documento_s3;
CREATE TRIGGER trg_auditar_documento_s3
AFTER INSERT OR UPDATE OR DELETE ON documento_s3
FOR EACH ROW EXECUTE FUNCTION registrar_evento_auditoria('documento_id');

-- KPI 1: pacientes unicos atendidos por mes.
CREATE OR REPLACE VIEW kpi_pacientes_atendidos_mes AS
SELECT
    date_trunc('month', a.inicio_atencion)::date AS mes,
    COUNT(DISTINCT c.paciente_id) AS pacientes_atendidos
FROM atencion AS a
JOIN cita AS c ON c.cita_id = a.cita_id
WHERE a.estado = 'COMPLETADA'
GROUP BY date_trunc('month', a.inicio_atencion)::date;

-- KPI 2: porcentaje mensual de citas canceladas.
CREATE OR REPLACE VIEW kpi_citas_canceladas_mes AS
SELECT
    date_trunc('month', c.fecha_hora)::date AS mes,
    COUNT(*) AS total_citas,
    COUNT(*) FILTER (WHERE c.estado = 'CANCELADA') AS citas_canceladas,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE c.estado = 'CANCELADA')
        / NULLIF(COUNT(*), 0),
        2
    ) AS porcentaje_canceladas
FROM cita AS c
GROUP BY date_trunc('month', c.fecha_hora)::date;

-- KPI 3: atenciones completadas por especialidad y mes.
CREATE OR REPLACE VIEW kpi_atenciones_especialidad_mes AS
SELECT
    date_trunc('month', a.inicio_atencion)::date AS mes,
    e.especialidad_id,
    e.nombre AS especialidad,
    COUNT(*) AS total_atenciones
FROM atencion AS a
JOIN cita AS c ON c.cita_id = a.cita_id
JOIN medico AS m ON m.medico_id = c.medico_id
JOIN especialidad AS e ON e.especialidad_id = m.especialidad_id
WHERE a.estado = 'COMPLETADA'
GROUP BY
    date_trunc('month', a.inicio_atencion)::date,
    e.especialidad_id,
    e.nombre;

-- Metrica complementaria para el KR de tiempo de espera.
CREATE OR REPLACE VIEW kpi_tiempo_espera_mes AS
SELECT
    date_trunc('month', a.inicio_atencion)::date AS mes,
    ROUND(AVG(EXTRACT(EPOCH FROM (a.inicio_atencion - c.fecha_llegada)) / 60.0), 2)
        AS minutos_promedio_espera
FROM atencion AS a
JOIN cita AS c ON c.cita_id = a.cita_id
WHERE a.estado = 'COMPLETADA'
  AND c.fecha_llegada IS NOT NULL
  AND a.inicio_atencion >= c.fecha_llegada
GROUP BY date_trunc('month', a.inicio_atencion)::date;

-- Metrica complementaria para el KR de pacientes recurrentes.
-- Un paciente es recurrente en un mes cuando fue atendido ese mes y ya tenia
-- al menos una atencion completada en un mes anterior.
CREATE OR REPLACE VIEW kpi_pacientes_recurrentes_mes AS
WITH pacientes_por_mes AS (
    SELECT DISTINCT
        c.paciente_id,
        date_trunc('month', a.inicio_atencion)::date AS mes
    FROM atencion AS a
    JOIN cita AS c ON c.cita_id = a.cita_id
    WHERE a.estado = 'COMPLETADA'
)
SELECT
    actual.mes,
    COUNT(*) AS pacientes_atendidos,
    COUNT(*) FILTER (
        WHERE EXISTS (
            SELECT 1
            FROM pacientes_por_mes AS anterior
            WHERE anterior.paciente_id = actual.paciente_id
              AND anterior.mes < actual.mes
        )
    ) AS pacientes_recurrentes,
    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE EXISTS (
                SELECT 1
                FROM pacientes_por_mes AS anterior
                WHERE anterior.paciente_id = actual.paciente_id
                  AND anterior.mes < actual.mes
            )
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS porcentaje_recurrentes
FROM pacientes_por_mes AS actual
GROUP BY actual.mes;

COMMIT;

-- Relaciones principales:
-- especialidad 1 ---- N medico
-- paciente     1 ---- N cita
-- medico       1 ---- N cita
-- cita         1 ---- 0..1 atencion
-- atencion     1 ---- 0..1 registro_clinico
-- atencion     1 ---- N pago
-- paciente     1 ---- N documento_s3
-- atencion     1 ---- N documento_s3 (opcional)
--
-- AWS IAM no se modela como tabla: los usuarios, roles y politicas se administran
-- en el servicio AWS IAM. El sitio web publico de S3 tampoco comparte bucket ni
-- permisos con los documentos clinicos privados registrados en documento_s3.
