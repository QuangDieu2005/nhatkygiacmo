-- DRAFT ONLY — NOT EXECUTED.
-- Review against the approved API contract and staging before use.
-- This file intentionally has no timestamped migration version. Do not apply it
-- with Supabase CLI or SQL Editor until separately approved and renamed.
-- It creates new tables only; legacy public.dreams and public.sleep_records
-- are not read, modified, renamed, or removed.

CREATE TABLE public.dreams_v2 (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  title text NOT NULL,
  content text NOT NULL,
  emotion text NOT NULL,
  tags text[] NOT NULL DEFAULT ARRAY[]::text[],
  clarity_score integer NOT NULL DEFAULT 3,
  is_lucid boolean NOT NULL DEFAULT false,
  dream_date date NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT dreams_v2_title_length CHECK (char_length(title) BETWEEN 1 AND 180),
  CONSTRAINT dreams_v2_content_length CHECK (char_length(content) BETWEEN 1 AND 20000),
  CONSTRAINT dreams_v2_emotion_allowed CHECK (
    emotion IN ('happy', 'peaceful', 'excited', 'sad', 'scared', 'confused', 'neutral')
  ),
  CONSTRAINT dreams_v2_tags_no_null_elements CHECK (array_position(tags, NULL) IS NULL),
  CONSTRAINT dreams_v2_clarity_score_range CHECK (clarity_score BETWEEN 1 AND 5)
);

CREATE TABLE public.sleep_records_v2 (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  start_time timestamptz NOT NULL,
  end_time timestamptz NOT NULL,
  -- Written by Express after validating start_time/end_time; never accepted from client.
  duration_minutes integer NOT NULL,
  quality_score integer NOT NULL DEFAULT 75,
  deep_sleep_minutes integer NOT NULL DEFAULT 0,
  light_sleep_minutes integer NOT NULL DEFAULT 0,
  rem_sleep_minutes integer NOT NULL DEFAULT 0,
  notes text NOT NULL DEFAULT '',
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT sleep_records_v2_time_range CHECK (
    end_time > start_time AND end_time <= start_time + interval '24 hours'
  ),
  CONSTRAINT sleep_records_v2_duration_matches CHECK (
    duration_minutes = floor(extract(epoch FROM (end_time - start_time)) / 60)::integer
  ),
  CONSTRAINT sleep_records_v2_duration_range CHECK (duration_minutes BETWEEN 0 AND 1440),
  CONSTRAINT sleep_records_v2_quality_range CHECK (quality_score BETWEEN 0 AND 100),
  CONSTRAINT sleep_records_v2_deep_nonnegative CHECK (deep_sleep_minutes >= 0),
  CONSTRAINT sleep_records_v2_light_nonnegative CHECK (light_sleep_minutes >= 0),
  CONSTRAINT sleep_records_v2_rem_nonnegative CHECK (rem_sleep_minutes >= 0)
);

ALTER TABLE public.dreams_v2 ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sleep_records_v2 ENABLE ROW LEVEL SECURITY;

CREATE POLICY dreams_v2_select_own ON public.dreams_v2
  FOR SELECT TO authenticated USING (user_id = auth.uid());
CREATE POLICY dreams_v2_insert_own ON public.dreams_v2
  FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid());
CREATE POLICY dreams_v2_update_own ON public.dreams_v2
  FOR UPDATE TO authenticated
  USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
CREATE POLICY dreams_v2_delete_own ON public.dreams_v2
  FOR DELETE TO authenticated USING (user_id = auth.uid());

CREATE POLICY sleep_records_v2_select_own ON public.sleep_records_v2
  FOR SELECT TO authenticated USING (user_id = auth.uid());
CREATE POLICY sleep_records_v2_insert_own ON public.sleep_records_v2
  FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid());
CREATE POLICY sleep_records_v2_update_own ON public.sleep_records_v2
  FOR UPDATE TO authenticated
  USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
CREATE POLICY sleep_records_v2_delete_own ON public.sleep_records_v2
  FOR DELETE TO authenticated USING (user_id = auth.uid());

-- API architecture is Express-only: authenticated users do not receive direct
-- table privileges. Policies are defense in depth and become effective for a
-- direct client only if a separately reviewed GRANT is approved later.
REVOKE ALL PRIVILEGES ON TABLE public.dreams_v2, public.sleep_records_v2
  FROM PUBLIC, anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.dreams_v2, public.sleep_records_v2
  TO service_role;

-- PK indexes are created by PostgreSQL. These indexes match current API filters/order.
CREATE INDEX dreams_v2_user_created_idx
  ON public.dreams_v2 (user_id, created_at DESC);
CREATE INDEX dreams_v2_user_dream_date_idx
  ON public.dreams_v2 (user_id, dream_date DESC);
CREATE INDEX dreams_v2_tags_gin_idx
  ON public.dreams_v2 USING gin (tags);
CREATE INDEX sleep_records_v2_user_start_idx
  ON public.sleep_records_v2 (user_id, start_time DESC);
CREATE INDEX sleep_records_v2_user_created_idx
  ON public.sleep_records_v2 (user_id, created_at DESC);
