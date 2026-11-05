-- Comentários das issues importadas (GET /projects/:id/issues/:iid/notes do GitLab).
-- Só entram os comentários de pessoas: as notas de sistema ("adicionou a label...", "mudou o milestone...")
-- ficam de fora, pois esse histórico já vem dos eventos de label e de milestone.
-- Comentário editado no GitLab é atualizado; comentário apagado sai da tabela na próxima leitura da issue.

create table public.gitlab_issue_notes (
  id                 bigint      primary key,          -- id do comentário (note) no GitLab
  issue_id           bigint      not null references public.gitlab_issues (id) on delete cascade,
  project_id         bigint      not null references public.gitlab_projects (id) on delete cascade,
  body               text        not null,             -- texto em Markdown
  author_id          bigint      references public.gitlab_users (id) on delete set null,
  internal           boolean     not null default false, -- comentário interno (visível só para membros do projeto)
  note_type          text,                             -- null (comentário simples) ou DiscussionNote (resposta em thread)
  resolvable         boolean     not null default false,
  resolved           boolean     not null default false,
  resolved_by_id     bigint      references public.gitlab_users (id) on delete set null,
  resolved_at        timestamptz,
  gitlab_created_at  timestamptz not null,
  gitlab_updated_at  timestamptz not null,
  imported_at        timestamptz not null default now(),
  updated_at         timestamptz not null default now()
);

create index gitlab_issue_notes_issue_idx on public.gitlab_issue_notes (issue_id, gitlab_created_at);
create index gitlab_issue_notes_project_idx on public.gitlab_issue_notes (project_id, gitlab_created_at);
create index gitlab_issue_notes_author_idx on public.gitlab_issue_notes (author_id);

create trigger gitlab_issue_notes_set_updated_at
  before update on public.gitlab_issue_notes
  for each row execute function public.set_updated_at();

alter table public.gitlab_issue_notes enable row level security;

-- Até qual atualização da issue (gitlab_updated_at) os comentários já foram lidos.
-- Um comentário novo ou editado atualiza a issue no GitLab, que é lida de novo na próxima importação.
alter table public.gitlab_issues add column notes_synced_at timestamptz;
