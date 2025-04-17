select count visitor_id as num_of_visitors from sessions;
-- кол-во уникальных пользователей 
select count (distinct visitor_id) as num_of_visitors from sessions; 
-- источник лидов по дням 
with last_visits as (
    select
        s.visitor_id,
        max(s.visit_date) as last_visit
    from sessions as s
    where s.medium not in ('organic')
    group by 1
),
last_paid_click as (
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
    from sessions as s
    inner join last_visits as lv
        on s.visitor_id = lv.visitor_id and s.visit_date = lv.last_visit
    left join leads as l
        on s.visitor_id = l.visitor_id and s.visit_date <= l.created_at
    order by
        amount desc nulls last,
        visit_date asc,
        utm_source asc,
        utm_campaign asc,
        utm_medium asc
)
select
    to_char(visit_date, 'day') as visit_day,
    utm_source,
    count(*) as source_count
from last_paid_click
group by 1, 2
order by
    min((cast(extract(dow from visit_date) as int) + 6) % 7),
    utm_source;
-- источник лидов по неделям 
with last_visits as (
    select
        s.visitor_id,
        max(s.visit_date) as last_visit
    from sessions as s
    where s.medium not in ('organic')
    group by 1
),

last_paid_click as (
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
    from sessions as s
    inner join last_visits as lv
        on s.visitor_id = lv.visitor_id and s.visit_date = lv.last_visit
    left join leads as l
        on s.visitor_id = l.visitor_id and s.visit_date <= l.created_at
    order by
        amount desc nulls last,
        visit_date asc,
        utm_source asc,
        utm_campaign asc,
        utm_medium asc
)

select
    to_char(visit_date, 'w') as visit_week,
    utm_source,
    count(*) as source_count
from last_paid_click
group by 1, 2
order by 1, 2;
-- источник лидов по месяцам
with last_visits as (
    select
        s.visitor_id,
        max(s.visit_date) as last_visit
    from sessions as s
    where s.medium not in ('organic')
    group by 1
),

last_paid_click as (
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
    from sessions as s
    inner join last_visits as lv
        on s.visitor_id = lv.visitor_id and s.visit_date = lv.last_visit
    left join leads as l
        on s.visitor_id = l.visitor_id and s.visit_date <= l.created_at
    order by
        amount desc nulls last,
        visit_date asc,
        utm_source asc,
        utm_campaign asc,
        utm_medium asc
)

select
    to_char(visit_date, 'mm') as visit_month,
    utm_source,
    count(*) as source_count
from last_paid_click
group by 1, 2
order by 1, 2;
-- количество лидов 
select count(lead_id) as lead_count from leads;






