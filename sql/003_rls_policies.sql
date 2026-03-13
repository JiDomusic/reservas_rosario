-- ============================================================================
-- 003_rls_policies.sql
-- Row Level Security policies for multitenant reservation system
-- ============================================================================
-- Run this in Supabase SQL Editor
-- ============================================================================

-- Enable RLS on all tables
ALTER TABLE tenants ENABLE ROW LEVEL SECURITY;
ALTER TABLE areas ENABLE ROW LEVEL SECURITY;
ALTER TABLE tables_def ENABLE ROW LEVEL SECURITY;
ALTER TABLE operating_hours ENABLE ROW LEVEL SECURITY;
ALTER TABLE reservations ENABLE ROW LEVEL SECURITY;
ALTER TABLE blocks ENABLE ROW LEVEL SECURITY;
ALTER TABLE table_blocks ENABLE ROW LEVEL SECURITY;
ALTER TABLE map_positions ENABLE ROW LEVEL SECURITY;
ALTER TABLE waitlist ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- Drop existing policies (clean slate)
-- ============================================================================
DROP POLICY IF EXISTS "tenant_select" ON tenants;
DROP POLICY IF EXISTS "tenant_update" ON tenants;
DROP POLICY IF EXISTS "public_select" ON tenants;
DROP POLICY IF EXISTS "tenant_select" ON areas;
DROP POLICY IF EXISTS "tenant_insert" ON areas;
DROP POLICY IF EXISTS "tenant_delete" ON areas;
DROP POLICY IF EXISTS "public_select" ON areas;
DROP POLICY IF EXISTS "tenant_select" ON tables_def;
DROP POLICY IF EXISTS "tenant_insert" ON tables_def;
DROP POLICY IF EXISTS "tenant_delete" ON tables_def;
DROP POLICY IF EXISTS "public_select" ON tables_def;
DROP POLICY IF EXISTS "tenant_select" ON operating_hours;
DROP POLICY IF EXISTS "tenant_insert" ON operating_hours;
DROP POLICY IF EXISTS "tenant_delete" ON operating_hours;
DROP POLICY IF EXISTS "public_select" ON operating_hours;
DROP POLICY IF EXISTS "tenant_select" ON reservations;
DROP POLICY IF EXISTS "tenant_insert" ON reservations;
DROP POLICY IF EXISTS "tenant_update" ON reservations;
DROP POLICY IF EXISTS "tenant_delete" ON reservations;
DROP POLICY IF EXISTS "public_select" ON reservations;
DROP POLICY IF EXISTS "public_insert" ON reservations;
DROP POLICY IF EXISTS "tenant_select" ON blocks;
DROP POLICY IF EXISTS "tenant_insert" ON blocks;
DROP POLICY IF EXISTS "tenant_delete" ON blocks;
DROP POLICY IF EXISTS "public_select" ON blocks;
DROP POLICY IF EXISTS "tenant_select" ON table_blocks;
DROP POLICY IF EXISTS "tenant_insert" ON table_blocks;
DROP POLICY IF EXISTS "tenant_delete" ON table_blocks;
DROP POLICY IF EXISTS "public_select" ON table_blocks;
DROP POLICY IF EXISTS "tenant_select" ON map_positions;
DROP POLICY IF EXISTS "tenant_insert" ON map_positions;
DROP POLICY IF EXISTS "tenant_delete" ON map_positions;
DROP POLICY IF EXISTS "tenant_select" ON waitlist;
DROP POLICY IF EXISTS "tenant_insert" ON waitlist;
DROP POLICY IF EXISTS "tenant_update" ON waitlist;
DROP POLICY IF EXISTS "tenant_delete" ON waitlist;

-- ============================================================================
-- TENANTS: admin can read/update own tenant, public can read (for app display)
-- ============================================================================
CREATE POLICY "tenant_select" ON tenants FOR SELECT TO authenticated
  USING (admin_user_id = auth.uid());
CREATE POLICY "tenant_update" ON tenants FOR UPDATE TO authenticated
  USING (admin_user_id = auth.uid())
  WITH CHECK (admin_user_id = auth.uid());
CREATE POLICY "public_select" ON tenants FOR SELECT TO anon
  USING (true);

-- ============================================================================
-- AREAS: admin CRUD, public read
-- ============================================================================
CREATE POLICY "tenant_select" ON areas FOR SELECT TO authenticated
  USING (tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid()));
CREATE POLICY "tenant_insert" ON areas FOR INSERT TO authenticated
  WITH CHECK (tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid()));
CREATE POLICY "tenant_delete" ON areas FOR DELETE TO authenticated
  USING (tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid()));
CREATE POLICY "public_select" ON areas FOR SELECT TO anon
  USING (true);

-- ============================================================================
-- TABLES_DEF: admin CRUD, public read
-- ============================================================================
CREATE POLICY "tenant_select" ON tables_def FOR SELECT TO authenticated
  USING (tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid()));
CREATE POLICY "tenant_insert" ON tables_def FOR INSERT TO authenticated
  WITH CHECK (tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid()));
CREATE POLICY "tenant_delete" ON tables_def FOR DELETE TO authenticated
  USING (tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid()));
CREATE POLICY "public_select" ON tables_def FOR SELECT TO anon
  USING (true);

-- ============================================================================
-- OPERATING_HOURS: admin CRUD, public read
-- ============================================================================
CREATE POLICY "tenant_select" ON operating_hours FOR SELECT TO authenticated
  USING (tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid()));
CREATE POLICY "tenant_insert" ON operating_hours FOR INSERT TO authenticated
  WITH CHECK (tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid()));
CREATE POLICY "tenant_delete" ON operating_hours FOR DELETE TO authenticated
  USING (tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid()));
CREATE POLICY "public_select" ON operating_hours FOR SELECT TO anon
  USING (true);

-- ============================================================================
-- RESERVATIONS: admin full access, public can read and create
-- ============================================================================
CREATE POLICY "tenant_select" ON reservations FOR SELECT TO authenticated
  USING (tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid()));
CREATE POLICY "tenant_insert" ON reservations FOR INSERT TO authenticated
  WITH CHECK (tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid()));
CREATE POLICY "tenant_update" ON reservations FOR UPDATE TO authenticated
  USING (tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid()));
CREATE POLICY "tenant_delete" ON reservations FOR DELETE TO authenticated
  USING (tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid()));
CREATE POLICY "public_select" ON reservations FOR SELECT TO anon
  USING (true);
CREATE POLICY "public_insert" ON reservations FOR INSERT TO anon
  WITH CHECK (true);

-- ============================================================================
-- BLOCKS: admin CRUD, public read
-- ============================================================================
CREATE POLICY "tenant_select" ON blocks FOR SELECT TO authenticated
  USING (tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid()));
CREATE POLICY "tenant_insert" ON blocks FOR INSERT TO authenticated
  WITH CHECK (tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid()));
CREATE POLICY "tenant_delete" ON blocks FOR DELETE TO authenticated
  USING (tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid()));
CREATE POLICY "public_select" ON blocks FOR SELECT TO anon
  USING (true);

-- ============================================================================
-- TABLE_BLOCKS: admin CRUD, public read
-- ============================================================================
CREATE POLICY "tenant_select" ON table_blocks FOR SELECT TO authenticated
  USING (tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid()));
CREATE POLICY "tenant_insert" ON table_blocks FOR INSERT TO authenticated
  WITH CHECK (tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid()));
CREATE POLICY "tenant_delete" ON table_blocks FOR DELETE TO authenticated
  USING (tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid()));
CREATE POLICY "public_select" ON table_blocks FOR SELECT TO anon
  USING (true);

-- ============================================================================
-- MAP_POSITIONS: admin CRUD only
-- ============================================================================
CREATE POLICY "tenant_select" ON map_positions FOR SELECT TO authenticated
  USING (tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid()));
CREATE POLICY "tenant_insert" ON map_positions FOR INSERT TO authenticated
  WITH CHECK (tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid()));
CREATE POLICY "tenant_delete" ON map_positions FOR DELETE TO authenticated
  USING (tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid()));

-- ============================================================================
-- WAITLIST: admin full access
-- ============================================================================
CREATE POLICY "tenant_select" ON waitlist FOR SELECT TO authenticated
  USING (tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid()));
CREATE POLICY "tenant_insert" ON waitlist FOR INSERT TO authenticated
  WITH CHECK (tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid()));
CREATE POLICY "tenant_update" ON waitlist FOR UPDATE TO authenticated
  USING (tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid()));
CREATE POLICY "tenant_delete" ON waitlist FOR DELETE TO authenticated
  USING (tenant_id IN (SELECT id FROM tenants WHERE admin_user_id = auth.uid()));
