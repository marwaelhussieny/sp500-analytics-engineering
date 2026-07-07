-- Classifies each month into a valuation quintile based on where its PE10
-- (Shiller CAPE) sits relative to the full historical distribution, then
-- reports the average subsequent 12-month return for each quintile. This is
-- the classic "does high CAPE predict lower forward returns?" analysis,
-- entirely reproducible from the fact table above.

with eligible as (

    select
        f.report_month,
        f.pe10,
        f.trailing_12mo_return_pct
    from {{ ref('fct_sp500_monthly') }} f
    where not f.is_price_only_row and not f.is_pe10_unavailable

),

quintiles as (

    select
        *,
        ntile(5) over (order by pe10) as pe10_quintile
    from eligible

)

select
    pe10_quintile,
    min(pe10)                              as pe10_min,
    max(pe10)                              as pe10_max,
    round(avg(pe10), 2)                    as pe10_avg,
    count(*)                               as months_in_quintile,
    round(avg(trailing_12mo_return_pct), 2) as avg_trailing_12mo_return_pct
from quintiles
group by pe10_quintile
order by pe10_quintile
