-- ============================================================================
-- migration_029 — Référencement des PDF de la bibliothèque
-- ============================================================================
-- Le fichier est hébergé dans un bucket public ou une URL institutionnelle.
-- Cette migration ne téléverse aucun document : elle ajoute uniquement le
-- lien permettant à l'application d'ouvrir le PDF attaché à une fiche.

alter table public.legal_documents
  add column if not exists file_url text;

comment on column public.legal_documents.file_url is
  'URL publique ou Supabase Storage du PDF intégral rattaché au document';

