-- Labels e milestones do GitLab. Labels e milestones de grupo valem para vários projetos,
-- por isso o vínculo com o projeto fica em tabelas separadas.

create table public.gitlab_labels (
  id                bigint primary key,             -- id da label no GitLab
  name              text        not null,
  description       text,
  color             text        not null,
  text_color        text,
  is_project_label  boolean     not null,           -- false = label de grupo
  imported_at       timestamptz not null default now(),
  updated_at        timestamptz not null default now()
);

create trigger gitlab_labels_set_updated_at
  before update on public.gitlab_labels
  for each row execute function public.set_updated_at();

create table public.gitlab_project_labels (
  project_id   bigint      not null references public.gitlab_projects (id) on delete cascade,
  label_id     bigint      not null references public.gitlab_labels (id) on delete cascade,
  priority     integer,                             -- prioridade da label no projeto
  imported_at  timestamptz not null default now(),
  primary key (project_id, label_id)
);

create index gitlab_project_labels_label_idx on public.gitlab_project_labels (label_id);

create table public.gitlab_milestones (
  id                 bigint primary key,            -- id do milestone no GitLab
  iid                integer     not null,
  project_id         bigint,                        -- dono, quando é milestone de projeto
  group_id           bigint,                        -- dono, quando é milestone de grupo
  title              text        not null,
  description        text,
  state              text        not null check (state in ('active', 'closed')),
  start_date         date,
  due_date           date,
  expired            boolean     not null default false,
  web_url            text,
  gitlab_created_at  timestamptz,
  gitlab_updated_at  timestamptz,
  imported_at        timestamptz not null default now(),
  updated_at         timestamptz not null default now()
);

create trigger gitlab_milestones_set_updated_at
  before update on public.gitlab_milestones
  for each row execute function public.set_updated_at();

create table public.gitlab_project_milestones (
  project_id    bigint      not null references public.gitlab_projects (id) on delete cascade,
  milestone_id  bigint      not null references public.gitlab_milestones (id) on delete cascade,
  imported_at   timestamptz not null default now(),
  primary key (project_id, milestone_id)
);

create index gitlab_project_milestones_milestone_idx on public.gitlab_project_milestones (milestone_id);

alter table public.gitlab_labels enable row level security;
alter table public.gitlab_project_labels enable row level security;
alter table public.gitlab_milestones enable row level security;
alter table public.gitlab_project_milestones enable row level security;
