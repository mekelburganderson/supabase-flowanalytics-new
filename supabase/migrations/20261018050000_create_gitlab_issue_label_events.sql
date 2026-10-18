-- Eventos de label das issues (resource_label_events do GitLab): quando cada label foi adicionada ou removida.

create table public.gitlab_issue_label_events (
  id           bigint primary key,                  -- id do evento no GitLab
  issue_id     bigint      not null references public.gitlab_issues (id) on delete cascade,
  project_id   bigint      not null references public.gitlab_projects (id) on delete cascade,
  action       text        not null check (action in ('add', 'remove')),
  label_id     bigint      references public.gitlab_labels (id) on delete set null,
  label_name   text,                                -- nome e cor no momento da importação (a label pode ter sido apagada)
  label_color  text,
  user_id      bigint      references public.gitlab_users (id) on delete set null,
  created_at   timestamptz not null,                -- quando a alteração aconteceu no GitLab
  imported_at  timestamptz not null default now()
);

create index gitlab_issue_label_events_issue_idx on public.gitlab_issue_label_events (issue_id, created_at);
create index gitlab_issue_label_events_project_idx on public.gitlab_issue_label_events (project_id, created_at);
create index gitlab_issue_label_events_label_idx on public.gitlab_issue_label_events (label_id);

alter table public.gitlab_issue_label_events enable row level security;

-- Até qual atualização da issue (gitlab_updated_at) os eventos de label já foram lidos.
-- Issue alterada depois disso tem os eventos lidos de novo na próxima importação.
alter table public.gitlab_issues add column label_events_synced_at timestamptz;
