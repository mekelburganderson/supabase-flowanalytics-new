-- Eventos dos merge requests (labels, milestone, estado), commits dos MRs, atividade dos projetos
-- (pushes, branches criadas/removidas, MRs abertos/aprovados/integrados, comentários) e branches.

-- ---------- Eventos dos MRs (resource_label_events, resource_milestone_events, resource_state_events) ----------
-- Os ids são sequências separadas por tipo no GitLab, por isso a chave inclui event_type.
create table public.gitlab_merge_request_events (
  event_type        text        not null check (event_type in ('label', 'milestone', 'state')),
  id                bigint      not null,
  merge_request_id  bigint      not null references public.gitlab_merge_requests (id) on delete cascade,
  project_id        bigint      not null references public.gitlab_projects (id) on delete cascade,
  action            text,                           -- add/remove (label e milestone)
  state             text,                           -- opened/closed/reopened/merged... (evento de estado)
  label_id          bigint      references public.gitlab_labels (id) on delete set null,
  label_name        text,
  label_color       text,
  milestone_id      bigint      references public.gitlab_milestones (id) on delete set null,
  milestone_title   text,
  user_id           bigint      references public.gitlab_users (id) on delete set null,
  created_at        timestamptz not null,
  imported_at       timestamptz not null default now(),
  primary key (event_type, id)
);

create index gitlab_merge_request_events_mr_idx on public.gitlab_merge_request_events (merge_request_id, created_at);
create index gitlab_merge_request_events_project_idx on public.gitlab_merge_request_events (project_id, created_at);

-- ---------- Commits ----------
create table public.gitlab_commits (
  project_id       bigint      not null references public.gitlab_projects (id) on delete cascade,
  sha              text        not null,
  short_id         text        not null,
  title            text        not null,
  message          text,
  author_name      text,
  author_email     text,
  author_user_id   bigint      references public.gitlab_users (id) on delete set null,  -- usuário do GitLab, quando identificado
  authored_at      timestamptz,
  committer_name   text,
  committer_email  text,
  committed_at     timestamptz,
  parent_ids       text[]      not null default '{}',
  web_url          text,
  imported_at      timestamptz not null default now(),
  primary key (project_id, sha)
);

create index gitlab_commits_author_idx on public.gitlab_commits (author_user_id, committed_at);
create index gitlab_commits_committed_idx on public.gitlab_commits (project_id, committed_at);

create table public.gitlab_merge_request_commits (
  merge_request_id  bigint not null references public.gitlab_merge_requests (id) on delete cascade,
  project_id        bigint not null,
  sha               text   not null,
  primary key (merge_request_id, sha),
  foreign key (project_id, sha) references public.gitlab_commits (project_id, sha) on delete cascade
);

-- Até qual atualização do MR (gitlab_updated_at) eventos e commits já foram lidos.
alter table public.gitlab_merge_requests add column events_synced_at timestamptz;
alter table public.gitlab_merge_requests add column commits_synced_at timestamptz;

-- ---------- Atividade dos projetos (GET /projects/:id/events) ----------
create table public.gitlab_project_events (
  id                  bigint primary key,           -- id do evento no GitLab
  project_id          bigint      not null references public.gitlab_projects (id) on delete cascade,
  action_name         text        not null,         -- pushed to, pushed new, deleted, opened, accepted, approved, commented on...
  target_type         text,                         -- MergeRequest, Issue, Note, DiffNote...; nulo em push
  target_id           bigint,
  target_iid          bigint,
  target_title        text,
  author_id           bigint      references public.gitlab_users (id) on delete set null,
  -- push
  push_action         text,                         -- pushed, created, removed
  push_ref_type       text,                         -- branch, tag
  push_ref            text,                         -- nome da branch/tag
  push_commit_count   integer,
  push_commit_from    text,
  push_commit_to      text,
  push_commit_title   text,
  -- comentário
  note_id             bigint,
  noteable_type       text,                         -- MergeRequest, Issue...
  noteable_id         bigint,
  noteable_iid        bigint,
  note_body           text,
  created_at          timestamptz not null,
  imported_at         timestamptz not null default now()
);

create index gitlab_project_events_project_idx on public.gitlab_project_events (project_id, created_at);
create index gitlab_project_events_author_idx on public.gitlab_project_events (author_id, created_at);
create index gitlab_project_events_ref_idx on public.gitlab_project_events (project_id, push_ref) where push_ref is not null;

-- ---------- Branches (situação atual de cada projeto) ----------
create table public.gitlab_branches (
  project_id                bigint      not null references public.gitlab_projects (id) on delete cascade,
  name                      text        not null,
  merged                    boolean     not null default false,
  protected                 boolean     not null default false,
  is_default                boolean     not null default false,
  developers_can_push       boolean     not null default false,
  developers_can_merge      boolean     not null default false,
  last_commit_sha           text,
  last_commit_title         text,
  last_commit_author_name   text,
  last_commit_author_email  text,
  last_commit_at            timestamptz,
  web_url                   text,
  imported_at               timestamptz not null default now(),
  primary key (project_id, name)
);

alter table public.gitlab_merge_request_events enable row level security;
alter table public.gitlab_commits enable row level security;
alter table public.gitlab_merge_request_commits enable row level security;
alter table public.gitlab_project_events enable row level security;
alter table public.gitlab_branches enable row level security;
