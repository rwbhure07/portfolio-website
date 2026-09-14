-- =============================================================
-- Aeroflutter: schema_init.sql
-- Phase 1 — Database Schema Initialization
-- Run this FIRST in Supabase SQL Editor
-- =============================================================

-- Enable the uuid-ossp extension (needed for uuid generation functions)
-- gen_random_uuid() is built-in to PostgreSQL 13+ (Supabase uses 15),
-- but we enable this for compatibility with any uuid helper functions.
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";


-- =============================================================
-- TABLE: employees
-- Stores employee profiles, signup GPS location, and face encoding.
-- One row per employee. Created during self-registration on mobile app.
-- =============================================================
CREATE TABLE IF NOT EXISTS employees (
  id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email              TEXT UNIQUE NOT NULL,
  name               TEXT NOT NULL,
  phone              TEXT,

  -- GPS coordinates captured at the moment the employee signed up.
  -- This is treated as the "office location" for that employee.
  -- NEVER updated after initial signup — it is the geofence anchor.
  signup_latitude    NUMERIC(10, 7) NOT NULL,
  signup_longitude   NUMERIC(10, 7) NOT NULL,

  -- face_encoding is a JSONB array of ~128 floats produced by Google ML Kit.
  -- Stored as JSONB so we can query/update it without full row replacement.
  -- NULL until the employee completes face registration (onboarding step 2).
  face_encoding      JSONB,

  -- Gates access to check-in: employee must have a stored face before checking in.
  is_onboarded       BOOLEAN NOT NULL DEFAULT false,

  created_at         TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at         TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Index on email for fast lookups during login / uniqueness checks.
CREATE INDEX IF NOT EXISTS idx_employees_email       ON employees(email);
-- Index for admin queries sorted by registration date.
CREATE INDEX IF NOT EXISTS idx_employees_created_at  ON employees(created_at);
-- Partial index: quickly find employees who still need onboarding.
CREATE INDEX IF NOT EXISTS idx_employees_not_onboarded
  ON employees(is_onboarded)
  WHERE is_onboarded = false;


-- =============================================================
-- TABLE: attendance
-- One row per (employee, calendar date). Stores check-in and
-- check-out in the same row to make "present today" queries trivial.
-- =============================================================
CREATE TABLE IF NOT EXISTS attendance (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id           UUID NOT NULL REFERENCES employees(id) ON DELETE CASCADE,

  -- Calendar date (not timestamp) used for the unique constraint and daily reporting.
  -- Stored in UTC; the mobile app should send the local date.
  date                  DATE NOT NULL,

  -- Check-in fields (populated on first tap of "Check In")
  check_in_time         TIMESTAMP WITH TIME ZONE,
  check_in_latitude     NUMERIC(10, 7),
  check_in_longitude    NUMERIC(10, 7),
  -- GCS URL set after Edge Function uploads the selfie; may be NULL briefly.
  check_in_image_url    TEXT,

  -- Check-out fields (populated on tap of "Check Out"; may remain NULL if employee forgets)
  check_out_time        TIMESTAMP WITH TIME ZONE,
  check_out_latitude    NUMERIC(10, 7),
  check_out_longitude   NUMERIC(10, 7),
  check_out_image_url   TEXT,

  created_at            TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at            TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),

  -- Enforces business rule: max one check-in record per employee per day.
  CONSTRAINT uq_attendance_employee_date UNIQUE (employee_id, date)
);

-- Primary access pattern: "show all records for employee X"
CREATE INDEX IF NOT EXISTS idx_attendance_employee_id
  ON attendance(employee_id);

-- Primary access pattern: "show all attendance for date Y" (owner dashboard)
CREATE INDEX IF NOT EXISTS idx_attendance_date
  ON attendance(date);

-- Composite index for the most common query: employee + date lookup (check-in exists?)
CREATE INDEX IF NOT EXISTS idx_attendance_employee_date
  ON attendance(employee_id, date);

-- Partial index: quickly find rows where check-out is still missing
-- (useful for "currently in office" view on owner dashboard).
CREATE INDEX IF NOT EXISTS idx_attendance_missing_checkout
  ON attendance(date)
  WHERE check_out_time IS NULL;


-- =============================================================
-- TABLE: owners
-- Stores company owner / HR manager accounts.
-- Intentionally separate from employees: different auth users,
-- different RLS policies, different roles.
-- =============================================================
CREATE TABLE IF NOT EXISTS owners (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email         TEXT UNIQUE NOT NULL,
  company_name  TEXT,
  phone         TEXT,
  created_at    TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Index for fast lookups by email (auth callbacks, role checks).
CREATE INDEX IF NOT EXISTS idx_owners_email ON owners(email);


-- =============================================================
-- TABLE: audit_logs
-- Append-only log of all significant actions.
-- Used for debugging, compliance, and detecting anomalies
-- (e.g. repeated failed face-match attempts).
-- employee_id is SET NULL on employee deletion so log history is preserved.
-- =============================================================
CREATE TABLE IF NOT EXISTS audit_logs (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id     UUID REFERENCES employees(id) ON DELETE SET NULL,
  action          TEXT NOT NULL CHECK (action IN ('signup', 'onboard_face', 'check_in', 'check_out')),
  status          TEXT NOT NULL CHECK (status IN ('success', 'failed')),
  -- Stores the failure reason: 'too_far_from_office', 'face_mismatch', etc.
  error_message   TEXT,
  -- Extra context: distance in meters, similarity score, IP address, etc.
  metadata        JSONB,
  created_at      TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_audit_logs_employee_id  ON audit_logs(employee_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_action       ON audit_logs(action);
-- Time-range queries for compliance reports
CREATE INDEX IF NOT EXISTS idx_audit_logs_created_at   ON audit_logs(created_at);
-- Fast lookup of all failures for monitoring / alerting
CREATE INDEX IF NOT EXISTS idx_audit_logs_status
  ON audit_logs(status)
  WHERE status = 'failed';


-- =============================================================
-- TRIGGER: auto-update updated_at columns
-- Keeps updated_at current without requiring the app to set it.
-- =============================================================
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

CREATE OR REPLACE TRIGGER trg_employees_updated_at
  BEFORE UPDATE ON employees
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE OR REPLACE TRIGGER trg_attendance_updated_at
  BEFORE UPDATE ON attendance
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();
