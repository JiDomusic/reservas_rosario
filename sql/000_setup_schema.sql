-- ============================================================================
-- 000_setup_schema.sql
-- Reserva Template - Database Schema Setup
-- ============================================================================
-- Creates all tables for the generic reservation system.
-- Run this file first against a fresh Supabase/PostgreSQL database.
-- ============================================================================

-- Enable UUID generation
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";


-- ============================================================================
-- 1. reservas - Core reservation table
-- ============================================================================
CREATE TABLE IF NOT EXISTS reservas (
    id                    UUID          PRIMARY KEY DEFAULT uuid_generate_v4(),
    fecha                 DATE          NOT NULL,
    hora                  TIME          NOT NULL,
    personas              INTEGER       NOT NULL,
    nombre                VARCHAR(100)  NOT NULL,
    telefono              VARCHAR(20)   NOT NULL,
    email                 VARCHAR(100),
    comentarios           TEXT,
    observaciones_admin   TEXT,
    estado                VARCHAR(20)   DEFAULT 'confirmada'
                                        CHECK (estado IN (
                                            'confirmada',
                                            'completada',
                                            'cancelada',
                                            'no_show',
                                            'en_mesa'
                                        )),
    codigo_confirmacion   VARCHAR(10)   UNIQUE,
    area                  VARCHAR(50),
    created_at            TIMESTAMPTZ   DEFAULT NOW(),
    actualizado_en        TIMESTAMPTZ   DEFAULT NOW()
);

COMMENT ON TABLE  reservas IS 'Core reservation records';
COMMENT ON COLUMN reservas.estado IS 'confirmada | completada | cancelada | no_show | en_mesa';
COMMENT ON COLUMN reservas.codigo_confirmacion IS 'Unique 6-char alphanumeric code shown to the customer';


-- ============================================================================
-- 2. restaurant_config - Key-value configuration store
-- ============================================================================
CREATE TABLE IF NOT EXISTS restaurant_config (
    id          SERIAL       PRIMARY KEY,
    clave       VARCHAR(100) UNIQUE NOT NULL,
    valor       TEXT         DEFAULT '',
    descripcion TEXT,
    created_at  TIMESTAMPTZ  DEFAULT NOW()
);

COMMENT ON TABLE restaurant_config IS 'Key-value pairs for all restaurant settings';


-- ============================================================================
-- 3. areas - Restaurant zones / floors
-- ============================================================================
CREATE TABLE IF NOT EXISTS areas (
    id                 UUID          DEFAULT uuid_generate_v4() PRIMARY KEY,
    nombre             VARCHAR(100)  NOT NULL UNIQUE,
    nombre_display     VARCHAR(100)  NOT NULL,
    capacidad_real     INTEGER       NOT NULL,
    capacidad_frontend INTEGER       NOT NULL,
    hora_inicio        TIME,
    hora_fin           TIME,
    activo             BOOLEAN       DEFAULT TRUE,
    created_at         TIMESTAMPTZ   DEFAULT NOW()
);

COMMENT ON TABLE areas IS 'Physical zones of the restaurant (e.g. patio, salon, terraza)';


-- ============================================================================
-- 4. mesas - Physical tables per area
-- ============================================================================
CREATE TABLE IF NOT EXISTS mesas (
    id             UUID          DEFAULT uuid_generate_v4() PRIMARY KEY,
    nombre         VARCHAR(50)   NOT NULL,
    area           VARCHAR(50)   NOT NULL,
    min_capacidad  INTEGER       NOT NULL,
    max_capacidad  INTEGER       NOT NULL,
    cantidad       INTEGER       DEFAULT 1,
    es_vip         BOOLEAN       DEFAULT FALSE,
    bloqueable     BOOLEAN       DEFAULT FALSE,
    activo         BOOLEAN       DEFAULT TRUE,
    orden          INTEGER       DEFAULT 0,
    created_at     TIMESTAMPTZ   DEFAULT NOW()
);

COMMENT ON TABLE  mesas IS 'Individual tables within each area';
COMMENT ON COLUMN mesas.cantidad IS 'Number of identical tables with this configuration';
COMMENT ON COLUMN mesas.orden IS 'Display order in the admin UI';


-- ============================================================================
-- 5. horarios - Operating hours per day of week and area
-- ============================================================================
CREATE TABLE IF NOT EXISTS horarios (
    id                 UUID        DEFAULT uuid_generate_v4() PRIMARY KEY,
    dia_semana         INTEGER     NOT NULL,  -- 0 = Domingo, 1 = Lunes ... 6 = Sabado
    area               VARCHAR(50) NOT NULL,
    hora_inicio        TIME        NOT NULL,
    hora_fin           TIME        NOT NULL,
    intervalo_minutos  INTEGER     DEFAULT 30,
    activo             BOOLEAN     DEFAULT TRUE,
    created_at         TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE  horarios IS 'Weekly schedule per area (which hours are bookable)';
COMMENT ON COLUMN horarios.dia_semana IS '0 = Domingo, 1 = Lunes, 2 = Martes ... 6 = Sabado';
COMMENT ON COLUMN horarios.intervalo_minutos IS 'Time-slot interval in minutes (default 30)';


-- ============================================================================
-- 6. bloqueos - Admin day/hour blocks
-- ============================================================================
CREATE TABLE IF NOT EXISTS bloqueos (
    id           UUID          DEFAULT uuid_generate_v4() PRIMARY KEY,
    fecha        DATE          NOT NULL,
    hora         TIME,
    bloquea_dia  BOOLEAN       DEFAULT FALSE,
    motivo       TEXT,
    created_by   VARCHAR(100),
    created_at   TIMESTAMPTZ   DEFAULT NOW()
);

COMMENT ON TABLE  bloqueos IS 'Manual blocks set by admin (full day or specific hour)';
COMMENT ON COLUMN bloqueos.bloquea_dia IS 'TRUE = entire day blocked; FALSE = only the specified hora';


-- ============================================================================
-- 7. estadisticas_diarias - Daily aggregated statistics
-- ============================================================================
CREATE TABLE IF NOT EXISTS estadisticas_diarias (
    id              SERIAL       PRIMARY KEY,
    fecha           DATE         UNIQUE NOT NULL,
    total_reservas  INTEGER      DEFAULT 0,
    total_personas  INTEGER      DEFAULT 0,
    completadas     INTEGER      DEFAULT 0,
    canceladas      INTEGER      DEFAULT 0,
    no_shows        INTEGER      DEFAULT 0,
    created_at      TIMESTAMPTZ  DEFAULT NOW()
);

COMMENT ON TABLE estadisticas_diarias IS 'Pre-computed daily stats for the dashboard';


-- ============================================================================
-- 8. logs - Audit log
-- ============================================================================
CREATE TABLE IF NOT EXISTS logs (
    id         SERIAL       PRIMARY KEY,
    accion     VARCHAR(100),
    detalle    TEXT,
    usuario    VARCHAR(100),
    created_at TIMESTAMPTZ  DEFAULT NOW()
);

COMMENT ON TABLE logs IS 'Audit trail of admin and system actions';


-- ============================================================================
-- 9. subscriptions - Monthly payment tracking
-- ============================================================================
CREATE TABLE IF NOT EXISTS subscriptions (
    id                 SERIAL        PRIMARY KEY,
    mes                INTEGER       NOT NULL,
    anio               INTEGER       NOT NULL,
    fecha_vencimiento  TIMESTAMPTZ,
    fecha_pago         TIMESTAMPTZ,
    pagado             BOOLEAN       DEFAULT FALSE,
    monto              NUMERIC(10,2) DEFAULT 0,
    notas              TEXT,
    created_at         TIMESTAMPTZ   DEFAULT NOW(),
    updated_at         TIMESTAMPTZ   DEFAULT NOW(),
    UNIQUE (mes, anio)
);

COMMENT ON TABLE subscriptions IS 'Tracks monthly subscription payments';


-- ============================================================================
-- 10. payment_codes - One-time payment codes
-- ============================================================================
CREATE TABLE IF NOT EXISTS payment_codes (
    id             SERIAL        PRIMARY KEY,
    codigo         VARCHAR(20)   UNIQUE NOT NULL,
    mes            INTEGER       NOT NULL,
    anio           INTEGER       NOT NULL,
    monto          NUMERIC(10,2) DEFAULT 0,
    usado          BOOLEAN       DEFAULT FALSE,
    fecha_creacion TIMESTAMPTZ   DEFAULT NOW(),
    fecha_uso      TIMESTAMPTZ,
    notas          TEXT
);

COMMENT ON TABLE payment_codes IS 'Disposable codes that unlock a month of service when redeemed';


-- ============================================================================
-- Indexes
-- ============================================================================

-- Fast look-ups for the reservation calendar and status filters
CREATE INDEX IF NOT EXISTS idx_reservas_fecha_hora_estado
    ON reservas (fecha, hora, estado);

-- Block look-ups by date
CREATE INDEX IF NOT EXISTS idx_bloqueos_fecha
    ON bloqueos (fecha);

-- Schedule look-ups by day of week
CREATE INDEX IF NOT EXISTS idx_horarios_dia_semana
    ON horarios (dia_semana);
