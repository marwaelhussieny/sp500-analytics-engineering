-- One row per decade: average valuation, average return, and worst
-- drawdown. Good for a "what actually happened each decade" dashboard table.

select
    cast((extract(year from report_month)::int / 10) * 10 as int) as decade,
    round(avg(pe10) filter (where not is_pe10_unavailable and not is_price_only_row), 2) as avg_pe10,
    round(avg(monthly_return_pct), 3)  as avg_monthly_return_pct,
    round(min(drawdown_from_peak_pct), 2) as worst_drawdown_pct,
    count(*) as months_recorded
from {{ ref('fct_sp500_monthly') }}
group by 1
order by 1
