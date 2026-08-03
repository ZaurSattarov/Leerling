-- Fase 5A: beperk schrijftoegang op de storage-bucket 'avatars' tot de eigen
-- leerlingmap. De drie bestaande write-policies controleerden alleen het
-- EERSTE padsegment ('leerlingen'), niet welke specifieke leerling-map het
-- betrof -- daardoor kon elke ingelogde gebruiker in theorie een avatar van
-- een andere leerling overschrijven/verwijderen als hij het pad kende.
--
-- Padstructuur (ongewijzigd, zie lib/core/services/student_service.dart
-- uploadMijnProfielfoto): avatars/leerlingen/{leerling_id}/profiel_....ext
--   storage.foldername(name)[1] = 'leerlingen'   (vast segment)
--   storage.foldername(name)[2] = de leerling-id (moet nu overeenkomen met
--                                  een leerlingen-rij van de aanroeper)
--
-- Alleen deze drie schrijf-policies worden vervangen. avatars_read_public
-- (publieke leestoegang -- bucket is bewust public=true) blijft ongewijzigd,
-- net als alle policies op andere buckets (invoices, bonnen).
--
-- Instructeur-uitzondering is bewust NIET toegevoegd: geverifieerd dat de
-- Instructeur-app nergens naar de 'avatars'-bucket schrijft (instructeur-
-- avatars gebruiken een losstaande lokale asset-picker, geen Storage-upload).
-- Deze functionaliteit is dus exclusief van de leerling zelf.

BEGIN;

DROP POLICY IF EXISTS "avatars_insert_authenticated" ON storage.objects;
DROP POLICY IF EXISTS "avatars_update_authenticated" ON storage.objects;
DROP POLICY IF EXISTS "avatars_delete_authenticated" ON storage.objects;

-- INSERT: nieuwe upload mag alleen landen in de map van de eigen leerlingrij.
CREATE POLICY "avatars_insert_eigen_leerling"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'avatars'
  AND (storage.foldername(name))[1] = 'leerlingen'
  AND (storage.foldername(name))[2] IN (
    SELECT id::text FROM public.leerlingen WHERE user_id = auth.uid()
  )
);

-- UPDATE: zowel USING (welke bestaande rij mag de aanroeper aanraken) als
-- WITH CHECK (naar welk pad mag het object na de update wijzen) zijn
-- expliciet gezet op dezelfde eigen-mapcontrole. Reden: Postgres RLS
-- evalueert USING tegen de OUDE rij en WITH CHECK tegen de NIEUWE rij. Zonder
-- expliciete WITH CHECK valt UPDATE terug op dezelfde expressie als USING,
-- maar dat gedrag hangt af van of de policy-auteur zich dat realiseert -- de
-- oorspronkelijke, te brede policy liet dit ook impliciet en bood daardoor
-- geen enkele garantie. Door WITH CHECK hier expliciet en identiek te maken
-- aan USING garanderen we dat een leerling een EIGEN object niet via UPDATE
-- (bv. Supabase Storage 'move') kan verplaatsen/hernoemen naar de map van
-- een andere leerling: dat zou als NIEUW pad niet meer voldoen aan de
-- eigen-mapcontrole en wordt dus geweigerd.
CREATE POLICY "avatars_update_eigen_leerling"
ON storage.objects
FOR UPDATE
TO authenticated
USING (
  bucket_id = 'avatars'
  AND (storage.foldername(name))[1] = 'leerlingen'
  AND (storage.foldername(name))[2] IN (
    SELECT id::text FROM public.leerlingen WHERE user_id = auth.uid()
  )
)
WITH CHECK (
  bucket_id = 'avatars'
  AND (storage.foldername(name))[1] = 'leerlingen'
  AND (storage.foldername(name))[2] IN (
    SELECT id::text FROM public.leerlingen WHERE user_id = auth.uid()
  )
);

-- DELETE: dit recht bestond al (breed) -- behouden, nu beperkt tot de eigen
-- map, in plaats van een nieuw recht te introduceren.
CREATE POLICY "avatars_delete_eigen_leerling"
ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id = 'avatars'
  AND (storage.foldername(name))[1] = 'leerlingen'
  AND (storage.foldername(name))[2] IN (
    SELECT id::text FROM public.leerlingen WHERE user_id = auth.uid()
  )
);

COMMIT;
