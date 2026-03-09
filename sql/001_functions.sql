-- ============================================================================
-- 001_functions.sql
-- Reserva Template - PostgreSQL Functions
-- ============================================================================
-- Depends on: 000_setup_schema.sql (tables must exist first)
-- ============================================================================


-- ============================================================================
-- generar_codigo_confirmacion()
-- ----------------------------------------------------------------------------
-- Generates a unique 6-character uppercase alphanumeric confirmation code.
-- Keeps trying until it finds one that does not already exist in `reservas`.
-- Usage:  SELECT generar_codigo_confirmacion();
-- ============================================================================
CREATE OR REPLACE FUNCTION generar_codigo_confirmacion()
RETURNS VARCHAR(6)
LANGUAGE plpgsql
AS $$
DECLARE
    caracteres  CONSTANT TEXT := 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    codigo      VARCHAR(6);
    existe      BOOLEAN;
    intentos    INTEGER := 0;
    max_intentos CONSTANT INTEGER := 100;
BEGIN
    LOOP
        -- Build a random 6-char code
        codigo := '';
        FOR i IN 1..6 LOOP
            codigo := codigo || substr(caracteres, floor(random() * length(caracteres) + 1)::int, 1);
        END LOOP;

        -- Check uniqueness against the reservas table
        SELECT EXISTS (
            SELECT 1 FROM reservas WHERE codigo_confirmacion = codigo
        ) INTO existe;

        EXIT WHEN NOT existe;

        intentos := intentos + 1;
        IF intentos >= max_intentos THEN
            RAISE EXCEPTION 'No se pudo generar un codigo unico tras % intentos', max_intentos;
        END IF;
    END LOOP;

    RETURN codigo;
END;
$$;

COMMENT ON FUNCTION generar_codigo_confirmacion()
    IS 'Returns a unique 6-char alphanumeric code not yet present in reservas.codigo_confirmacion';


-- ============================================================================
-- verificar_capacidad_disponible(p_fecha, p_hora, p_personas)
-- ----------------------------------------------------------------------------
-- Checks whether the restaurant can accept a new reservation for the given
-- date, time, and party size.
--
-- Logic:
--   1. Look up all active areas (or the single default area).
--   2. For each area, sum the frontend capacity from `areas`.
--   3. Subtract the personas already reserved at (p_fecha, p_hora) in that area
--      where estado NOT IN ('cancelada').
--   4. If any area has enough remaining capacity, return TRUE.
--
-- Returns TRUE  if the reservation can be accepted.
-- Returns FALSE if there is not enough capacity.
--
-- Usage:  SELECT verificar_capacidad_disponible('2025-06-15', '20:30', 4);
-- ============================================================================
CREATE OR REPLACE FUNCTION verificar_capacidad_disponible(
    p_fecha    DATE,
    p_hora     TIME,
    p_personas INTEGER
)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
DECLARE
    rec              RECORD;
    personas_actual  INTEGER;
    capacidad_total  INTEGER;
    disponible       BOOLEAN := FALSE;
BEGIN
    -- Iterate over every active area
    FOR rec IN
        SELECT nombre, capacidad_frontend
        FROM areas
        WHERE activo = TRUE
    LOOP
        -- Count how many personas are already booked in this area/slot
        SELECT COALESCE(SUM(personas), 0)
        INTO personas_actual
        FROM reservas
        WHERE fecha = p_fecha
          AND hora  = p_hora
          AND (area = rec.nombre OR area IS NULL)
          AND estado NOT IN ('cancelada');

        capacidad_total := rec.capacidad_frontend;

        IF (capacidad_total - personas_actual) >= p_personas THEN
            disponible := TRUE;
            EXIT;  -- At least one area can accommodate; no need to check more
        END IF;
    END LOOP;

    -- If no areas are configured yet, fall back to a simple global check
    -- using restaurant_config.max_personas as a ceiling per slot.
    IF NOT FOUND THEN
        SELECT COALESCE(SUM(personas), 0)
        INTO personas_actual
        FROM reservas
        WHERE fecha = p_fecha
          AND hora  = p_hora
          AND estado NOT IN ('cancelada');

        SELECT COALESCE(valor::INTEGER, 15)
        INTO capacidad_total
        FROM restaurant_config
        WHERE clave = 'max_personas';

        -- Default to 15 if not configured
        IF capacidad_total IS NULL THEN
            capacidad_total := 15;
        END IF;

        disponible := (capacidad_total - personas_actual) >= p_personas;
    END IF;

    RETURN disponible;
END;
$$;

COMMENT ON FUNCTION verificar_capacidad_disponible(DATE, TIME, INTEGER)
    IS 'Returns TRUE if the restaurant can seat p_personas at (p_fecha, p_hora)';
