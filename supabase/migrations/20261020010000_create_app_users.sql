-- Usuários do FlowAnalytics (tela Usuários), usados pela api-flowanalytics.
-- A senha não fica aqui: o login é validado no endpoint da Inside. Esta tabela diz quem pode
-- entrar no FlowAnalytics (cadastrado e ativo) e quais telas cada pessoa vê.

create table public.app_users (
  id             uuid        primary key default gen_random_uuid(),
  name           text        not null check (length(btrim(name)) > 0),
  email          text        not null check (email = lower(btrim(email)) and email like '%@%'),
  active         boolean     not null default true,
  last_login_at  timestamptz,                       -- null = ainda não entrou
  created_by     text,                              -- e-mail de quem cadastrou
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);

create unique index app_users_email_key on public.app_users (email);

create trigger app_users_set_updated_at
  before update on public.app_users
  for each row execute function public.set_updated_at();

-- Telas liberadas para cada usuário. A tela é o caminho da rota no app ('/', '/merge-requests', '/usuarios'...).
create table public.app_user_screens (
  user_id  uuid  not null references public.app_users (id) on delete cascade,
  screen   text  not null,
  primary key (user_id, screen)
);

alter table public.app_users enable row level security;
alter table public.app_user_screens enable row level security;
