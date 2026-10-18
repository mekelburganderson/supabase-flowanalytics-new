-- Projetos importados do GitLab (gitlab.insidesistemas.com.br).
-- A coluna active define quais projetos as integrações (issues, eventos, MRs via webhooks) usam.
-- A importação atualiza os dados do GitLab mas nunca altera active.

create table public.gitlab_projects (
  id                   bigint primary key,           -- id do projeto no GitLab
  name                 text        not null,
  path_with_namespace  text        not null,
  namespace            text        not null,
  description          text,
  web_url              text        not null,
  visibility           text        not null check (visibility in ('private', 'internal', 'public')),
  default_branch       text,
  archived             boolean     not null default false,
  gitlab_created_at    timestamptz,
  last_activity_at     timestamptz,
  active               boolean     not null default false,
  imported_at          timestamptz not null default now(),
  updated_at           timestamptz not null default now()
);

comment on table public.gitlab_projects is 'Projetos do GitLab importados pela API; active indica se entram nas integrações.';
comment on column public.gitlab_projects.active is 'Só projetos ativos recebem issues, eventos e MRs das integrações.';

create index gitlab_projects_active_idx on public.gitlab_projects (active) where active;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger gitlab_projects_set_updated_at
  before update on public.gitlab_projects
  for each row execute function public.set_updated_at();

-- Acesso só pelo backend (service role / conexão direta); nenhuma policy para anon/authenticated por enquanto.
alter table public.gitlab_projects enable row level security;
