-- Escopo de cada dashboard: 'analysis' (telas da seção Análise) ou 'management' (Visão Gerencial).
-- Os dashboards da Visão Gerencial ficam isolados: não aparecem no seletor da Análise
-- nem podem ser usados nos indicadores dela. Os dashboards que já existem continuam em 'analysis'.
alter table public.app_dashboards
  add column scope text not null default 'analysis' check (scope in ('analysis', 'management'));

comment on column public.app_dashboards.scope is 'analysis = telas da seção Análise; management = Visão Gerencial (isolados dos indicadores da Análise).';

create index app_dashboards_scope_idx on public.app_dashboards (scope, position);

-- As telas novas (/visao-gerencial e /configuracoes/visao-gerencial) são liberadas por usuário em Usuários.
