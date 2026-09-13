-- Recherche plein texte exposée au client avec filtres de corpus.
-- `legal_documents.search_vector` est maintenu par migration_010.

create or replace function public.search_legal_corpus(
  p_query text default '',
  p_type text default null,
  p_domain text default null,
  p_limit integer default 100
)
returns table (id text, search_rank real)
language sql
stable
as $$
  select
    d.id,
    ts_rank_cd(
      d.search_vector,
      websearch_to_tsquery('french', nullif(trim(p_query), ''))
    )::real as search_rank
  from public.legal_documents d
  where (nullif(trim(p_query), '') is null
      or d.search_vector @@ websearch_to_tsquery('french', trim(p_query))
      or lower(d.reference) like '%' || lower(trim(p_query)) || '%')
    and (p_type is null or d.type = p_type)
    and (p_domain is null or d.domain = p_domain)
  order by search_rank desc nulls last, d.updated_at desc, d.title asc
  limit greatest(1, least(coalesce(p_limit, 100), 200));
$$;

grant execute on function public.search_legal_corpus(text, text, text, integer) to anon, authenticated;
