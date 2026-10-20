-- Issue com as labels (nomes) e os responsáveis (ids) já agregados, para as telas de análise.
-- Os cálculos (lead time em dias úteis, medianas, etapas e tipos) ficam na api-flowanalytics.

create view public.gitlab_issues_v
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
                 where a.issue_id = i.id), '{}') as assignee_ids
from public.gitlab_issues i;

comment on view public.gitlab_issues_v is 'Issues com nomes das labels e ids dos responsáveis, para as análises da api-flowanalytics.';

create index if not exists gitlab_issues_project_closed_idx on public.gitlab_issues (project_id, closed_at);
create index if not exists gitlab_issues_project_created_idx on public.gitlab_issues (project_id, gitlab_created_at);
create index if not exists gitlab_issues_project_state_idx on public.gitlab_issues (project_id, state);
