# activeadmin_table_footer

![CI](https://github.com/activeadmin-plugins/activeadmin_table_footer/workflows/CI/badge.svg)
![Coverage](https://img.shields.io/endpoint?url=https://activeadmin-plugins.github.io/activeadmin_table_footer/badge.json)
![Ruby](https://img.shields.io/badge/ruby-3.3%2B-blue)

Adds a `<tfoot>` row to ActiveAdmin index tables. Totals are aggregated
across **all pages** of the filtered scope — not just the visible one — in a
single SQL query when you use `footer_data:`.

Works with **ActiveAdmin 3.5+ and 4.x**.

### ActiveAdmin 4

![Subscriptions index with footer totals on AA 4](https://github.com/activeadmin-plugins/activeadmin_table_footer/releases/download/assets-v1/subscriptions_with_footer_4_0.png)

### ActiveAdmin 3

![Subscriptions index with footer totals on AA 3.5](https://github.com/activeadmin-plugins/activeadmin_table_footer/releases/download/assets-v1/subscriptions_with_footer_3_5.png)

The page shows 30 rows, but the footer row reports the sum across all 42
subscriptions — that's the point.

## Install

```ruby
# Gemfile
gem "activeadmin_table_footer"
```

## Usage

```ruby
ActiveAdmin.register Subscription do
  index footer_data: ->(collection) {
          totals = collection.joins(:plan).pick(
            Arel.sql("COALESCE(SUM(seats), 0)"),
            Arel.sql("COALESCE(SUM(seats * plans.monthly_price), 0)")
          )
          { total_seats: totals[0], total_cost: totals[1] }
        } do
    column :customer
    column :plan
    column :is_operator, footer: -> { strong { "Total (all pages)" } }
    column "Seats",      footer: -> { strong { footer_data[:total_seats].to_s } }, &:seats
    column :total_cost,  footer: -> { strong { number_to_currency(footer_data[:total_cost]) } } do |row|
      number_to_currency row.total_cost
    end
  end
end
```

The `footer_data:` Proc runs once over the filtered scope (LIMIT/OFFSET/ORDER
are stripped automatically). The result is exposed inside each
`column …, footer: …` Proc via `footer_data`.

`footer:` accepts a string, a symbol (`:sum`, `:count`, `:average`,
`:minimum`, `:maximum`), or a Proc — Procs run inside the table view, so view
helpers (`number_to_currency`, `link_to`) and Arbre tags (`strong`, `span`)
work as expected.

## License

MIT
