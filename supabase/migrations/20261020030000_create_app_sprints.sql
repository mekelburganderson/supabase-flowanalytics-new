-- Sprints do FlowAnalytics (tela Sprints), usadas pela api-flowanalytics.
-- Sprints do time com tarefas, responsável (usuário do GitLab) e issues vinculadas.
-- Sem dados de exemplo: as tabelas começam vazias.

create table public.app_sprints (
  id           uuid        primary key default gen_random_uuid(),
  name         text        not null check (length(btrim(name)) > 0),
  start_date   date        not null,
  end_date     date        not null,
  description  text        not null default '',
  created_by   text,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),
  check (end_date >= start_date)
);

create index app_sprints_dates_idx on public.app_sprints (start_date desc);

create trigger app_sprints_set_updated_at
  before update on public.app_sprints
  for each row execute function public.set_updated_at();

-- Concluída = done_at preenchida.
create table public.app_sprint_tasks (
  id           uuid        primary key default gen_random_uuid(),
  sprint_id    uuid        not null references public.app_sprints (id) on delete cascade,
  title        text        not null check (length(btrim(title)) > 0),
  assignee_id  bigint      references public.gitlab_users (id) on delete set null,  -- responsável (usuário do GitLab)
  done_at      date,
  position     integer     not null default 0,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

create index app_sprint_tasks_sprint_idx on public.app_sprint_tasks (sprint_id, position);
create index app_sprint_tasks_assignee_idx on public.app_sprint_tasks (assignee_id);

create trigger app_sprint_tasks_set_updated_at
  before update on public.app_sprint_tasks
  for each row execute function public.set_updated_at();

create table public.app_sprint_task_issues (
  task_id   uuid    not null references public.app_sprint_tasks (id) on delete cascade,
  issue_id  bigint  not null references public.gitlab_issues (id) on delete cascade,
  primary key (task_id, issue_id)
);

create index app_sprint_task_issues_issue_idx on public.app_sprint_task_issues (issue_id);

alter table public.app_sprints enable row level security;
alter table public.app_sprint_tasks enable row level security;
alter table public.app_sprint_task_issues enable row level security;
