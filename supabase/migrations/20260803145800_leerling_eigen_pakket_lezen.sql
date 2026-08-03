-- ============================================================================
-- Fase 4 -- leerling mag eigen toegewezen lespakket lezen
-- ============================================================================
-- Aanleiding: docs/PROFIEL_ARCHITECTUUR.md (afwijking 1) en het onderzoek in
-- Fase 4 (Rijopleiding/Lespakket). Instructeur-app's eigen weergavepatroon
-- (leerling_detail_screen.dart, "Fase F" in hun eigen commentaar) leest voor
-- élk pakketveld eerst de immutable snapshot op leerlingen; ALLEEN wanneer
-- leerling.pakket_snapshot_vastgelegd_op nog NULL is (legacy-toewijzing, vóór
-- de snapshotfunctionaliteit bestond) valt het terug op een rechtstreekse,
-- gerichte select-by-id op instructor_lesson_packages.
--
-- Vandaag heeft GEEN van de 33 leerlingen met een pakket_id al een volledige
-- snapshot (geverifieerd tegen de live data) -- de catalogus-fallback is dus
-- niet een randgeval maar het hoofdpad voor bijna alle huidige leerlingen.
-- Zonder leesrechten op instructor_lesson_packages zou de Leerling-app voor
-- vrijwel iedereen "Pakketgegevens niet beschikbaar" moeten tonen, terwijl er
-- wel degelijk een geldig toegewezen pakket bestaat.
--
-- Vandaag bestaat er precies één policy op instructor_lesson_packages:
-- "instructor_lesson_packages_own" (ALL, USING/WITH CHECK: instructeur_id =
-- auth.uid()) -- uitsluitend de eigen instructeur. Een leerling heeft nul
-- toegang, ook niet tot het eigen toegewezen pakket.
--
-- Deze migratie voegt UITSLUITEND een nieuwe, smalle SELECT-policy toe:
-- een leerling mag alleen het pakket lezen waarnaar zijn EIGEN
-- leerlingen.pakket_id verwijst (via leerlingen.user_id = auth.uid()).
-- Geen INSERT/UPDATE/DELETE-rechten, geen toegang tot andere pakketten van
-- dezelfde of een andere instructeur, geen wijziging aan de bestaande
-- instructeur-policy.
--
-- Idempotent: DROP POLICY IF EXISTS vóór CREATE POLICY. Wijzigt geen
-- bestaande rijen, verwijdert niets.
-- ============================================================================

DROP POLICY IF EXISTS leerling_eigen_toegewezen_pakket_lezen
  ON public.instructor_lesson_packages;

CREATE POLICY leerling_eigen_toegewezen_pakket_lezen
  ON public.instructor_lesson_packages
  FOR SELECT
  USING (
    id IN (
      SELECT pakket_id
      FROM public.leerlingen
      WHERE user_id = auth.uid()
        AND pakket_id IS NOT NULL
    )
  );

COMMENT ON POLICY leerling_eigen_toegewezen_pakket_lezen ON public.instructor_lesson_packages IS
  'Leerling mag uitsluitend het eigen toegewezen pakket lezen (legacy-catalogusfallback voor leerlingen zonder pakket_snapshot_vastgelegd_op). Zie docs/PROFIEL_ARCHITECTUUR.md.';
