-- ============================================================
-- STUDENT APP MIGRATION
-- Run this in Supabase SQL Editor (same project as instructor app)
-- This does NOT change existing instructor tables or policies.
-- ============================================================

-- 1. Add user_id to leerlingen so students can log in
ALTER TABLE leerlingen
  ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_leerlingen_user_id ON leerlingen(user_id);

-- 2. Student notifications table
CREATE TABLE IF NOT EXISTS leerling_notificaties (
  id            UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  leerling_id   UUID NOT NULL REFERENCES leerlingen(id) ON DELETE CASCADE,
  instructeur_id UUID NOT NULL REFERENCES instructeur_profielen(id) ON DELETE CASCADE,
  titel         TEXT NOT NULL,
  omschrijving  TEXT,
  type          TEXT NOT NULL DEFAULT 'systeem', -- les | factuur | voortgang | systeem
  gelezen       BOOLEAN NOT NULL DEFAULT FALSE,
  aangemaakt_op TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_leerling_notificaties_leerling
  ON leerling_notificaties(leerling_id, gelezen, aangemaakt_op DESC);

-- ============================================================
-- 3. RLS: enable on new table
-- ============================================================

ALTER TABLE leerling_notificaties ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- 4. STUDENT RLS POLICIES
-- Helper: find own leerling_id from auth.uid() via user_id column
-- ============================================================

-- 4a. Students can read their own leerling record
CREATE POLICY "student_leerling_select" ON leerlingen
  FOR SELECT
  USING (user_id = auth.uid());

-- 4b. Students can read their own lessons
CREATE POLICY "student_lessen_select" ON lessen
  FOR SELECT
  USING (
    leerling_id IN (
      SELECT id FROM leerlingen WHERE user_id = auth.uid()
    )
  );

-- 4c. Students can read their own invoices
CREATE POLICY "student_facturen_select" ON facturen
  FOR SELECT
  USING (
    leerling_id IN (
      SELECT id FROM leerlingen WHERE user_id = auth.uid()
    )
  );

-- 4d. Students can read the instructor profile of their own instructor
CREATE POLICY "student_instructeur_select" ON instructeur_profielen
  FOR SELECT
  USING (
    id IN (
      SELECT instructeur_id FROM leerlingen WHERE user_id = auth.uid()
    )
  );

-- 4e. Students can read their own exam results
CREATE POLICY "student_examen_resultaten_select" ON examen_resultaten
  FOR SELECT
  USING (
    leerling_id IN (
      SELECT id FROM leerlingen WHERE user_id = auth.uid()
    )
  );

-- 4f. Students can read & mark their own notifications
CREATE POLICY "student_notificaties_select" ON leerling_notificaties
  FOR SELECT
  USING (
    leerling_id IN (
      SELECT id FROM leerlingen WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "student_notificaties_update" ON leerling_notificaties
  FOR UPDATE
  USING (
    leerling_id IN (
      SELECT id FROM leerlingen WHERE user_id = auth.uid()
    )
  )
  WITH CHECK (
    leerling_id IN (
      SELECT id FROM leerlingen WHERE user_id = auth.uid()
    )
  );

-- ============================================================
-- 5. INSTRUCTOR can manage student notifications
-- ============================================================

CREATE POLICY "instructeur_notificaties_all" ON leerling_notificaties
  FOR ALL
  USING (instructeur_id = auth.uid())
  WITH CHECK (instructeur_id = auth.uid());

-- ============================================================
-- 6. Instructor app: allow instructors to update user_id
--    (so they can invite/link a student account)
-- ============================================================

-- Instructors can already update leerlingen (existing policy).
-- No extra policy needed — the existing UPDATE policy on leerlingen
-- (where instructeur_id = auth.uid()) already covers setting user_id.

-- ============================================================
-- 7. OPTIONAL: function to link student by email
-- Instructors call this to connect a student's auth account.
-- ============================================================

CREATE OR REPLACE FUNCTION link_student_account(
  p_leerling_id UUID,
  p_student_email TEXT
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id UUID;
BEGIN
  SELECT id INTO v_user_id
  FROM auth.users
  WHERE email = p_student_email
  LIMIT 1;

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Geen account gevonden voor e-mailadres: %', p_student_email;
  END IF;

  UPDATE leerlingen
  SET user_id = v_user_id
  WHERE id = p_leerling_id
    AND instructeur_id = auth.uid();
END;
$$;
