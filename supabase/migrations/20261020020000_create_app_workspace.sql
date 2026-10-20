-- Projetos / Workspace do FlowAnalytics, usados pela api-flowanalytics.
-- Projetos internos do time, com funcionalidades e subfuncionalidades (um nível), prazos e conclusões.
-- Sem dados de exemplo: as tabelas começam vazias.

create table public.app_work_projects (
  id              uuid        primary key default gen_random_uuid(),
  name            text        not null default '',  -- opcional; sem nome, o app mostra a descrição
  description     text        not null check (length(btrim(description)) > 0),
  due_date        date,                             -- prazo previsto
  completed_date  date,                             -- conclusão do projeto
  git_project_id  bigint      references public.gitlab_projects (id) on delete set null,  -- projeto do GitLab vinculado (opcional)
  created_by      text,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

create trigger app_work_projects_set_updated_at
  before update on public.app_work_projects
  for each row execute function public.set_updated_at();

-- Funcionalidade com parent_id nulo; subfuncionalidade aponta para a funcionalidade (só um nível, garantido pela API).
-- Concluída = completed_date preenchida.
create table public.app_work_features (
  id              uuid        primary key default gen_random_uuid(),
  project_id      uuid        not null references public.app_work_projects (id) on delete cascade,
  parent_id       uuid        references public.app_work_features (id) on delete cascade,
  name            text        not null check (length(btrim(name)) > 0),
  due_date        date,
  completed_date  date,
  position        integer     not null default 0,  -- ordem entre irmãs
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

create index app_work_features_project_idx on public.app_work_features (project_id, parent_id, position);

create trigger app_work_features_set_updated_at
  before update on public.app_work_features
  for each row execute function public.set_updated_at();

-- Issues do GitLab vinculadas às funcionalidades de último nível.
create table public.app_work_feature_issues (
  feature_id  uuid    not null references public.app_work_features (id) on delete cascade,
  issue_id    bigint  not null references public.gitlab_issues (id) on delete cascade,
  primary key (feature_id, issue_id)
);

create index app_work_feature_issues_issue_idx on public.app_work_feature_issues (issue_id);

alter table public.app_work_projects enable row level security;
alter table public.app_work_features enable row level security;
alter table public.app_work_feature_issues enable row level security;
