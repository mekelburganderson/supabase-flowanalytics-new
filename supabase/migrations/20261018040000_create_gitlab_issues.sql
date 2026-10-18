-- Issues do GitLab: dados principais (gitlab_issues), detalhes (gitlab_issue_details)
-- e vínculos com responsáveis e labels. Autor, responsáveis, labels e milestone apontam
-- para as tabelas já existentes (gitlab_users, gitlab_labels, gitlab_milestones).

create table public.gitlab_issues (
  id                 bigint primary key,            -- id global da issue no GitLab
  iid                integer     not null,          -- número da issue no projeto
  project_id         bigint      not null references public.gitlab_projects (id) on delete cascade,
  title              text        not null,
  description        text,
  state              text        not null check (state in ('opened', 'closed')),
  author_id          bigint      references public.gitlab_users (id) on delete set null,
  milestone_id       bigint      references public.gitlab_milestones (id) on delete set null,
  gitlab_created_at  timestamptz not null,
  gitlab_updated_at  timestamptz not null,
  closed_at          timestamptz,
  due_date           date,
  web_url            text        not null,
  imported_at        timestamptz not null default now(),
  updated_at         timestamptz not null default now(),
  unique (project_id, iid)
);

create index gitlab_issues_author_idx on public.gitlab_issues (author_id);
create index gitlab_issues_milestone_idx on public.gitlab_issues (milestone_id);

create trigger gitlab_issues_set_updated_at
  before update on public.gitlab_issues
  for each row execute function public.set_updated_at();

create table public.gitlab_issue_details (
  issue_id              bigint primary key references public.gitlab_issues (id) on delete cascade,
  state                 text        not null check (state in ('opened', 'closed')),
  issue_type            text,
  milestone_id          bigint      references public.gitlab_milestones (id) on delete set null,
  gitlab_created_at     timestamptz not null,
  gitlab_updated_at     timestamptz not null,
  closed_at             timestamptz,
  closed_by_id          bigint      references public.gitlab_users (id) on delete set null,
  start_date            date,
  due_date              date,
  confidential          boolean     not null default false,
  user_notes_count      integer     not null default 0,
  merge_requests_count  integer     not null default 0,
  upvotes               integer     not null default 0,
  downvotes             integer     not null default 0,
  time_estimate         integer     not null default 0,  -- segundos
  total_time_spent      integer     not null default 0,  -- segundos
  task_count            integer     not null default 0,
  task_completed_count  integer     not null default 0,
  imported_at           timestamptz not null default now(),
  updated_at            timestamptz not null default now()
);

create trigger gitlab_issue_details_set_updated_at
  before update on public.gitlab_issue_details
  for each row execute function public.set_updated_at();

create table public.gitlab_issue_assignees (
  issue_id  bigint not null references public.gitlab_issues (id) on delete cascade,
  user_id   bigint not null references public.gitlab_users (id) on delete cascade,
  primary key (issue_id, user_id)
);

create index gitlab_issue_assignees_user_idx on public.gitlab_issue_assignees (user_id);

create table public.gitlab_issue_labels (
  issue_id  bigint not null references public.gitlab_issues (id) on delete cascade,
  label_id  bigint not null references public.gitlab_labels (id) on delete cascade,
  primary key (issue_id, label_id)
);

create index gitlab_issue_labels_label_idx on public.gitlab_issue_labels (label_id);

alter table public.gitlab_issues enable row level security;
alter table public.gitlab_issue_details enable row level security;
alter table public.gitlab_issue_assignees enable row level security;
alter table public.gitlab_issue_labels enable row level security;
