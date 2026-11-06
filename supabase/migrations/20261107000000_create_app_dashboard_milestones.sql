-- Milestones de cada dashboard (aba "Milestones" em Configurações > Dashboards).
-- Filtram só as issues CONCLUÍDAS na Visão geral (substituem o filtro de milestone da barra).
-- Nenhuma linha = todas as milestones (sem filtro).
create table public.app_dashboard_milestones (
  dashboard_id  uuid    not null references public.app_dashboards (id) on delete cascade,
  milestone_id  bigint  not null,                 -- id do milestone no GitLab (gitlab_milestones.id)
  primary key (dashboard_id, milestone_id)
);

alter table public.app_dashboard_milestones enable row level security;
