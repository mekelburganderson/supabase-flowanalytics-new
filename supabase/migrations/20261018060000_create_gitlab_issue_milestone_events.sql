-- Eventos de milestone das issues (resource_milestone_events do GitLab): quando a issue entrou ou saiu de um milestone.

create table public.gitlab_issue_milestone_events (
  id               bigint primary key,              -- id do evento no GitLab
  issue_id         bigint      not null references public.gitlab_issues (id) on delete cascade,
  project_id       bigint      not null references public.gitlab_projects (id) on delete cascade,
  action           text        not null check (action in ('add', 'remove')),
  milestone_id     bigint      references public.gitlab_milestones (id) on delete set null,
  milestone_title  text,                            -- título no momento da importação (o milestone pode ter sido apagado)
  issue_state      text,                            -- estado da issue quando o evento aconteceu
  user_id          bigint      references public.gitlab_users (id) on delete set null,
  created_at       timestamptz not null,            -- quando a alteração aconteceu no GitLab
  imported_at      timestamptz not null default now()
);

create index gitlab_issue_milestone_events_issue_idx on public.gitlab_issue_milestone_events (issue_id, created_at);
create index gitlab_issue_milestone_events_project_idx on public.gitlab_issue_milestone_events (project_id, created_at);
create index gitlab_issue_milestone_events_milestone_idx on public.gitlab_issue_milestone_events (milestone_id);

alter table public.gitlab_issue_milestone_events enable row level security;

-- Até qual atualização da issue (gitlab_updated_at) os eventos de milestone já foram lidos.
alter table public.gitlab_issues add column milestone_events_synced_at timestamptz;
