-- Month-over-month and trailing-12-month returns, both nominal and
-- inflation-adjusted (using real_price, which Shiller already deflates).

with staged as (

    select * from {{ ref('stg_sp500_monthly') }}
    where not is_price_only_row  -- exclude FRED-extended rows: no real_price to compute inflation-adjusted returns

),

with_lags as (

    select
        *,
        lag(index_price, 1) over (order by report_month)  as prev_month_price,
        lag(real_price, 1)  over (order by report_month)  as prev_month_real_price,
        lag(index_price, 12) over (order by report_month) as price_12mo_ago

    from staged

)

select
    report_month,
    index_price,
    real_price,
    pe10,
    is_pe10_unavailable,

    round(100.0 * (index_price - prev_month_price) / nullif(prev_month_price, 0), 3)
        as monthly_return_pct,

    round(100.0 * (real_price - prev_month_real_price) / nullif(prev_month_real_price, 0), 3)
        as monthly_real_return_pct,

    round(100.0 * (index_price - price_12mo_ago) / nullif(price_12mo_ago, 0), 3)
        as trailing_12mo_return_pct

from with_lags
