---
title: S&P 500 Historical Analytics (1871–present)
---

Built entirely with **dbt** models on **DuckDB**, visualized here with **Evidence**.
Source: [Robert Shiller's dataset](https://github.com/datasets/s-and-p-500) (public domain, PDDL).

```sql monthly
select * from sp500.fct_sp500_monthly
where not is_price_only_row
order by report_month
```

<BigValue
    data={monthly.slice(-1)}
    value=index_price
    title="Latest index level"
    fmt="#,##0.00"
/>

<BigValue
    data={monthly.slice(-1)}
    value=pe10
    title="Current Shiller CAPE (PE10)"
    fmt="#,##0.0"
/>

```sql worst_drawdown
select report_month, drawdown_from_peak_pct
from sp500.fct_sp500_monthly
where not is_price_only_row
order by drawdown_from_peak_pct asc
limit 1
```

<BigValue
    data={worst_drawdown}
    value=drawdown_from_peak_pct
    title="Worst drawdown ever recorded"
    fmt="#,##0.0'%'"
/>

## Price history

<LineChart
    data={monthly}
    x=report_month
    y=index_price
    yScale=log
    title="S&P 500 index level (log scale)"
/>

## Drawdowns from all-time peak

<AreaChart
    data={monthly}
    x=report_month
    y=drawdown_from_peak_pct
    title="Drawdown from prior peak (%)"
/>

## Valuation vs. forward returns

Does a high CAPE ratio actually predict lower forward returns? Grouping every
month into a valuation quintile (1 = cheapest, 5 = most expensive) and
averaging the following 12-month return for each group:

```sql valuation
select * from sp500.mart_valuation_quintiles
order by pe10_quintile
```

<BarChart
    data={valuation}
    x=pe10_quintile
    y=avg_trailing_12mo_return_pct
    title="Avg trailing 12-month return by valuation quintile"
/>

<DataTable data={valuation} />

## Decade-by-decade summary

```sql decades
select * from sp500.mart_decade_summary
order by decade desc
```

<DataTable data={decades} rows=20>
    <Column id=decade/>
    <Column id=avg_pe10 title="Avg CAPE"/>
    <Column id=avg_monthly_return_pct title="Avg monthly return %"/>
    <Column id=worst_drawdown_pct title="Worst drawdown %"/>
    <Column id=months_recorded title="Months recorded"/>
</DataTable>
