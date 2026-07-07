-- The single wide table a BI tool or dashboard should query for anything
-- month-level: price, returns, drawdown, and valuation all in one row.

with base as (

    select * from {{ ref('stg_sp500_monthly') }}

),

returns as (

    select * from {{ ref('int_sp500_returns') }}

),

drawdowns as (

    select * from {{ ref('int_sp500_drawdowns') }}

)

select
    base.report_month,
    base.index_price,
    base.dividend,
    base.earnings,
    base.pe10,
    base.is_price_only_row,
    base.is_pe10_unavailable,
    returns.monthly_return_pct,
    returns.monthly_real_return_pct,
    returns.trailing_12mo_return_pct,
    drawdowns.drawdown_from_peak_pct

from base
left join returns   on base.report_month = returns.report_month
left join drawdowns on base.report_month = drawdowns.report_month
order by base.report_month
