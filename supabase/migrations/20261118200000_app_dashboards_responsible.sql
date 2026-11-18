-- Critério de responsável de cada dashboard (aba "Responsáveis" no configurador da Visão Gerencial EG).
-- responsible_use_assignee = true: issue com Assignee no GitLab tem como responsáveis só os assignees.
-- Sem Assignee (ou com responsible_use_assignee = false), valem as labels de responsible_labels (cada label = um desenvolvedor).
-- Os indicadores da Gerencial Fullstack não usam esta regra.
alter table public.app_dashboards
  add column responsible_use_assignee boolean not null default true,
  add column responsible_labels       text[]  not null default '{}',
  add constraint app_dashboards_responsible_check check (responsible_use_assignee or cardinality(responsible_labels) > 0);

comment on column public.app_dashboards.responsible_use_assignee is 'Visão Gerencial EG: issue com Assignee usa só os assignees como responsáveis.';
comment on column public.app_dashboards.responsible_labels is 'Visão Gerencial EG: labels (por nome) que indicam o desenvolvedor responsável, quando a issue não tem Assignee.';
