-- À exécuter une fois dans le SQL Editor de votre projet Supabase — ajoute
-- ce qui manquait à schema.sql (déjà exécuté) pour la migration complète des
-- 4 modules. Sans risque à réexécuter (idempotent).

alter table public.professional_drafting_results
  add column if not exists risks jsonb not null default '[]'::jsonb;

alter table public.professional_drafting_results
  add column if not exists cited_sources jsonb not null default '[]'::jsonb;

alter table public.litigation_messages
  add column if not exists suggested_professional text;

create or replace function public.increment_download_count(doc_id text)
returns void as $$
begin
  insert into public.library_document_stats (document_id, download_count)
  values (doc_id, 1)
  on conflict (document_id)
  do update set download_count = public.library_document_stats.download_count + 1;
end;
$$ language plpgsql security invoker set search_path = public;
