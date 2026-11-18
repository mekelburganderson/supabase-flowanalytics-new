-- Regra de conclusão de cada dashboard (aba "Conclusão" no configurador da Visão Gerencial EG).
-- A issue conta como concluída quando:
--   completion_on_close = true e a issue está fechada (closed), OU
--   tem alguma das labels de completion_labels, mesmo aberta.
-- Os dashboards que já existem ficam com a regra atual (só fechada). Os indicadores da Gerencial Fullstack não usam esta regra.
alter table public.app_dashboards
  add column completion_on_close boolean not null default true,
  add column completion_labels   text[]  not null default '{}',
  add constraint app_dashboards_completion_check check (completion_on_close or cardinality(completion_labels) > 0);

comment on column public.app_dashboards.completion_on_close is 'Visão Gerencial EG: issue fechada (closed) conta como concluída.';
comment on column public.app_dashboards.completion_labels is 'Visão Gerencial EG: labels (por nome) que marcam a issue como concluída, mesmo aberta.';
