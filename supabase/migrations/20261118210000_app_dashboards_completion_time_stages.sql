-- Etapas que formam o "tempo de conclusão" das issues na Visão Gerencial EG (aba "Conclusão").
-- O tempo de conclusão é a soma do tempo útil em que a issue ficou nessas etapas até a data de conclusão.
-- Vazio = todas as etapas "fazendo" do dashboard (comportamento anterior).
alter table public.app_dashboards
  add column completion_time_stages text[] not null default '{}';

comment on column public.app_dashboards.completion_time_stages is 'Visão Gerencial EG: etapas (labels) somadas no tempo de conclusão; vazio = todas as etapas do dashboard.';
