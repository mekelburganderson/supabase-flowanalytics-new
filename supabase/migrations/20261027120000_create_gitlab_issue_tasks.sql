-- Tasks do GitLab (work items do tipo Task) filhas de issues: vínculo com a issue pai e detalhes da task.
-- Lidas pela GraphQL API (widget de hierarquia), que a REST não expõe. A task também existe em gitlab_issues
-- (issue_type = 'task'); aqui fica quem é a issue pai e o que a task tem de próprio.
-- Só entram tasks com issue pai já importada em gitlab_issues.

create table public.gitlab_issue_tasks (
  task_id            bigint      primary key,          -- id global da task no GitLab (o mesmo de gitlab_issues.id)
  parent_issue_id    bigint      not null references public.gitlab_issues (id) on delete cascade,
  project_id         bigint      not null references public.gitlab_projects (id) on delete cascade,
  iid                integer     not null,             -- número da task no projeto
  title              text        not null,
  description        text,
  state              text        not null check (state in ('opened', 'closed')),
  author_id          bigint      references public.gitlab_users (id) on delete set null,
  milestone_id       bigint,                           -- id do milestone no GitLab (sem FK: pode não estar importado)
  start_date         date,
  due_date           date,
  time_estimate      integer     not null default 0,   -- segundos
  total_time_spent   integer     not null default 0,   -- segundos
  gitlab_created_at  timestamptz not null,
  gitlab_updated_at  timestamptz not null,
  closed_at          timestamptz,
  web_url            text        not null,
  imported_at        timestamptz not null default now(),
  updated_at         timestamptz not null default now(),
  unique (project_id, iid)
);

create index gitlab_issue_tasks_parent_idx on public.gitlab_issue_tasks (parent_issue_id);

create trigger gitlab_issue_tasks_set_updated_at
  before update on public.gitlab_issue_tasks
  for each row execute function public.set_updated_at();

create table public.gitlab_issue_task_assignees (
  task_id  bigint not null references public.gitlab_issue_tasks (task_id) on delete cascade,
  user_id  bigint not null references public.gitlab_users (id) on delete cascade,
  primary key (task_id, user_id)
);

create index gitlab_issue_task_assignees_user_idx on public.gitlab_issue_task_assignees (user_id);

alter table public.gitlab_issue_tasks enable row level security;
alter table public.gitlab_issue_task_assignees enable row level security;
