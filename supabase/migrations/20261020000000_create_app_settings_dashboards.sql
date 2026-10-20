-- Configurações do FlowAnalytics (tela Configurações), usadas pela api-flowanalytics.

-- ---------- Configurações gerais ----------
-- Projetos do GitLab usados no sistema. Lista própria, independente de gitlab_projects.active
-- (que só controla a importação). Uma linha só (id = 1).
create table public.app_settings (
  id            smallint    primary key default 1 check (id = 1),
  all_projects  boolean     not null default true,  -- true = todos os projetos importados, inclusive os que entrarem depois
  updated_by    text,
  updated_at    timestamptz not null default now()
);

comment on column public.app_settings.all_projects is 'Com true, app_system_projects é ignorada e todos os projetos importados são usados.';

insert into public.app_settings (id) values (1);

create trigger app_settings_set_updated_at
  before update on public.app_settings
  for each row execute function public.set_updated_at();

-- Projetos usados quando app_settings.all_projects = false.
create table public.app_system_projects (
  project_id  bigint primary key references public.gitlab_projects (id) on delete cascade
);

-- ---------- Dashboards ----------
-- Cada dashboard define os projetos do GitLab que entram nas análises e quais labels são etapas
-- (em ordem, o fluxo da issue) e tipos (em ordem de prioridade). São compartilhados por todos.

create table public.app_dashboards (
  id            uuid        primary key default gen_random_uuid(),
  name          text        not null check (length(btrim(name)) > 0),
  all_projects  boolean     not null default true,  -- true = todos os projetos usados no sistema, inclusive os que entrarem depois
  position      integer     not null default 0,     -- ordem na lista
  created_by    text,                               -- e-mail de quem criou
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

comment on column public.app_dashboards.all_projects is 'Com true, app_dashboard_projects é ignorada e entram todos os projetos usados no sistema.';

create trigger app_dashboards_set_updated_at
  before update on public.app_dashboards
  for each row execute function public.set_updated_at();

-- Projetos escolhidos quando all_projects = false.
create table public.app_dashboard_projects (
  dashboard_id  uuid    not null references public.app_dashboards (id) on delete cascade,
  project_id    bigint  not null references public.gitlab_projects (id) on delete cascade,
  primary key (dashboard_id, project_id)
);

-- Uso de cada label no dashboard. A label é guardada pelo nome porque labels de grupo
-- e de projetos diferentes podem ter o mesmo nome e devem contar como uma só.
create table public.app_dashboard_labels (
  dashboard_id  uuid     not null references public.app_dashboards (id) on delete cascade,
  label_name    text     not null,
  usage         text     not null check (usage in ('stage', 'type')),
  position      integer  not null,                 -- ordem dentro de etapas ou de tipos
  primary key (dashboard_id, label_name)
);

create index app_dashboard_labels_order_idx on public.app_dashboard_labels (dashboard_id, usage, position);

-- Preferências de cada usuário (identificado pelo e-mail do login).
create table public.app_user_preferences (
  email                text        primary key,
  active_dashboard_id  uuid        references public.app_dashboards (id) on delete set null,
  updated_at           timestamptz not null default now()
);

create trigger app_user_preferences_set_updated_at
  before update on public.app_user_preferences
  for each row execute function public.set_updated_at();

alter table public.app_settings enable row level security;
alter table public.app_system_projects enable row level security;
alter table public.app_dashboards enable row level security;
alter table public.app_dashboard_projects enable row level security;
alter table public.app_dashboard_labels enable row level security;
alter table public.app_user_preferences enable row level security;
