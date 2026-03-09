-- =====================================================
-- SISTEMA DE RESERVAS - SUPABASE SETUP
-- Correr este SQL en: Supabase Dashboard → SQL Editor
-- =====================================================

-- ─── 1. TABLA TENANTS (un restaurante por fila) ───
CREATE TABLE tenants (
  id TEXT PRIMARY KEY,                          -- ej: "jj_rosario"
  nombre_restaurante TEXT NOT NULL DEFAULT '',
  subtitulo TEXT DEFAULT '',
  slogan TEXT DEFAULT '',
  direccion TEXT DEFAULT '',
  ciudad TEXT DEFAULT '',
  provincia TEXT DEFAULT '',
  pais TEXT DEFAULT '',
  google_maps_query TEXT DEFAULT '',
  email_contacto TEXT DEFAULT '',
  telefono_contacto TEXT DEFAULT '',
  whatsapp_numero TEXT DEFAULT '',
  codigo_pais_telefono TEXT DEFAULT '54',
  sitio_web TEXT DEFAULT '',

  -- Imágenes
  logo_color_url TEXT,
  logo_blanco_url TEXT,
  fondo_url TEXT,

  -- Colores (hex string: "#FF0000")
  color_primario TEXT DEFAULT '#194485',
  color_secundario TEXT DEFAULT '#154080',
  color_terciario TEXT DEFAULT '#1B427C',
  color_acento TEXT DEFAULT '#FF0000',

  -- Reglas operativas
  dia_cerrado INT DEFAULT 1,                    -- 0=ninguno, 1=Lun, 7=Dom
  min_personas INT DEFAULT 2,
  max_personas INT DEFAULT 15,
  anticipo_almuerzo_horas INT DEFAULT 2,
  anticipo_regular_horas INT DEFAULT 24,
  minutos_liberacion_auto INT DEFAULT 15,
  dias_adelanto_maximo INT DEFAULT 60,
  ventana_confirmacion_horas INT DEFAULT 2,
  recordatorio_horas_antes INT DEFAULT 24,

  -- Feature flags
  usa_sistema_mesas BOOLEAN DEFAULT false,
  usa_areas_multiples BOOLEAN DEFAULT false,
  capacidad_compartida BOOLEAN DEFAULT false,
  optimizacion_estricta_mesas BOOLEAN DEFAULT false,
  onboarding_completed BOOLEAN DEFAULT false,

  -- Banner de cierre temporal
  banner_activo BOOLEAN DEFAULT false,
  banner_texto TEXT DEFAULT 'Nos tomamos un descanso. Volvemos pronto.',
  banner_fecha TEXT,

  -- Suscripción
  subscription_start_date TEXT,
  subscription_due_day INT DEFAULT 18,

  -- Auth: el user_id del admin de este restaurante
  admin_user_id UUID REFERENCES auth.users(id),

  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- ─── 2. TABLA AREAS ───
CREATE TABLE areas (
  id TEXT NOT NULL,
  tenant_id TEXT NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  nombre TEXT NOT NULL,                         -- "planta_baja"
  nombre_display TEXT NOT NULL DEFAULT '',       -- "Planta Baja"
  capacidad_real INT DEFAULT 0,
  capacidad_frontend INT DEFAULT 0,
  hora_inicio TEXT,                              -- "09:00"
  hora_fin TEXT,                                 -- "15:00"
  activo BOOLEAN DEFAULT true,
  PRIMARY KEY (tenant_id, id)
);

-- ─── 3. TABLA MESAS ───
CREATE TABLE tables_def (
  id TEXT NOT NULL,
  tenant_id TEXT NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  nombre TEXT NOT NULL,
  area TEXT NOT NULL,                            -- FK lógico a areas.nombre
  min_capacidad INT DEFAULT 2,
  max_capacidad INT DEFAULT 4,
  cantidad INT DEFAULT 1,
  es_vip BOOLEAN DEFAULT false,
  bloqueable BOOLEAN DEFAULT false,
  activo BOOLEAN DEFAULT true,
  pos_x DOUBLE PRECISION DEFAULT 0,
  pos_y DOUBLE PRECISION DEFAULT 0,
  width DOUBLE PRECISION DEFAULT 80,
  height DOUBLE PRECISION DEFAULT 80,
  shape TEXT DEFAULT 'rect',                     -- 'rect', 'circle', 'square'
  PRIMARY KEY (tenant_id, id)
);

-- ─── 4. TABLA HORARIOS ───
CREATE TABLE operating_hours (
  id TEXT NOT NULL,
  tenant_id TEXT NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  dia_semana INT NOT NULL,                       -- 0=Dom, 1=Lun, 6=Sáb
  area TEXT NOT NULL,
  hora_inicio TEXT NOT NULL,                     -- "20:00"
  hora_fin TEXT NOT NULL,                        -- "23:30"
  intervalo_minutos INT DEFAULT 30,
  activo BOOLEAN DEFAULT true,
  PRIMARY KEY (tenant_id, id)
);

-- ─── 5. TABLA RESERVAS ───
CREATE TABLE reservations (
  id TEXT NOT NULL,
  tenant_id TEXT NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  fecha TEXT NOT NULL,                           -- "2026-02-25"
  hora TEXT NOT NULL,                            -- "21:00"
  personas INT NOT NULL,
  nombre TEXT NOT NULL,
  telefono TEXT NOT NULL,
  codigo_confirmacion TEXT,
  email TEXT,
  comentarios TEXT,
  estado TEXT NOT NULL DEFAULT 'pendiente_confirmacion',
  area TEXT NOT NULL,
  confirmado_cliente BOOLEAN DEFAULT false,
  confirmado_at TEXT,
  recordatorio_enviado BOOLEAN DEFAULT false,
  recordatorio_enviado_at TEXT,
  created_at TEXT DEFAULT to_char(now(), 'YYYY-MM-DD"T"HH24:MI:SS'),
  PRIMARY KEY (tenant_id, id)
);

-- Índices para queries frecuentes
CREATE INDEX idx_reservations_fecha ON reservations(tenant_id, fecha);
CREATE INDEX idx_reservations_estado ON reservations(tenant_id, estado);
CREATE INDEX idx_reservations_codigo ON reservations(tenant_id, codigo_confirmacion);

-- ─── 6. TABLA LISTA DE ESPERA ───
CREATE TABLE waitlist (
  id TEXT NOT NULL,
  tenant_id TEXT NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  fecha TEXT NOT NULL,
  hora TEXT NOT NULL,
  personas INT NOT NULL,
  nombre TEXT NOT NULL,
  telefono TEXT NOT NULL,
  email TEXT,
  comentarios TEXT,
  estado TEXT NOT NULL DEFAULT 'esperando',      -- 'esperando', 'removido'
  notificado BOOLEAN DEFAULT false,
  notificado_at TEXT,
  created_at TEXT DEFAULT to_char(now(), 'YYYY-MM-DD"T"HH24:MI:SS'),
  PRIMARY KEY (tenant_id, id)
);

-- ─── 7. TABLA BLOQUEOS ───
CREATE TABLE blocks (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  tenant_id TEXT NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  fecha TEXT NOT NULL,                           -- "2026-02-25"
  bloquea_dia BOOLEAN DEFAULT false,
  hora TEXT,                                     -- "21:00" (null si bloquea_dia=true)
  motivo TEXT,
  created_by TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_blocks_fecha ON blocks(tenant_id, fecha);

-- ─── 8. TABLA BLOQUEOS DE MESAS ───
CREATE TABLE table_blocks (
  tenant_id TEXT NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  table_id TEXT NOT NULL,
  bloqueada BOOLEAN DEFAULT false,
  PRIMARY KEY (tenant_id, table_id)
);

-- ─── 9. POSICIONES DEL MAPA ───
CREATE TABLE map_positions (
  tenant_id TEXT NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  map_id TEXT NOT NULL,                          -- "mesa_4p_0", "mesa_4p_1"
  pos_x DOUBLE PRECISION DEFAULT 0,
  pos_y DOUBLE PRECISION DEFAULT 0,
  PRIMARY KEY (tenant_id, map_id)
);

-- ═════════════════════════════════════════════════════
-- ROW LEVEL SECURITY (cada restaurante ve solo sus datos)
-- ═════════════════════════════════════════════════════

ALTER TABLE tenants ENABLE ROW LEVEL SECURITY;
ALTER TABLE areas ENABLE ROW LEVEL SECURITY;
ALTER TABLE tables_def ENABLE ROW LEVEL SECURITY;
ALTER TABLE operating_hours ENABLE ROW LEVEL SECURITY;
ALTER TABLE reservations ENABLE ROW LEVEL SECURITY;
ALTER TABLE waitlist ENABLE ROW LEVEL SECURITY;
ALTER TABLE blocks ENABLE ROW LEVEL SECURITY;
ALTER TABLE table_blocks ENABLE ROW LEVEL SECURITY;
ALTER TABLE map_positions ENABLE ROW LEVEL SECURITY;

-- Policy: el admin autenticado solo ve su tenant
-- (el admin_user_id en tenants vincula usuario → restaurante)

-- Tenants: el admin ve solo su restaurante
CREATE POLICY "Admin ve su tenant"
  ON tenants FOR ALL
  USING (admin_user_id = auth.uid());

-- Para las demás tablas: el admin ve datos de su tenant
-- Se busca el tenant_id del usuario logueado
CREATE OR REPLACE FUNCTION get_my_tenant_id()
RETURNS TEXT
LANGUAGE SQL
STABLE
SECURITY DEFINER
AS $$
  SELECT id FROM tenants WHERE admin_user_id = auth.uid() LIMIT 1;
$$;

CREATE POLICY "Admin ve sus areas"
  ON areas FOR ALL
  USING (tenant_id = get_my_tenant_id());

CREATE POLICY "Admin ve sus mesas"
  ON tables_def FOR ALL
  USING (tenant_id = get_my_tenant_id());

CREATE POLICY "Admin ve sus horarios"
  ON operating_hours FOR ALL
  USING (tenant_id = get_my_tenant_id());

CREATE POLICY "Admin ve sus reservas"
  ON reservations FOR ALL
  USING (tenant_id = get_my_tenant_id());

CREATE POLICY "Admin ve su waitlist"
  ON waitlist FOR ALL
  USING (tenant_id = get_my_tenant_id());

CREATE POLICY "Admin ve sus bloqueos"
  ON blocks FOR ALL
  USING (tenant_id = get_my_tenant_id());

CREATE POLICY "Admin ve sus table_blocks"
  ON table_blocks FOR ALL
  USING (tenant_id = get_my_tenant_id());

CREATE POLICY "Admin ve sus map_positions"
  ON map_positions FOR ALL
  USING (tenant_id = get_my_tenant_id());

-- Super admin: cualquier admin autenticado puede crear tenants
CREATE POLICY "Admin crea tenants"
  ON tenants FOR INSERT
  WITH CHECK (auth.role() = 'authenticated');

-- ═════════════════════════════════════════════════════
-- ACCESO PÚBLICO (para clientes que hacen reservas sin login)
-- ═════════════════════════════════════════════════════

-- Los clientes (anon) pueden leer la config del restaurante por tenant_id
CREATE POLICY "Público lee tenant por id"
  ON tenants FOR SELECT
  USING (true);

-- Los clientes pueden leer áreas, mesas y horarios (para el flujo de reserva)
CREATE POLICY "Público lee areas"
  ON areas FOR SELECT
  USING (true);

CREATE POLICY "Público lee mesas"
  ON tables_def FOR SELECT
  USING (true);

CREATE POLICY "Público lee horarios"
  ON operating_hours FOR SELECT
  USING (true);

-- Los clientes pueden CREAR reservas y leer sus propias reservas por código
CREATE POLICY "Público crea reservas"
  ON reservations FOR INSERT
  WITH CHECK (true);

CREATE POLICY "Público lee reservas"
  ON reservations FOR SELECT
  USING (true);

-- Los clientes pueden crear waitlist
CREATE POLICY "Público crea waitlist"
  ON waitlist FOR INSERT
  WITH CHECK (true);

-- Público lee bloqueos (para saber qué horarios están bloqueados)
CREATE POLICY "Público lee bloqueos"
  ON blocks FOR SELECT
  USING (true);

-- ═════════════════════════════════════════════════════
-- STORAGE BUCKET (para logos y fotos)
-- ═════════════════════════════════════════════════════

INSERT INTO storage.buckets (id, name, public)
VALUES ('restaurant-images', 'restaurant-images', true);

-- Cualquiera puede ver las imágenes (son públicas)
CREATE POLICY "Imágenes públicas"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'restaurant-images');

-- Solo admin autenticado sube imágenes
CREATE POLICY "Admin sube imágenes"
  ON storage.objects FOR INSERT
  WITH CHECK (bucket_id = 'restaurant-images' AND auth.role() = 'authenticated');

CREATE POLICY "Admin borra imágenes"
  ON storage.objects FOR DELETE
  USING (bucket_id = 'restaurant-images' AND auth.role() = 'authenticated');

-- ═════════════════════════════════════════════════════
-- TRIGGER: actualizar updated_at en tenants
-- ═════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tenants_updated_at
  BEFORE UPDATE ON tenants
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();
