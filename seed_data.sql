-- =============================================================
-- Aeroflutter: seed_data.sql
-- Phase 1 — Seed / Sample Data
-- Run this AFTER schema_init.sql AND rls_policies.sql
-- =============================================================
--
-- IMPORTANT — Read before running:
--
-- Supabase Auth (auth.users) and the employees/owners tables are separate.
-- RLS policies check auth.uid(), which only works for rows whose `id`
-- matches an actual Supabase Auth user.
--
-- For local testing, you have two options:
--
-- OPTION A (Recommended for Phase 1 testing):
--   Run this script as-is. The UUIDs below are fixed test UUIDs.
--   You will NOT be able to log in as these employees because no
--   auth.users rows exist for them. Use the Supabase Dashboard's
--   "Table Editor" to VIEW the data, and the SQL Editor to query it.
--
-- OPTION B (For end-to-end mobile app testing in Phase 2+):
--   1. Go to Supabase Dashboard → Authentication → Users
--   2. Click "Add User" → fill in email/password
--   3. Copy the UUID Supabase assigns to that auth user
--   4. Replace the UUID values below with the ones from the dashboard
--   5. Run the INSERT statements
--   This links auth users to employee rows so login works.
--
-- The owner account MUST be created via OPTION B before the web
-- dashboard can log in. See SETUP.md for step-by-step instructions.
-- =============================================================


-- =============================================================
-- OWNER ACCOUNT
-- Create the auth user in the dashboard first, then insert here.
-- =============================================================

-- STEP: In Supabase Dashboard → Auth → Users → Add User
--   Email: owner@aeroflutter.app
--   Password: (set a strong password)
--   Copy the UUID assigned by Supabase and replace 'OWNER_UUID_HERE'

INSERT INTO owners (id, email, company_name, phone)
VALUES (
  '00000000-0000-0000-0000-000000000001',   -- Replace with real auth UUID
  'owner@aeroflutter.app',
  'Aeroflutter Corp',
  '+1-555-000-0001'
)
ON CONFLICT (email) DO NOTHING;


-- =============================================================
-- SAMPLE EMPLOYEES
-- Fixed UUIDs for schema testing. Replace with real auth UUIDs
-- for end-to-end login testing (see OPTION B above).
--
-- Office reference location: 28.6139° N, 77.2090° E (New Delhi, India)
-- All signup coordinates are within a few metres of each other,
-- simulating employees who registered while physically at the office.
-- =============================================================

-- Employee 1: Alice Johnson — fully onboarded
INSERT INTO employees (
  id, email, name, phone,
  signup_latitude, signup_longitude,
  face_encoding, is_onboarded
) VALUES (
  '00000000-0000-0000-0000-000000000010',
  'alice@example.com',
  'Alice Johnson',
  '+1-555-100-0001',
  28.6139200, 77.2090100,
  -- 128-float face encoding produced by ML Kit (sample values — replace with real ones)
  '[0.12,-0.45,0.78,0.23,-0.67,0.34,0.89,-0.12,0.56,-0.34,
    0.67,-0.23,0.45,0.78,-0.56,0.12,-0.89,0.34,0.67,-0.45,
    0.23,0.56,-0.78,0.12,0.34,-0.67,0.89,0.45,-0.23,0.78,
   -0.12,0.56,0.23,-0.45,0.67,-0.34,0.78,0.12,-0.56,0.89,
    0.45,-0.23,0.67,0.34,-0.89,0.12,0.56,-0.78,0.23,0.45,
   -0.67,0.89,0.12,-0.34,0.56,0.78,-0.23,0.45,0.67,-0.12,
    0.34,-0.89,0.56,0.23,-0.45,0.78,0.12,0.67,-0.34,0.89,
    0.45,-0.56,0.23,0.78,-0.12,0.34,0.67,-0.89,0.56,0.12,
   -0.45,0.78,0.23,-0.67,0.34,0.89,-0.12,0.56,-0.34,0.67,
   -0.23,0.45,0.78,-0.56,0.12,-0.89,0.34,0.67,-0.45,0.23,
    0.56,-0.78,0.12,0.34,-0.67,0.89,0.45,-0.23,0.78,-0.12,
    0.56,0.23,-0.45,0.67,-0.34,0.78,0.12,-0.56,0.89,0.45,
   -0.23,0.67,0.34,-0.89,0.12,0.56,-0.78,0.23,0.45,-0.67]',
  true
) ON CONFLICT (email) DO NOTHING;

-- Employee 2: Bob Smith — fully onboarded
INSERT INTO employees (
  id, email, name, phone,
  signup_latitude, signup_longitude,
  face_encoding, is_onboarded
) VALUES (
  '00000000-0000-0000-0000-000000000011',
  'bob@example.com',
  'Bob Smith',
  '+1-555-100-0002',
  28.6139350, 77.2090250,
  '[0.34,-0.56,0.12,0.78,-0.23,0.45,0.67,-0.89,0.12,0.56,
   -0.34,0.78,0.23,-0.45,0.67,0.12,-0.56,0.89,0.34,-0.67,
    0.45,0.78,-0.12,0.56,0.23,-0.89,0.67,0.34,-0.45,0.78,
    0.12,-0.34,0.56,0.89,-0.23,0.45,0.67,-0.78,0.12,0.34,
   -0.56,0.23,0.78,-0.45,0.67,0.12,-0.89,0.34,0.56,-0.23,
    0.45,0.78,-0.12,0.67,0.34,-0.56,0.89,0.23,-0.45,0.78,
    0.12,0.56,-0.34,0.67,0.89,-0.23,0.45,0.78,-0.12,0.34,
   -0.67,0.56,0.23,-0.89,0.45,0.78,0.12,-0.34,0.67,0.89,
   -0.56,0.23,0.45,-0.78,0.12,0.34,0.67,-0.89,0.56,0.23,
   -0.45,0.78,0.12,-0.67,0.34,0.89,-0.23,0.56,0.45,-0.78,
    0.12,0.34,0.67,-0.56,0.89,0.23,-0.45,0.78,0.12,-0.34,
    0.56,0.67,-0.89,0.23,0.45,0.78,-0.12,0.34,0.67,-0.56,
    0.89,0.23,-0.45,0.78,0.12,0.34,-0.67,0.56,0.89,-0.23]',
  true
) ON CONFLICT (email) DO NOTHING;

-- Employee 3: Carol Brown — not yet onboarded (no face encoding yet)
INSERT INTO employees (
  id, email, name, phone,
  signup_latitude, signup_longitude,
  face_encoding, is_onboarded
) VALUES (
  '00000000-0000-0000-0000-000000000012',
  'carol@example.com',
  'Carol Brown',
  '+1-555-100-0003',
  28.6138900, 77.2089900,
  NULL,      -- face_encoding is NULL: Carol completed step 1 but not step 2
  false
) ON CONFLICT (email) DO NOTHING;

-- Employee 4: David Lee — fully onboarded
INSERT INTO employees (
  id, email, name, phone,
  signup_latitude, signup_longitude,
  face_encoding, is_onboarded
) VALUES (
  '00000000-0000-0000-0000-000000000013',
  'david@example.com',
  'David Lee',
  '+1-555-100-0004',
  28.6139100, 77.2090400,
  '[0.67,-0.12,0.45,0.89,-0.34,0.56,0.23,-0.78,0.45,0.12,
   -0.67,0.34,0.89,-0.23,0.56,0.78,-0.45,0.12,0.34,-0.89,
    0.67,0.23,-0.56,0.45,0.78,-0.12,0.34,0.89,-0.67,0.23,
    0.56,-0.45,0.12,0.78,-0.34,0.67,0.89,-0.56,0.23,0.45,
   -0.12,0.78,0.34,-0.67,0.56,0.89,-0.23,0.45,0.12,-0.78,
    0.67,0.34,-0.89,0.56,0.23,-0.45,0.78,0.12,0.67,-0.34,
    0.89,0.56,-0.23,0.45,0.78,-0.12,0.34,0.67,-0.89,0.56,
    0.23,-0.45,0.78,0.12,-0.34,0.67,0.89,-0.56,0.23,0.45,
   -0.78,0.12,0.34,0.67,-0.89,0.56,0.23,-0.45,0.78,0.12,
   -0.34,0.67,0.89,-0.56,0.23,0.45,-0.78,0.12,0.34,0.67,
   -0.89,0.56,0.23,-0.45,0.78,0.12,0.34,-0.67,0.89,0.56,
    0.23,-0.45,0.78,0.12,-0.34,0.67,0.89,-0.56,0.23,0.45,
   -0.12,0.78,0.34,-0.67,0.56,0.89,-0.23,0.45,0.12,-0.78]',
  true
) ON CONFLICT (email) DO NOTHING;


-- =============================================================
-- SAMPLE ATTENDANCE RECORDS
-- Simulates one week of check-ins/check-outs for Alice and Bob.
-- Carol has no attendance (not onboarded). David has partial data.
-- =============================================================

-- Alice — Monday (full day)
INSERT INTO attendance (
  employee_id, date,
  check_in_time,  check_in_latitude,  check_in_longitude,  check_in_image_url,
  check_out_time, check_out_latitude, check_out_longitude, check_out_image_url
) VALUES (
  '00000000-0000-0000-0000-000000000010',
  CURRENT_DATE - INTERVAL '4 days',
  (CURRENT_DATE - INTERVAL '4 days')::TIMESTAMP WITH TIME ZONE + INTERVAL '9 hours 10 minutes',
  28.6139200, 77.2090100,
  'https://storage.googleapis.com/aeroflutter-dev/alice_checkin_monday.jpg',
  (CURRENT_DATE - INTERVAL '4 days')::TIMESTAMP WITH TIME ZONE + INTERVAL '18 hours 5 minutes',
  28.6139200, 77.2090100,
  'https://storage.googleapis.com/aeroflutter-dev/alice_checkout_monday.jpg'
) ON CONFLICT ON CONSTRAINT uq_attendance_employee_date DO NOTHING;

-- Alice — Tuesday (full day)
INSERT INTO attendance (
  employee_id, date,
  check_in_time,  check_in_latitude,  check_in_longitude,  check_in_image_url,
  check_out_time, check_out_latitude, check_out_longitude, check_out_image_url
) VALUES (
  '00000000-0000-0000-0000-000000000010',
  CURRENT_DATE - INTERVAL '3 days',
  (CURRENT_DATE - INTERVAL '3 days')::TIMESTAMP WITH TIME ZONE + INTERVAL '9 hours 2 minutes',
  28.6139210, 77.2090110,
  'https://storage.googleapis.com/aeroflutter-dev/alice_checkin_tuesday.jpg',
  (CURRENT_DATE - INTERVAL '3 days')::TIMESTAMP WITH TIME ZONE + INTERVAL '17 hours 55 minutes',
  28.6139200, 77.2090100,
  'https://storage.googleapis.com/aeroflutter-dev/alice_checkout_tuesday.jpg'
) ON CONFLICT ON CONSTRAINT uq_attendance_employee_date DO NOTHING;

-- Alice — Wednesday (no check-out: forgot to tap)
INSERT INTO attendance (
  employee_id, date,
  check_in_time, check_in_latitude, check_in_longitude, check_in_image_url
) VALUES (
  '00000000-0000-0000-0000-000000000010',
  CURRENT_DATE - INTERVAL '2 days',
  (CURRENT_DATE - INTERVAL '2 days')::TIMESTAMP WITH TIME ZONE + INTERVAL '9 hours 30 minutes',
  28.6139200, 77.2090100,
  'https://storage.googleapis.com/aeroflutter-dev/alice_checkin_wednesday.jpg'
) ON CONFLICT ON CONSTRAINT uq_attendance_employee_date DO NOTHING;

-- Alice — Today (just checked in, still in office)
INSERT INTO attendance (
  employee_id, date,
  check_in_time, check_in_latitude, check_in_longitude, check_in_image_url
) VALUES (
  '00000000-0000-0000-0000-000000000010',
  CURRENT_DATE,
  now() - INTERVAL '2 hours',
  28.6139200, 77.2090100,
  'https://storage.googleapis.com/aeroflutter-dev/alice_checkin_today.jpg'
) ON CONFLICT ON CONSTRAINT uq_attendance_employee_date DO NOTHING;

-- Bob — Monday (full day)
INSERT INTO attendance (
  employee_id, date,
  check_in_time,  check_in_latitude,  check_in_longitude,  check_in_image_url,
  check_out_time, check_out_latitude, check_out_longitude, check_out_image_url
) VALUES (
  '00000000-0000-0000-0000-000000000011',
  CURRENT_DATE - INTERVAL '4 days',
  (CURRENT_DATE - INTERVAL '4 days')::TIMESTAMP WITH TIME ZONE + INTERVAL '9 hours 25 minutes',
  28.6139360, 77.2090260,
  'https://storage.googleapis.com/aeroflutter-dev/bob_checkin_monday.jpg',
  (CURRENT_DATE - INTERVAL '4 days')::TIMESTAMP WITH TIME ZONE + INTERVAL '18 hours 30 minutes',
  28.6139350, 77.2090250,
  'https://storage.googleapis.com/aeroflutter-dev/bob_checkout_monday.jpg'
) ON CONFLICT ON CONSTRAINT uq_attendance_employee_date DO NOTHING;

-- Bob — Tuesday (absent — no row inserted; owner dashboard shows as absent)

-- Bob — Wednesday (full day)
INSERT INTO attendance (
  employee_id, date,
  check_in_time,  check_in_latitude,  check_in_longitude,  check_in_image_url,
  check_out_time, check_out_latitude, check_out_longitude, check_out_image_url
) VALUES (
  '00000000-0000-0000-0000-000000000011',
  CURRENT_DATE - INTERVAL '2 days',
  (CURRENT_DATE - INTERVAL '2 days')::TIMESTAMP WITH TIME ZONE + INTERVAL '9 hours 15 minutes',
  28.6139360, 77.2090260,
  'https://storage.googleapis.com/aeroflutter-dev/bob_checkin_wednesday.jpg',
  (CURRENT_DATE - INTERVAL '2 days')::TIMESTAMP WITH TIME ZONE + INTERVAL '19 hours',
  28.6139350, 77.2090250,
  'https://storage.googleapis.com/aeroflutter-dev/bob_checkout_wednesday.jpg'
) ON CONFLICT ON CONSTRAINT uq_attendance_employee_date DO NOTHING;

-- David — Today (checked in, working)
INSERT INTO attendance (
  employee_id, date,
  check_in_time, check_in_latitude, check_in_longitude, check_in_image_url
) VALUES (
  '00000000-0000-0000-0000-000000000013',
  CURRENT_DATE,
  now() - INTERVAL '1 hour 30 minutes',
  28.6139100, 77.2090400,
  'https://storage.googleapis.com/aeroflutter-dev/david_checkin_today.jpg'
) ON CONFLICT ON CONSTRAINT uq_attendance_employee_date DO NOTHING;


-- =============================================================
-- SAMPLE AUDIT LOGS
-- =============================================================

-- Successful check-ins
INSERT INTO audit_logs (employee_id, action, status, metadata)
VALUES
  ('00000000-0000-0000-0000-000000000010', 'check_in', 'success',
   '{"distance_meters": 2.1, "face_similarity": 0.97}'),
  ('00000000-0000-0000-0000-000000000011', 'check_in', 'success',
   '{"distance_meters": 5.4, "face_similarity": 0.94}'),
  ('00000000-0000-0000-0000-000000000013', 'check_in', 'success',
   '{"distance_meters": 8.2, "face_similarity": 0.91}');

-- Failed check-in: employee was too far from office
INSERT INTO audit_logs (employee_id, action, status, error_message, metadata)
VALUES (
  '00000000-0000-0000-0000-000000000010',
  'check_in', 'failed',
  'too_far_from_office',
  '{"distance_meters": 127.5, "threshold_meters": 50}'
);

-- Failed check-in: face did not match
INSERT INTO audit_logs (employee_id, action, status, error_message, metadata)
VALUES (
  '00000000-0000-0000-0000-000000000011',
  'check_in', 'failed',
  'face_mismatch',
  '{"face_similarity": 0.43, "threshold": 0.60}'
);

-- Signup and onboarding events
INSERT INTO audit_logs (employee_id, action, status)
VALUES
  ('00000000-0000-0000-0000-000000000010', 'signup', 'success'),
  ('00000000-0000-0000-0000-000000000010', 'onboard_face', 'success'),
  ('00000000-0000-0000-0000-000000000011', 'signup', 'success'),
  ('00000000-0000-0000-0000-000000000011', 'onboard_face', 'success'),
  ('00000000-0000-0000-0000-000000000012', 'signup', 'success'),  -- Carol: signed up
  ('00000000-0000-0000-0000-000000000013', 'signup', 'success'),
  ('00000000-0000-0000-0000-000000000013', 'onboard_face', 'success');
