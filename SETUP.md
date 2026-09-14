# Aeroflutter — Phase 1 Setup Guide

Complete Supabase setup for the Aeroflutter attendance system.

---

## Prerequisites

- A web browser
- The three SQL files from this repo:
  1. `schema_init.sql`
  2. `rls_policies.sql`
  3. `seed_data.sql`

---

## Step 1 — Create a Supabase Project

1. Go to [https://supabase.com](https://supabase.com) and sign in (or create a free account).
2. Click **New Project**.
3. Fill in:
   - **Name:** `aeroflutter`
   - **Database Password:** choose a strong password and save it somewhere safe
   - **Region:** choose the region closest to your office
4. Click **Create new project** and wait ~2 minutes for provisioning.

---

## Step 2 — Get Your API Keys

1. In your project dashboard, go to **Settings → API**.
2. Copy and save:
   - **Project URL** — looks like `https://xxxxxxxxxxxx.supabase.co`
   - **anon / public key** — safe to include in mobile/web apps
   - **service_role / secret key** — NEVER expose in client code
3. Paste these into your `.env` files (see `.env.example`).

---

## Step 3 — Run the Schema

1. In your project dashboard, click **SQL Editor** in the left sidebar.
2. Click **New query**.
3. Open `schema_init.sql` in a text editor, copy the entire contents.
4. Paste into the SQL Editor.
5. Click **Run** (or press `Cmd/Ctrl + Enter`).
6. You should see `Success. No rows returned` — that is correct.

**Verify:** Go to **Table Editor** — you should see four tables:
- `employees`
- `attendance`
- `owners`
- `audit_logs`

---

## Step 4 — Run the RLS Policies

1. Click **New query** in the SQL Editor.
2. Open `rls_policies.sql`, copy the entire contents.
3. Paste and click **Run**.

**Verify:** Go to **Authentication → Policies** — you should see policies listed under each table.

> If you see an error like `function is_owner() already exists`, that is safe to ignore — it means you are re-running the script.

---

## Step 5 — Create the Owner Auth User

The owner needs an account in Supabase Auth before their row in the `owners` table will work for login.

1. Go to **Authentication → Users** in your project dashboard.
2. Click **Add User** → **Create new user**.
3. Fill in:
   - **Email:** `owner@aeroflutter.app`
   - **Password:** choose a strong password
4. Click **Create User**.
5. Copy the **UUID** that appears in the user list (it looks like `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`).

---

## Step 6 — Run the Seed Data

1. Open `seed_data.sql` in a text editor.
2. Find this line near the top:
   ```sql
   '00000000-0000-0000-0000-000000000001',   -- Replace with real auth UUID
   ```
3. Replace `00000000-0000-0000-0000-000000000001` with the UUID you copied in Step 5.
4. Copy the entire (modified) file contents.
5. In the SQL Editor, click **New query**, paste, and click **Run**.

**Verify:** Go to **Table Editor → owners** — you should see one row with `owner@aeroflutter.app`.

> The sample employee rows use placeholder UUIDs (`00000000-0000-0000-0000-00000000001x`). They are useful for viewing schema data but you cannot log in as them. See "Creating Test Employee Auth Users" below if you need login testing.

---

## Step 7 — Verify RLS Policies

Run these queries in the SQL Editor to confirm policies are working:

```sql
-- Should return rows (running as service role bypasses RLS — expected)
SELECT * FROM employees;
SELECT * FROM attendance;

-- Check that RLS is enabled on all tables
SELECT tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'public';
-- All four tables should show rowsecurity = true
```

---

## Step 8 — Set Up Your .env Files

Copy `.env.example` to `.env` in each sub-project:

```
cp .env.example mobile-app/.env
cp .env.example web-dashboard/.env
```

Fill in the values from Step 2.

> The `SUPABASE_SERVICE_ROLE_KEY` goes only in your Edge Functions `.env`, never in the mobile or web app.

---

## Creating Test Employee Auth Users (Optional, for Phase 2+)

To test the full login flow before the mobile app is built:

1. Go to **Authentication → Users → Add User** for each test employee.
2. Copy the UUID Supabase generates.
3. In the SQL Editor, update the seed employee row:
   ```sql
   UPDATE employees
   SET id = 'PASTE-REAL-UUID-HERE'
   WHERE email = 'alice@example.com';
   ```
4. Also update any related attendance rows:
   ```sql
   UPDATE attendance
   SET employee_id = 'PASTE-REAL-UUID-HERE'
   WHERE employee_id = '00000000-0000-0000-0000-000000000010';
   ```

---

## Testing Checklist

After completing all steps above:

- [ ] Supabase project created and provisioned
- [ ] `schema_init.sql` ran without errors
- [ ] All 4 tables visible in Table Editor
- [ ] `rls_policies.sql` ran without errors
- [ ] Policies visible in Authentication → Policies
- [ ] Owner auth user created in Authentication → Users
- [ ] `seed_data.sql` ran with correct owner UUID
- [ ] `owners` table has 1 row
- [ ] `employees` table has 4 rows
- [ ] `attendance` table has 7+ rows
- [ ] `audit_logs` table has 9+ rows
- [ ] `.env` files populated with real API keys
- [ ] Service role key is NOT in any client `.env` file

---

## Common Errors

| Error | Cause | Fix |
|-------|-------|-----|
| `relation "employees" already exists` | Schema already ran | Safe to ignore or `DROP TABLE` first |
| `function is_owner() already exists` | RLS already ran | Safe to ignore |
| `duplicate key value violates unique constraint` | Seed already ran | Safe to ignore (uses `ON CONFLICT DO NOTHING`) |
| Owner can't log in | Auth user UUID doesn't match owners.id | Re-run Step 5-6 with correct UUID |

---

## What's Next — Phase 2

Phase 2 builds the React Native mobile app authentication screens:
- Login screen (Supabase Auth sign-in)
- Signup screen (creates employee row + captures GPS)
- Forgot password flow

Required Supabase configuration before Phase 2:
- **Authentication → URL Configuration**: set Site URL to your Expo dev URL
- **Authentication → Email Templates**: customize the confirmation email
- **Authentication → Providers**: ensure Email provider is enabled
