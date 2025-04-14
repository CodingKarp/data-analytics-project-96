with last_visits as (
    select
        visitor_id,
        MAX(visit_date) as last_visit
    from sessions
    group by 1
)
select distinct
    s.visitor_id,
    lv.last_visit as visit_date,
    s.source as utm_source,
    s.medium as utm_medium,
    s.campaign as utm_campaign,
    l.created_at,
    l.amount,
    l.closing_reason,
    l.status_id
from sessions as s
inner join last_visits as lv
    on s.visitor_id = lv.visitor_id
left join leads as l
    on s.visitor_id = l.visitor_id
where s.medium not in ('social', 'organic')
order by
    amount desc nulls last, visit_date asc, utm_source asc, utm_campaign asc, utm_medium asc;
