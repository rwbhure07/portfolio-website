-- =============================================================
-- Aeroflutter: rls_policies.sql
-- Phase 1 — Row Level Security Policies
-- Run this AFTER schema_init.sql
-- =============================================================
--
-- Security model summary:
--   EMPLOYEE  → can only see and modify their own data
--   OWNER     → read-only access to ALL employee and attendance data
--   ANON      → can only write to employees during signup flow
--
-- How ownership is determined:
--   Employees: employees.id must equal auth.uid()
--   Owners:    owners.id must equal auth.uid()
--             (so an owner must have a corresponding row in owners table)
-- =============================================================


-- =============================================================
-- Helper function: is the current user a registered owner?
-- Called in USING clauses; returns true if auth.uid() exists in owners.
-- Defined as SECURITY DEFINER so it can bypass RLS on the owners table
-- while checking the owners table itself.
-- =============================================================
CREATE OR REPLACE FUNCTION is_owner()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT EXISTS (
    SELECT 1 FROM owners WHERE id = auth.uid()
  );
$$;


-- =============================================================
-- TABLE: employees — RLS
-- =============================================================
ALTER TABLE employees ENABLE ROW LEVEL SECURITY;

-- ANON: Allow self-registration (INSERT only, no SELECT/UPDATE/DELETE)
-- The mobile app uses the anon key to create a new employee row on signup.
-- The employee cannot read or modify any rows at this point.
CREATE POLICY "anon_can_insert_employee_on_signup"
  ON employees
  FOR INSERT
  TO anon
  WITH CHECK (true);

-- EMPLOYEE: Can read only their own profile row.
-- Used by the mobile app to load name, face_encoding, signup location.
CREATE POLICY "employee_can_read_own_profile"
  ON employees
  FOR SELECT
  TO authenticated
  USING (
    id = auth.uid()          -- employee reads their own row
    OR is_owner()            -- or owner reads all rows (see below)
  );

-- EMPLOYEE: Can update only their own profile (e.g. face_encoding, is_onboarded).
-- Prevents employees from editing other employees' face data.
CREATE POLICY "employee_can_update_own_profile"
  ON employees
  FOR UPDATE
  TO authenticated
  USING (id = auth.uid())
  WITH CHECK (id = auth.uid());

-- OWNER: Read access to ALL employees is handled by the SELECT policy above
-- (is_owner() check), so no separate policy is needed for owners on this table.

-- NOTE: DELETE on employees is intentionally not permitted via RLS.
-- Employee deletion (offboarding) should be done manually by an admin
-- through the Supabase Dashboard or a server-side Edge Function using
-- the service role key, not exposed to any client.


-- =============================================================
-- TABLE: attendance — RLS
-- =============================================================
ALTER TABLE attendance ENABLE ROW LEVEL SECURITY;

-- EMPLOYEE: Can read only their own attendance history.
-- Used by the mobile app to show "your last 30 days".
CREATE POLICY "employee_can_read_own_attendance"
  ON attendance
  FOR SELECT
  TO authenticated
  USING (
    employee_id = auth.uid()   -- employee reads their own
    OR is_owner()              -- or owner reads all
  );

-- EMPLOYEE: Can insert a new attendance record (check-in).
-- WITH CHECK ensures the employee can only create records for themselves.
CREATE POLICY "employee_can_insert_own_attendance"
  ON attendance
  FOR INSERT
  TO authenticated
  WITH CHECK (employee_id = auth.uid());

-- EMPLOYEE: Can update their own attendance record (to add check-out data).
-- Prevents an employee from modifying another employee's check-out time.
CREATE POLICY "employee_can_update_own_attendance"
  ON attendance
  FOR UPDATE
  TO authenticated
  USING (employee_id = auth.uid())
  WITH CHECK (employee_id = auth.uid());

-- OWNER: Read-only; owners cannot insert, update, or delete attendance records.
-- Write operations on attendance are reserved for employees (and Edge Functions
-- using the service role key for the image URL update step).


-- =============================================================
-- TABLE: owners — RLS
-- =============================================================
ALTER TABLE owners ENABLE ROW LEVEL SECURITY;

-- OWNER: Can read only their own owner profile.
-- No write access via client — owner rows are created server-side.
CREATE POLICY "owner_can_read_own_profile"
  ON owners
  FOR SELECT
  TO authenticated
  USING (id = auth.uid());

-- Anon and employees cannot read, insert, update, or delete from owners.
-- (No policies created for those roles → access denied by default.)


-- =============================================================
-- TABLE: audit_logs — RLS
-- =============================================================
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;

-- EMPLOYEE: Can insert their own audit log entries (success/failure events).
-- The mobile app logs check-in attempts including failures.
CREATE POLICY "employee_can_insert_own_audit_log"
  ON audit_logs
  FOR INSERT
  TO authenticated
  WITH CHECK (employee_id = auth.uid());

-- EMPLOYEE: Can read only their own audit logs (e.g. "why did check-in fail?").
-- OWNER: Can read all audit logs (compliance / debugging).
CREATE POLICY "employee_or_owner_can_read_audit_logs"
  ON audit_logs
  FOR SELECT
  TO authenticated
  USING (
    employee_id = auth.uid()
    OR is_owner()
  );

-- Nobody can UPDATE or DELETE audit_logs via the client.
-- Audit logs are append-only by policy design.
