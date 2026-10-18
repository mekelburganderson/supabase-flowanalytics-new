-- Labels de grupo passam a guardar o grupo dono, para busca por grupo.
-- Milestones já têm group_id.

alter table public.gitlab_labels add column group_id bigint;

comment on column public.gitlab_labels.group_id is 'Grupo dono, quando é label de grupo (preenchido pela importação por grupo).';

create index gitlab_labels_group_idx on public.gitlab_labels (group_id) where group_id is not null;
create index gitlab_milestones_group_idx on public.gitlab_milestones (group_id) where group_id is not null;
