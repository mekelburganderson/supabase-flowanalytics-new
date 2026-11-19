-- Gestão de Pessoal (telas Colaboradores e Ausências), usada pela api-flowanalytics.
-- Colaboradores cadastrados no FlowAnalytics (não são os usuários do GitLab) e as ausências deles:
-- férias, folga ou atestado, com período e observação.
-- Sem dados de exemplo: as tabelas começam vazias.

create table public.app_employees (
  id          uuid        primary key default gen_random_uuid(),
  name        text        not null check (length(btrim(name)) > 0),
  job_title   text,                                  -- função
  hire_date   date,                                  -- data de admissão
  email       text,
  phone       text,
  active      boolean     not null default true,     -- inativo não aparece para novas ausências
  created_by  text,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

create index app_employees_name_idx on public.app_employees (active desc, name);

create trigger app_employees_set_updated_at
  before update on public.app_employees
  for each row execute function public.set_updated_at();

-- Período fechado: start_date e end_date contam como dias de ausência.
-- O colaborador com ausência não pode ser removido (on delete restrict): só inativado.
create table public.app_absences (
  id           uuid        primary key default gen_random_uuid(),
  employee_id  uuid        not null references public.app_employees (id) on delete restrict,
  type         text        not null check (type in ('ferias', 'folga', 'atestado')),
  start_date   date        not null,
  end_date     date        not null,
  notes        text        not null default '',
  created_by   text,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),
  check (end_date >= start_date)
);

create index app_absences_period_idx on public.app_absences (start_date, end_date);
create index app_absences_employee_idx on public.app_absences (employee_id, start_date);

create trigger app_absences_set_updated_at
  before update on public.app_absences
  for each row execute function public.set_updated_at();

alter table public.app_employees enable row level security;
alter table public.app_absences enable row level security;
