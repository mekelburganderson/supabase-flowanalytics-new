-- Fluxo do kanban de cada dashboard (aba "Fluxo do kanban" em Configurações > Dashboards).
-- Separado de app_dashboard_labels (etapas "fazendo" e tipos): a mesma label pode estar
-- nas etapas e também no backlog ou no fluxo total.
--   backlog = labels em que a issue espera para ser trabalhada (ex.: Avaliação, To Do)
--   flow    = sequência do kanban do backlog a fazer até a conclusão (fechamento da issue)
create table public.app_dashboard_kanban_labels (
  dashboard_id  uuid     not null references public.app_dashboards (id) on delete cascade,
  kind          text     not null check (kind in ('backlog', 'flow')),
  label_name    text     not null,
  position      integer  not null,                 -- ordem dentro da lista (0, 1, 2...)
  primary key (dashboard_id, kind, label_name)
);

create index app_dashboard_kanban_labels_order_idx on public.app_dashboard_kanban_labels (dashboard_id, kind, position);

alter table public.app_dashboard_kanban_labels enable row level security;
