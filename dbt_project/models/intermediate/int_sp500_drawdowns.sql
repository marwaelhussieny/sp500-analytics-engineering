-- Drawdown = % below the highest price seen so far. This is the metric
-- that actually communicates risk to a reader ("the index fell 57% from
-- its prior peak") in a way raw monthly returns don't.

with staged as (

    select report_month, index_price
    from {{ ref('stg_sp500_monthly') }}
    where not is_price_only_row

),

running_peak as (

    select
        *,
        max(index_price) over (
            order by report_month
            rows between unbounded preceding and current row
        ) as peak_price_to_date

    from staged

)

select
    report_month,
    index_price,
    peak_price_to_date,
    round(100.0 * (index_price - peak_price_to_date) / peak_price_to_date, 3)
        as drawdown_from_peak_pct
from running_peak
