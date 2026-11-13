-- Dream Diary: read-only Supabase inventory for manual review.
-- Run each SELECT statement separately in Supabase SQL Editor after reviewing it.
-- This file contains metadata queries and aggregate row counts only. It does not
-- select user rows or personal content. No migration or data change is included.

-- Group 1A: actual column metadata for the two public tables.
-- Expected: one row per visible column, including type, nullability, default,
-- identity/generated metadata. A missing table/permission can return no rows.
SELECT
  table_name,
  ordinal_position,
  column_name,
  data_type,
  udt_schema,
  udt_name,
  is_nullable,
  column_default,
  is_identity,
  identity_generation,
  is_generated,
  generation_expression
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name IN ('dreams', 'sleep_records')
ORDER BY table_name, ordinal_position;

-- Group 1B: explicit presence check for legacy and contract columns.
-- Expected: only columns that exist are returned. This does not inspect values.
SELECT
  table_name,
  column_name,
  data_type,
  udt_schema,
  udt_name,
  is_nullable,
  column_default,
  is_identity,
  identity_generation,
  is_generated
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name IN ('dreams', 'sleep_records')
  AND column_name IN (
    'id', 'user_id', 'title', 'content', 'emotion', 'tags',
    'clarity_score', 'is_lucid', 'dream_date', 'created_at',
    'sleep_time', 'wake_time', 'duration_minutes', 'quality', 'quality_score',
    'deep_sleep_minutes', 'light_sleep_minutes', 'rem_sleep_minutes',
    'note', 'notes', 'start_time', 'end_time'
  )
ORDER BY table_name, column_name;

-- Group 2: primary key, foreign key, unique, check, and other constraints.
-- Expected: catalog definitions and FK delete action. Catalog access is needed.
-- If this query is denied, ask the project owner to run it as a role allowed to
-- inspect PostgreSQL catalogs; do not infer constraints from supabase_schema.sql.
SELECT
  ns.nspname AS table_schema,
  tbl.relname AS table_name,
  con.conname AS constraint_name,
  CASE con.contype
    WHEN 'p' THEN 'PRIMARY KEY'
    WHEN 'f' THEN 'FOREIGN KEY'
    WHEN 'u' THEN 'UNIQUE'
    WHEN 'c' THEN 'CHECK'
    WHEN 'x' THEN 'EXCLUSION'
    ELSE con.contype::text
  END AS constraint_type,
  pg_get_constraintdef(con.oid, true) AS constraint_definition,
  CASE con.confdeltype
    WHEN 'a' THEN 'NO ACTION'
    WHEN 'r' THEN 'RESTRICT'
    WHEN 'c' THEN 'CASCADE'
    WHEN 'n' THEN 'SET NULL'
    WHEN 'd' THEN 'SET DEFAULT'
    ELSE NULL
  END AS foreign_key_on_delete,
  con.convalidated AS is_validated,
  con.condeferrable AS is_deferrable,
  con.condeferred AS initially_deferred
FROM pg_constraint AS con
JOIN pg_class AS tbl ON tbl.oid = con.conrelid
JOIN pg_namespace AS ns ON ns.oid = tbl.relnamespace
WHERE ns.nspname = 'public'
  AND tbl.relname IN ('dreams', 'sleep_records')
ORDER BY tbl.relname, con.contype, con.conname;

-- Group 3A: indexes attached to the two tables.
-- Expected: index names and definitions; pg_indexes visibility depends on role.
SELECT schemaname, tablename, indexname, indexdef
FROM pg_indexes
WHERE schemaname = 'public'
  AND tablename IN ('dreams', 'sleep_records')
ORDER BY tablename, indexname;

-- Group 3B: non-internal triggers and the trigger functions they invoke.
-- Expected: trigger metadata and function identity, never function source code.
SELECT
  ns.nspname AS table_schema,
  tbl.relname AS table_name,
  trg.tgname AS trigger_name,
  trg.tgenabled AS enabled_state,
  fn_ns.nspname AS function_schema,
  fn.proname AS function_name,
  pg_get_function_identity_arguments(fn.oid) AS function_arguments
FROM pg_trigger AS trg
JOIN pg_class AS tbl ON tbl.oid = trg.tgrelid
JOIN pg_namespace AS ns ON ns.oid = tbl.relnamespace
JOIN pg_proc AS fn ON fn.oid = trg.tgfoid
JOIN pg_namespace AS fn_ns ON fn_ns.oid = fn.pronamespace
WHERE ns.nspname = 'public'
  AND tbl.relname IN ('dreams', 'sleep_records')
  AND NOT trg.tgisinternal
ORDER BY tbl.relname, trg.tgname;

-- Group 3C: functions with a direct catalog dependency on either table.
-- Expected: function identities only. PostgreSQL does not record every
-- relation reference inside every procedural function body; an empty result
-- does not prove that no function reads these tables. Function bodies are
-- intentionally not selected. Catalog visibility may depend on role/version.
SELECT DISTINCT
  fn_ns.nspname AS function_schema,
  fn.proname AS function_name,
  pg_get_function_identity_arguments(fn.oid) AS function_arguments,
  lang.lanname AS language,
  fn.prosecdef AS security_definer,
  fn.provolatile AS volatility
FROM pg_depend AS dep
JOIN pg_proc AS fn ON dep.classid = 'pg_proc'::regclass AND dep.objid = fn.oid
JOIN pg_namespace AS fn_ns ON fn_ns.oid = fn.pronamespace
JOIN pg_language AS lang ON lang.oid = fn.prolang
JOIN pg_class AS tbl ON dep.refclassid = 'pg_class'::regclass AND dep.refobjid = tbl.oid
JOIN pg_namespace AS tbl_ns ON tbl_ns.oid = tbl.relnamespace
WHERE tbl_ns.nspname = 'public'
  AND tbl.relname IN ('dreams', 'sleep_records')
ORDER BY fn_ns.nspname, fn.proname, function_arguments;

-- Group 4A: RLS flags on both tables.
-- Expected: one row per existing table with enabled/forced RLS flags.
SELECT
  ns.nspname AS table_schema,
  tbl.relname AS table_name,
  tbl.relrowsecurity AS row_level_security_enabled,
  tbl.relforcerowsecurity AS row_level_security_forced
FROM pg_class AS tbl
JOIN pg_namespace AS ns ON ns.oid = tbl.relnamespace
WHERE ns.nspname = 'public'
  AND tbl.relkind IN ('r', 'p')
  AND tbl.relname IN ('dreams', 'sleep_records')
ORDER BY tbl.relname;

-- Group 4B: row-level security policies.
-- Expected: policy roles, command, permissive mode, and USING/WITH CHECK rules.
-- These are policy definitions, not row data. A permission error means the
-- result is incomplete and must not be treated as “no policies”.
SELECT
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual AS using_expression,
  with_check AS with_check_expression
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename IN ('dreams', 'sleep_records')
ORDER BY tablename, policyname;

-- Group 4C: explicit table grants visible to the current SQL Editor role.
-- Expected: grantee, privilege, and grantability. This view may omit inherited
-- or indirect privileges; supplement with an owner-reviewed privilege check
-- if the result is incomplete. Do not infer safety from an empty result alone.
SELECT
  table_schema,
  table_name,
  grantee,
  privilege_type,
  is_grantable,
  with_hierarchy
FROM information_schema.role_table_grants
WHERE table_schema = 'public'
  AND table_name IN ('dreams', 'sleep_records')
ORDER BY table_name, grantee, privilege_type;

-- Group 5: focused legacy/target-column inventory.
-- This repeats part of Group 1 to make mapping review easier; it still returns
-- column metadata only, never tags, notes, dream content, or sleep timestamps.
SELECT
  table_name,
  column_name,
  data_type,
  udt_schema,
  udt_name,
  is_nullable,
  column_default,
  is_identity,
  identity_generation,
  is_generated
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name IN ('dreams', 'sleep_records')
  AND column_name IN (
    'tags', 'dream_date', 'clarity_score', 'is_lucid',
    'sleep_time', 'wake_time', 'quality', 'quality_score',
    'duration_minutes', 'start_time', 'end_time', 'deep_sleep_minutes',
    'light_sleep_minutes', 'rem_sleep_minutes', 'note', 'notes'
  )
ORDER BY table_name, column_name;

-- Group 6: aggregate row counts only; no row-level values or identifiers.
-- COUNT(*) may scan large tables. Run only if acceptable for the project load.
-- Result visibility can be affected by the executing role and RLS; record the
-- role/context and treat counts as visible-row counts unless confirmed otherwise.
SELECT 'dreams' AS table_name, COUNT(*)::bigint AS row_count
FROM public.dreams
UNION ALL
SELECT 'sleep_records' AS table_name, COUNT(*)::bigint AS row_count
FROM public.sleep_records
ORDER BY table_name;
