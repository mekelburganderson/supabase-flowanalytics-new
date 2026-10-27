-- Sincronização com o GitLab (api-flowanalytics, /sincronizacao): agendamento da execução automática
-- (configurado em Configurações gerais) e histórico das execuções, manuais e agendadas.

-- Uma linha só. Horários em Brasília; a execução acontece nas horas cheias de start_hour a end_hour,
-- a cada interval_hours a partir de start_hour, nos dias da semana de weekdays (0 = domingo ... 6 = sábado).
create table public.app_sync_schedule (
  id              smallint    primary key default 1 check (id = 1),
  enabled         boolean     not null default true,
  interval_hours  smallint    not null default 1 check (interval_hours between 1 and 24),
  start_hour      smallint    not null default 7 check (start_hour between 0 and 23),
  end_hour        smallint    not null default 20 check (end_hour between 0 and 23),
  weekdays        smallint[]  not null default '{1,2,3,4,5}',
  updated_by      text,
  updated_at      timestamptz not null default now(),
  check (end_hour >= start_hour),
  check (weekdays <@ '{0,1,2,3,4,5,6}')
);

insert into public.app_sync_schedule (id) values (1);

create trigger app_sync_schedule_set_updated_at
  before update on public.app_sync_schedule
  for each row execute function public.set_updated_at();

-- Uma linha por execução. finished_at nulo = em andamento (ou interrompida, se for antiga).
create table public.app_sync_runs (
  id           bigint      generated always as identity primary key,
  trigger      text        not null check (trigger in ('manual', 'agendada')),
  started_by   text,
  started_at   timestamptz not null default now(),
  finished_at  timestamptz,
  success      boolean,
  projects     int,
  steps        jsonb       -- resultado de cada etapa: [{ step, seconds, result, error }]
);

create index app_sync_runs_started_at_idx on public.app_sync_runs (started_at desc);

alter table public.app_sync_schedule enable row level security;
alter table public.app_sync_runs enable row level security;
