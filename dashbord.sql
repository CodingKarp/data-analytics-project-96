-- общее число посещение
select count visitor_id as num_of_visitors from sessions;
-- кол-во уникальных пользователей 
select count (distinct visitor_id) as num_of_visitors from sessions; 
-- 
with last_visits as (
    select
        l.visitor_id,
        MAX(s.visit_date) as last_visit
    from sessions as s
    left join leads as l
        on s.visitor_id = l.visitor_id and s.visit_date <= l.created_at
    where s.medium not in ('organic')
    group by 1
)
last_paid as (
select 
    s.visitor_id,
    lv.last_visit as visit_date,
    s.source as utm_source,
    s.medium as utm_medium,
    s.campaign as utm_campaign,
    l.created_at,
    l.amount,
    l.closing_reason,
    l.status_id
from last_visits as lv
left join sessions as s
    on lv.visitor_id = s.visitor_id and lv.last_visit = s.visit_date
left join leads as l
    on s.visitor_id = l.visitor_id
order by
    amount desc nulls last,
    visit_date asc,
    utm_source asc,
    utm_campaign asc,
    utm_medium asc
)
select
    extract(day from visit_date) as visit_day,
    utm_source, 
    count(utm_source) as source_count   
from last_paid 
group by 1, 2 
order by 1, 2;




