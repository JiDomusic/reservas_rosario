-- ============================================================================
-- 004_trial_period.sql
-- Agrega sistema de período de prueba (15 días) por restaurante
-- ============================================================================

-- Columna: fecha de fin del trial (default = created_at + 15 días)
ALTER TABLE tenants
  ADD COLUMN IF NOT EXISTS trial_end_date TIMESTAMPTZ;

-- Columna: si ya se extendió el trial (solo una vez)
ALTER TABLE tenants
  ADD COLUMN IF NOT EXISTS trial_extended BOOLEAN DEFAULT FALSE;

-- Setear trial_end_date para tenants existentes que no lo tengan
UPDATE tenants
  SET trial_end_date = created_at + INTERVAL '15 days'
  WHERE trial_end_date IS NULL;

-- Default para nuevos tenants
ALTER TABLE tenants
  ALTER COLUMN trial_end_date SET DEFAULT (NOW() + INTERVAL '15 days');

COMMENT ON COLUMN tenants.trial_end_date IS 'Fecha de fin del período de prueba';
COMMENT ON COLUMN tenants.trial_extended IS 'TRUE si ya se usó la extensión gratuita de 15 días';
