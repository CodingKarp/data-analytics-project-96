-- Подзапрос находит последние визиты пользователей
with last_visits as (
    select
        l.visitor_id,
        MAX(s.visit_date) as last_visit
    from sessions as s
    left join leads as l
        on s.visitor_id = l.visitor_id and s.visit_date <= l.created_at
    where s.medium not in ('organic')
    group by l.visitor_id
)

select distinct
    s.visitor_id,
    lv.last_visit as visit_date,
    s.source as utm_source,
    s.medium as utm_medium,
    s.campaign as utm_campaign,
    l.lead_id,
    l.created_at,
    l.amount,
    l.closing_reason,
    l.status_id
from last_visits as lv
left join sessions as s
    on lv.visitor_id = s.visitor_id and lv.last_visit = s.visit_date
left join leads as l
    on s.visitor_id = l.visitor_id and s.visit_date <= l.created_at
order by
    l.amount desc nulls last,
    lv.last_visit asc,
    s.source asc,
    s.campaign asc,
    s.medium asc
limit 10;
