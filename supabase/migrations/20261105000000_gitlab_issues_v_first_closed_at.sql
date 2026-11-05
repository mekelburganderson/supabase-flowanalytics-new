-- Primeiro fechamento das issues, para os filtros e as análises da api-flowanalytics.
-- O closed_at do GitLab é o fechamento mais recente: issue reaberta e fechada de novo "muda de data".
-- O primeiro fechamento vem do evento "closed" mais antigo da issue nos eventos de projeto
-- (target_type Issue ou WorkItem, target_id = id da issue); sem evento (issues antigas), vale o closed_at.
-- Issue reaberta e ainda aberta fica sem data de fechamento (null), como antes.

create index if not exists gitlab_project_events_issue_closed_idx
  on public.gitlab_project_events (target_id, created_at)
  where action_name = 'closed' and target_type in ('Issue', 'WorkItem');

create or replace view public.gitlab_issues_v
with (security_invoker = true)
as
select i.id,
       i.iid,
       i.project_id,
       i.title,
       i.state,
       i.milestone_id,
       i.gitlab_created_at as created_at,
       i.closed_at,
       i.web_url,
       coalesce((select array_agg(l.name order by l.name)
                 from public.gitlab_issue_labels il
                 join public.gitlab_labels l on l.id = il.label_id
                 where il.issue_id = i.id), '{}') as label_names,
       coalesce((select array_agg(a.user_id order by a.user_id)
                 from public.gitlab_issue_assignees a
                 where a.issue_id = i.id), '{}') as assignee_ids,
       case when i.state = 'closed' then
         least(i.closed_at, (select min(e.created_at)
                             from public.gitlab_project_events e
                             where e.target_id = i.id
                               and e.action_name = 'closed'
                               and e.target_type in ('Issue', 'WorkItem')))
       end as first_closed_at
from public.gitlab_issues i;

comment on view public.gitlab_issues_v is 'Issues com nomes das labels, ids dos responsáveis e o primeiro fechamento (first_closed_at), para as análises da api-flowanalytics.';
comment on column public.gitlab_issues_v.first_closed_at is 'Primeiro fechamento da issue fechada (evento "closed" mais antigo ou closed_at); null se aberta.';
