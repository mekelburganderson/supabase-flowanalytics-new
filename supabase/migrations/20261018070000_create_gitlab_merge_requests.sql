-- Merge requests do GitLab: dados principais (gitlab_merge_requests), detalhes (gitlab_merge_request_details)
-- e vínculos com responsáveis, revisores, labels e issues.

create table public.gitlab_merge_requests (
  id                 bigint primary key,            -- id global do MR no GitLab
  iid                integer     not null,          -- número do MR no projeto
  project_id         bigint      not null references public.gitlab_projects (id) on delete cascade,
  title              text        not null,
  description        text,
  state              text        not null check (state in ('opened', 'closed', 'merged', 'locked')),
  draft              boolean     not null default false,
  source_branch      text        not null,
  target_branch      text        not null,
  author_id          bigint      references public.gitlab_users (id) on delete set null,
  milestone_id       bigint      references public.gitlab_milestones (id) on delete set null,
  gitlab_created_at  timestamptz not null,
  gitlab_updated_at  timestamptz not null,
  merged_at          timestamptz,
  closed_at          timestamptz,
  web_url            text        not null,
  imported_at        timestamptz not null default now(),
  updated_at         timestamptz not null default now(),
  unique (project_id, iid)
);

create index gitlab_merge_requests_author_idx on public.gitlab_merge_requests (author_id);
create index gitlab_merge_requests_merged_idx on public.gitlab_merge_requests (project_id, merged_at);

create trigger gitlab_merge_requests_set_updated_at
  before update on public.gitlab_merge_requests
  for each row execute function public.set_updated_at();

create table public.gitlab_merge_request_details (
  merge_request_id       bigint primary key references public.gitlab_merge_requests (id) on delete cascade,
  state                  text        not null,
  detailed_merge_status  text,                      -- situação para merge (mergeable, not_open, conflict...)
  merge_status           text,
  has_conflicts          boolean     not null default false,
  draft                  boolean     not null default false,
  merged_by_id           bigint      references public.gitlab_users (id) on delete set null,
  closed_by_id           bigint      references public.gitlab_users (id) on delete set null,
  gitlab_created_at      timestamptz not null,
  gitlab_updated_at      timestamptz not null,
  prepared_at            timestamptz,
  merged_at              timestamptz,
  closed_at              timestamptz,
  sha                    text,
  merge_commit_sha       text,
  squash_commit_sha      text,
  squash                 boolean     not null default false,
  user_notes_count       integer     not null default 0,
  upvotes                integer     not null default 0,
  downvotes              integer     not null default 0,
  time_estimate          integer     not null default 0,  -- segundos
  total_time_spent       integer     not null default 0,  -- segundos
  imported_at            timestamptz not null default now(),
  updated_at             timestamptz not null default now()
);

create trigger gitlab_merge_request_details_set_updated_at
  before update on public.gitlab_merge_request_details
  for each row execute function public.set_updated_at();

create table public.gitlab_merge_request_assignees (
  merge_request_id  bigint not null references public.gitlab_merge_requests (id) on delete cascade,
  user_id           bigint not null references public.gitlab_users (id) on delete cascade,
  primary key (merge_request_id, user_id)
);

create table public.gitlab_merge_request_reviewers (
  merge_request_id  bigint not null references public.gitlab_merge_requests (id) on delete cascade,
  user_id           bigint not null references public.gitlab_users (id) on delete cascade,
  primary key (merge_request_id, user_id)
);

create table public.gitlab_merge_request_labels (
  merge_request_id  bigint not null references public.gitlab_merge_requests (id) on delete cascade,
  label_id          bigint not null references public.gitlab_labels (id) on delete cascade,
  primary key (merge_request_id, label_id)
);

-- Issues vinculadas ao MR. closes = o MR fecha a issue ao ser integrado; related = issue mencionada/relacionada.
-- A issue pode ser de outro projeto e ainda não estar em gitlab_issues, por isso não há chave estrangeira.
create table public.gitlab_merge_request_issues (
  merge_request_id  bigint      not null references public.gitlab_merge_requests (id) on delete cascade,
  issue_id          bigint      not null,
  issue_iid         integer     not null,
  issue_project_id  bigint      not null,
  link_type         text        not null check (link_type in ('closes', 'related')),
  primary key (merge_request_id, issue_id, link_type)
);

create index gitlab_merge_request_issues_issue_idx on public.gitlab_merge_request_issues (issue_id);
create index gitlab_merge_request_assignees_user_idx on public.gitlab_merge_request_assignees (user_id);
create index gitlab_merge_request_reviewers_user_idx on public.gitlab_merge_request_reviewers (user_id);

alter table public.gitlab_merge_requests enable row level security;
alter table public.gitlab_merge_request_details enable row level security;
alter table public.gitlab_merge_request_assignees enable row level security;
alter table public.gitlab_merge_request_reviewers enable row level security;
alter table public.gitlab_merge_request_labels enable row level security;
alter table public.gitlab_merge_request_issues enable row level security;
