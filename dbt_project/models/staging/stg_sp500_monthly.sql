with source as (

    select * from {{ ref('sp500_shiller_raw') }}

),

renamed as (

    select
        "Date"                      as report_month,
        "SP500"                     as index_price,
        "Dividend"                  as dividend,
        "Earnings"                  as earnings,
        "Consumer Price Index"      as cpi,
        "Long Interest Rate"        as long_interest_rate,
        "Real Price"                as real_price,
        "Real Dividend"             as real_dividend,
        "Real Earnings"             as real_earnings,
        "PE10"                      as pe10

    from source

),

flagged as (

    select
        *,
        -- From 2023-07 onward, the source extends the series using only the
        -- FRED index price. Fundamentals (dividend, earnings, CPI, PE10) are
        -- not available for these rows and are populated as 0 upstream —
        -- flag them so marts don't silently treat 0 as a real value.
        (cpi = 0 and dividend = 0 and earnings = 0) as is_price_only_row,

        -- PE10 (Shiller CAPE) requires 10 years of trailing real earnings,
        -- unavailable for the first ~120 months of the series (1871-1880).
        (pe10 = 0 and not (cpi = 0 and dividend = 0 and earnings = 0)) as is_pe10_unavailable

    from renamed

)

select * from flagged
