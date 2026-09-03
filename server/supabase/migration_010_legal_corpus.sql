-- ============================================================================
--  migration_010 — Corpus juridique de la bibliothèque
-- ----------------------------------------------------------------------------
--  Deux tables alimentées par le pipeline `tools/legal_import/` :
--    - legal_documents : la fiche d'un texte (métadonnées + prose éventuelle)
--    - legal_articles  : le texte intégral, article par article
--
--  Lecture PUBLIQUE (anon) : la bibliothèque est consultable sans compte.
--  Écriture réservée au service_role (le pipeline), qui contourne la RLS.
-- ============================================================================

create table if not exists public.legal_documents (
  id                    text primary key,
  title                 text not null,
  type                  text not null,   -- constitution|code|loi|decret|arrete|jurisprudence|traite|modeleActe
  domain                text not null,   -- civil|penal|commercial|travail|famille|administratif|fiscal|constitutionnel|foncier|ohada|procedureCivile|procedurePenale|autre
  reference             text not null default '',
  date_publication      date,
  date_entree_en_vigueur date,
  status                text not null default 'enVigueur', -- enVigueur|modifie|abroge|projet
  summary               text not null default '',
  full_content          text not null default '',
  outline               text[] not null default '{}',
  summary_only          boolean not null default false, -- true : synthèse seule, texte intégral à venir
  official_source_name  text,
  source_url            text,
  tags                  text[] not null default '{}',
  related_ids           text[] not null default '{}',
  search_vector         tsvector,
  imported_at           timestamptz,
  created_at            timestamptz not null default now(),
  updated_at            timestamptz not null default now()
);

create table if not exists public.legal_articles (
  document_id  text not null references public.legal_documents(id) on delete cascade,
  ord          int  not null,          -- ordre d'apparition (0-based)
  number       text not null,          -- « 1 », « 12 bis », « L. 122-4 »
  heading      text not null default '',
  body         text not null,
  path         text[] not null default '{}',  -- « Livre I », « Titre II », « Chapitre 1 »
  primary key (document_id, ord)
);

create index if not exists legal_articles_doc_idx        on public.legal_articles (document_id);
create index if not exists legal_documents_type_idx      on public.legal_documents (type);
create index if not exists legal_documents_domain_idx    on public.legal_documents (domain);
create index if not exists legal_documents_search_idx    on public.legal_documents using gin (search_vector);

-- --- recherche plein texte (français), maintenue par trigger -----------------
create or replace function public.legal_documents_search_refresh()
returns trigger language plpgsql as $$
begin
  new.search_vector :=
      setweight(to_tsvector('french', coalesce(new.title, '')),      'A')
   || setweight(to_tsvector('french', coalesce(new.reference, '')),  'B')
   || setweight(to_tsvector('french', coalesce(new.summary, '')),    'B')
   || setweight(to_tsvector('french', array_to_string(new.tags, ' ')), 'B')
   || setweight(to_tsvector('french', coalesce(new.full_content, '')), 'C');
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists legal_documents_search_trg on public.legal_documents;
create trigger legal_documents_search_trg
  before insert or update on public.legal_documents
  for each row execute function public.legal_documents_search_refresh();

-- --- RLS : lecture publique, écriture service_role uniquement ----------------
alter table public.legal_documents enable row level security;
alter table public.legal_articles  enable row level security;

drop policy if exists "legal_documents_public_read" on public.legal_documents;
create policy "legal_documents_public_read"
  on public.legal_documents for select
  using (true);

drop policy if exists "legal_articles_public_read" on public.legal_articles;
create policy "legal_articles_public_read"
  on public.legal_articles for select
  using (true);

-- Aucune policy INSERT/UPDATE/DELETE : seul le service_role (bypass RLS),
-- utilisé par `tools/legal_import push`, peut écrire dans ces tables.
