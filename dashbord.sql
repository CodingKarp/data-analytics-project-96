-- общее число пользователей 
select count(visitor_id) as num_of_visitors from sessions;
-- кол-во уникальных пользователей 
select count (distinct visitor_id) as unique_visitors from sessions; 
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

-- конверсия визит -> лид -> покупка
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
        l.lead_id,
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
        l.amount desc nulls last,
        s.visit_date asc,
        s.source asc,
        s.campaign asc,
        s.medium asc
),

visit_lead_purchase as (
    select
        count(distinct visitor_id) as visitors_count,
        count(distinct lead_id) as leads_count,
        sum(
            case
                when
                    closing_reason = 'успешно реализовано' or status_id = 142
                    then 1
                else 0
            end
        ) as purchases_count
    from last_paid_click
)

select
    round(leads_count * 100.00 / visitors_count, 2) as visit_to_lead,
    round(purchases_count * 100.00 / leads_count, 2) as lead_to_purchase
from visit_lead_purchase;

-- расходы по каждому каналу по неделям 
select
    'vk' as source,
    to_char(campaign_date, 'w'),
    sum(daily_spent),
    sum(revenue)
from vk_ads
group by 1, 2

union

select
    'ya' as source,
    to_char(campaign_date, 'w'),
    sum(daily_spent)
from ya_ads
group by 1, 2
order by 2;

-- окуппаемость канналов 
with cost as (
select
    'vk' as source,
    sum(daily_spent) as total_spent
from vk_ads
group by 1

union

select
    'ya' as source,
    sum(daily_spent) as total_spent
from ya_ads
group by 1
), 
revenue as ( 
select 
	'vk' as source, 
	sum(l.amount) as total_revenue
from leads as l 
inner join sessions as s 
	on l.visitor_id = s.visitor_id and source = 'vk'
	
union 

select 
	'ya' as source, 
	sum(l.amount) as total_revenue
from leads as l 
inner join sessions s 
	on l.visitor_id = s.visitor_id and source = 'yandex'
)
select 
	c.source,
	r.total_revenue as total_revenue,
	c.total_spent as total_spent, 
	r.total_revenue - c.total_spent as profit
from cost as c
inner join revenue as r using(source); 

-- основные метрики 
with last_visits as (
    select
        s.visitor_id,
        MAX(s.visit_date) as last_visit
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
        l.lead_id,
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
        l.amount desc nulls last,
        s.visit_date asc,
        s.source asc,
        s.campaign asc,
        s.medium asc
),

aggregation as (
    select
        visit_date::date,
        utm_source,
        utm_medium,
        utm_campaign,
        COUNT(visitor_id) as visitors_count,
        COUNT(lead_id) as leads_count,
        SUM(
            case
                when
                    closing_reason = 'Успешно реализовано' or status_id = 142
                    then 1
                else 0
            end
        ) as purchases_count,
        SUM(amount) as revenue
    from last_paid_click
    group by
        visit_date::date,
        utm_source,
        utm_medium,
        utm_campaign
),

ad_costs as (
    select
        utm_source,
        utm_medium,
        utm_campaign,
        campaign_date,
        SUM(daily_spent) as total_cost
    from vk_ads
    group by utm_source, utm_medium, utm_campaign, campaign_date
    union all
    select
        utm_source,
        utm_medium,
        utm_campaign,
        campaign_date,
        SUM(daily_spent) as total_cost
    from ya_ads
    group by utm_source, utm_medium, utm_campaign, campaign_date
),

aggregate_last_paid_click as (
    select
        a.visit_date,
        a.utm_source,
        a.utm_medium,
        a.utm_campaign,
        a.visitors_count,
        ac.total_cost,
        a.leads_count,
        a.purchases_count,
        a.revenue
    from aggregation as a
    left join ad_costs as ac
        on
            a.visit_date = ac.campaign_date::date
            and a.utm_source = ac.utm_source
            and a.utm_medium = ac.utm_medium
            and a.utm_campaign = ac.utm_campaign
    order by
        revenue desc nulls last,
        visit_date asc,
        visitors_count desc,
        utm_source asc, utm_medium asc, utm_campaign asc
)

select
    utm_source as source,
    utm_medium as medium, 
    utm_campaign as campaign
    case
        when
            sum(visitors_count) > 0
            then round(sum(total_cost) / sum(visitors_count), 2)
        else 0
    end as cpu,
    case
        when
            sum(leads_count) > 0
            then round(sum(total_cost) / sum(leads_count), 2)
        else 0
    end as cpl,
    case
        when
            sum(purchases_count) > 0
            then round(sum(total_cost) / sum(purchases_count), 2)
        else 0
    end as cppu,
    case
        when
            sum(total_cost) > 0
            then
                round(
                    (sum(revenue) - sum(total_cost)) * 100.0 / sum(total_cost),
                    2
                )
        else 0
    end as roi
from aggregate_last_paid_click
where utm_source in ('vk', 'yandex')
group by 1, 2, 3
order by 1;











