-- Usuários do GitLab encontrados como membros dos projetos importados,
-- e o vínculo de cada um com os projetos (nível de acesso).

create table public.gitlab_users (
  id           bigint primary key,                -- id do usuário no GitLab
  username     text        not null,
  name         text        not null,
  state        text        not null,              -- active, blocked, deactivated...
  avatar_url   text,
  web_url      text        not null,
  imported_at  timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

comment on table public.gitlab_users is 'Usuários do GitLab importados a partir dos membros dos projetos.';

create trigger gitlab_users_set_updated_at
  before update on public.gitlab_users
  for each row execute function public.set_updated_at();

create table public.gitlab_project_members (
  project_id    bigint      not null references public.gitlab_projects (id) on delete cascade,
  user_id       bigint      not null references public.gitlab_users (id) on delete cascade,
  access_level  integer     not null,             -- 10 guest, 15 planner, 20 reporter, 30 developer, 40 maintainer, 50 owner
  expires_at    date,
  imported_at   timestamptz not null default now(),
  primary key (project_id, user_id)
);

comment on table public.gitlab_project_members is 'Membros de cada projeto do GitLab (diretos e herdados do grupo).';

create index gitlab_project_members_user_idx on public.gitlab_project_members (user_id);

alter table public.gitlab_users enable row level security;
alter table public.gitlab_project_members enable row level security;
