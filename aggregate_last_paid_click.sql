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
        count(distinct visitor_id) as visitors_count,
        count(lead_id) as leads_count,
        sum(
            case
                when
                    closing_reason = 'Успешно реализовано' or status_id = 142
                    then 1
                else 0
            end
        ) as purchases_count,
        sum(amount) as revenue
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
        sum(daily_spent) as total_cost
    from ya_ads
    group by utm_source, utm_medium, utm_campaign, campaign_date
)

select
    a.visit_date,
    a.visitors_count,
    a.utm_source,
    a.utm_medium,
    a.utm_campaign,
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
    a.revenue desc nulls last,
    a.visit_date asc,
    a.visitors_count desc,
    a.utm_source asc, a.utm_medium asc, a.utm_campaign asc
limit 15;
