-- Análises com IA da Visão geral (api-flowanalytics, POST /analise/visao-geral/ia): cada análise gerada fica registrada
-- com quem gerou, quando, os filtros usados e o resultado completo. Listar e ver exigem a tela Visão geral;
-- gerar e remover exigem a permissão /analise-ia.

create table public.app_ai_analyses (
  id              bigint      generated always as identity primary key,
  created_at      timestamptz not null default now(),          -- data e hora da geração
  user_id         uuid        references public.app_users (id) on delete set null,
  user_name       text        not null,                        -- nome e e-mail na época (o usuário pode ser removido)
  user_email      text        not null,
  dashboard_id    uuid        references public.app_dashboards (id) on delete set null,
  dashboard_name  text        not null,
  scope_label     text        not null,                        -- recorte exibido (ex.: "Últimos 30 dias · Milestone X")
  filters         jsonb       not null,                        -- { dashboardId, dashboardName, preset, start, end, label, projects, users, milestones }
  model           text        not null,
  input_tokens    int,
  output_tokens   int,
  result          jsonb       not null                         -- resposta do POST /analise/visao-geral/ia
);

create index app_ai_analyses_created_at_idx on public.app_ai_analyses (created_at desc);
create index app_ai_analyses_dashboard_idx on public.app_ai_analyses (dashboard_id, created_at desc);

alter table public.app_ai_analyses enable row level security;
