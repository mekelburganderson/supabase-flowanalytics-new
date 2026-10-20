-- Merge request com labels, revisores, 1º review, commits e discussões já agregados, para a tela de análise de MRs.
-- 1º review = primeiro comentário (Note, DiffNote, DiscussionNote) ou aprovação no MR feito por alguém que não é o autor,
-- vindo da atividade dos projetos (gitlab_project_events).
-- Revisores = revisores formais do MR + quem comentou ou aprovou (exceto o autor).

create view public.gitlab_merge_requests_v
with (security_invoker = true)
as
with reviews as (
  select e.noteable_id as merge_request_id, e.author_id, e.created_at
  from public.gitlab_project_events e
  where e.noteable_type = 'MergeRequest' and e.noteable_id is not null
  union all
  select e.target_id, e.author_id, e.created_at
  from public.gitlab_project_events e
  where e.target_type = 'MergeRequest' and e.action_name = 'approved' and e.target_id is not null
)
select m.id,
       m.iid,
       m.project_id,
       m.title,
       m.state,
       m.draft,
       m.source_branch,
       m.target_branch,
       m.author_id,
       m.milestone_id,
       m.gitlab_created_at as created_at,
       m.merged_at,
       m.closed_at,
       m.web_url,
       d.merged_by_id,
       coalesce(d.user_notes_count, 0) as discussion_count,
       coalesce((select array_agg(l.name order by l.name)
                 from public.gitlab_merge_request_labels ml
                 join public.gitlab_labels l on l.id = ml.label_id
                 where ml.merge_request_id = m.id), '{}') as label_names,
       coalesce((select array_agg(distinct u.user_id)
                 from (select r.user_id from public.gitlab_merge_request_reviewers r where r.merge_request_id = m.id
                       union
                       select rv.author_id from reviews rv
                       where rv.merge_request_id = m.id and rv.author_id is not null and rv.author_id is distinct from m.author_id) u), '{}') as reviewer_ids,
       (select min(rv.created_at) from reviews rv
        where rv.merge_request_id = m.id and rv.author_id is distinct from m.author_id) as first_review_at,
       (select rv.author_id from reviews rv
        where rv.merge_request_id = m.id and rv.author_id is distinct from m.author_id
        order by rv.created_at limit 1) as first_review_by_id,
       (select count(*)::int from public.gitlab_merge_request_commits c where c.merge_request_id = m.id) as commit_count
from public.gitlab_merge_requests m
left join public.gitlab_merge_request_details d on d.merge_request_id = m.id;

comment on view public.gitlab_merge_requests_v is 'MRs com labels, revisores, 1º review, commits e discussões, para as análises da api-flowanalytics.';

create index if not exists gitlab_project_events_noteable_idx on public.gitlab_project_events (noteable_id) where noteable_type = 'MergeRequest';
create index if not exists gitlab_project_events_mr_target_idx on public.gitlab_project_events (target_id) where target_type = 'MergeRequest';
create index if not exists gitlab_merge_requests_project_created_idx on public.gitlab_merge_requests (project_id, gitlab_created_at);
