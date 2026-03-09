-- ============================================================================
-- 002_seed_config.sql
-- Reserva Template - Default Configuration Seed
-- ============================================================================
-- Populates `restaurant_config` with all required keys and their defaults.
-- Safe to re-run: uses ON CONFLICT (clave) DO NOTHING so existing values
-- are never overwritten.
--
-- Depends on: 000_setup_schema.sql
-- ============================================================================

INSERT INTO restaurant_config (clave, valor, descripcion) VALUES

-- -------------------------------------------------------------------------
-- Branding & identity
-- -------------------------------------------------------------------------
('nombre_restaurante',   '',        'Nombre del restaurante'),
('subtitulo',            '',        'Subtitulo o tagline corto'),
('slogan',               '',        'Slogan promocional'),

-- -------------------------------------------------------------------------
-- Location
-- -------------------------------------------------------------------------
('direccion',            '',        'Direccion fisica del restaurante'),
('ciudad',               '',        'Ciudad'),
('provincia',            '',        'Provincia o estado'),
('pais',                 '',        'Pais'),
('google_maps_query',    '',        'Query para embeber Google Maps'),

-- -------------------------------------------------------------------------
-- Contact
-- -------------------------------------------------------------------------
('email_contacto',       '',        'Email principal de contacto'),
('whatsapp_numero',      '',        'Numero de WhatsApp con codigo de pais'),
('telefono_contacto',    '',        'Telefono de contacto'),
('codigo_pais_telefono', '54',      'Codigo de pais para telefonos (sin +)'),

-- -------------------------------------------------------------------------
-- Web
-- -------------------------------------------------------------------------
('sitio_web',            '',        'URL del sitio web del restaurante'),

-- -------------------------------------------------------------------------
-- Assets / images
-- -------------------------------------------------------------------------
('logo_color_url',       '',        'URL del logo a color'),
('logo_blanco_url',      '',        'URL del logo en blanco'),
('fondo_url',            '',        'URL de la imagen de fondo principal'),

-- -------------------------------------------------------------------------
-- Theme colors
-- -------------------------------------------------------------------------
('color_primario',       '#194485', 'Color primario de la marca (hex)'),
('color_secundario',     '#154080', 'Color secundario (hex)'),
('color_terciario',      '#1B427C', 'Color terciario (hex)'),
('color_acento',         '#FF0000', 'Color de acento / CTA (hex)'),

-- -------------------------------------------------------------------------
-- Reservation rules
-- -------------------------------------------------------------------------
('dia_cerrado',              '1',     'Dia de la semana cerrado (0=Dom..6=Sab). 1=Lunes por defecto'),
('min_personas',             '2',     'Minimo de personas por reserva'),
('max_personas',             '15',    'Maximo de personas por reserva'),
('anticipo_almuerzo_horas',  '2',     'Horas de anticipacion minima para reservas de almuerzo'),
('anticipo_regular_horas',   '24',    'Horas de anticipacion minima para reservas regulares'),
('minutos_liberacion_auto',  '15',    'Minutos tras la hora para liberar reservas no confirmadas'),
('dias_adelanto_maximo',     '60',    'Cuantos dias en el futuro se puede reservar'),

-- -------------------------------------------------------------------------
-- Admin
-- -------------------------------------------------------------------------
('admin_emails',         '[]',     'Lista JSON de emails con acceso admin'),
('super_admin_emails',   '[]',     'Lista JSON de emails con acceso super-admin'),

-- -------------------------------------------------------------------------
-- Feature flags
-- -------------------------------------------------------------------------
('usa_sistema_mesas',    'false',  'Habilitar asignacion de mesas fisicas'),
('usa_areas_multiples',  'false',  'Habilitar multiples areas (salon, terraza, etc.)'),
('capacidad_compartida', 'false',  'Capacidad compartida entre areas'),

-- -------------------------------------------------------------------------
-- Onboarding
-- -------------------------------------------------------------------------
('onboarding_completado', 'false', 'Se completo el wizard de configuracion inicial'),

-- -------------------------------------------------------------------------
-- Subscription
-- -------------------------------------------------------------------------
('subscription_start_date', '',    'Fecha de inicio de la suscripcion (ISO 8601)'),
('subscription_due_day',    '18',  'Dia del mes en que vence el pago'),

-- -------------------------------------------------------------------------
-- Banner
-- -------------------------------------------------------------------------
('banner_activo',        'false',  'Mostrar banner informativo en el frontend'),
('banner_texto',         '',       'Texto del banner'),
('banner_fecha',         '',       'Fecha asociada al banner (ISO 8601)'),

-- -------------------------------------------------------------------------
-- VIP
-- -------------------------------------------------------------------------
('mesa_vip_bloqueada',   'false',  'Bloquear mesas VIP para asignacion manual')

ON CONFLICT (clave) DO NOTHING;
