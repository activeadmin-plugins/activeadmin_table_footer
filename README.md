# activeadmin_table_footer

Adds a `<tfoot>` row to ActiveAdmin index tables with a clean per-column DSL
and an optional single-query aggregate (`footer_data`) shared across cells.

**Compatible with ActiveAdmin 3.5+ and 4.x.**

## Why

Real-world admin tables for billing, subscriptions, orders, inventory often
need a totals row at the bottom:

| | Customer | Plan | Seats | Total Cost |
|---|---|---|---|---|
| | Acme   | Basic | 10 | $100.00 |
| | Globex | Pro   | 7  | $175.00 |
| **Total** | | | **17** | **$275.00** |

The naive workaround — one `Proc` per column that calls `collection.sum(:x)` —
produces N SQL queries (one per footer cell). This gem solves both problems:

1. **DSL**: `column :amount, footer: -> { ... }` — declarative, lives next to
   the column it footers.
2. **One query**: `index footer_data: ->(c) { ... }` runs once and exposes the
   result inside every `footer:` proc as the `footer_data` method.

## Installation

```ruby
# Gemfile
gem "activeadmin_table_footer"
```

The gem auto-registers via a Rails engine — no initializer needed unless you
want to override styles.

## Usage

### Minimal (per-column aggregates)

```ruby
ActiveAdmin.register Order do
  index do
    column :customer
    column :placed_at
    column :amount, footer: :sum     # → collection.sum(:amount)
    column :tax,    footer: :sum
    column :status, footer: -> { strong { "All Orders" } }
  end
end
```

### Production (single SQL for all aggregates)

The `collection` passed into both `footer_data:` and `column ... footer:` Procs
is automatically stripped of `LIMIT / OFFSET / ORDER BY` so aggregates cover
**all filtered rows** across every page, not just the visible 30.

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
    column "Seats", footer: -> { strong { footer_data[:total_seats].to_s } }, &:seats
    column :total_cost,
           footer: -> { strong { number_to_currency(footer_data[:total_cost]) } } do |row|
      number_to_currency row.total_cost
    end
  end
end
```

One SQL query computes both `SUM(seats)` and `SUM(seats × plans.monthly_price)`;
each `footer:` Proc reads from `footer_data` instead of querying again.

The footer **reflects active filters** — Ransack-narrowed `collection` is the
one passed to `footer_data:`. Filter by customer, plan, status → totals update.

## DSL

### `index footer_data: <Proc>`

A Proc that receives the **filtered, un-paginated** collection (the AA-scoped
relation with `LIMIT / OFFSET / ORDER BY` stripped) and returns any value
(Hash, Array, OpenStruct). The return value is memoized for the request and
exposed inside every `footer:` Proc as the `footer_data` method.

### `column …, footer: <value>`

| `footer:` value | Behavior |
|---|---|
| `String` / Numeric | Rendered as-is (`footer.to_s`) |
| `Symbol` (`:sum`, `:count`, `:average`, `:minimum`, `:maximum`) | AR relation → one SQL per cell (use sparingly; prefer `footer_data:`). Plain Array → Ruby `Enumerable` equivalent (nil-safe). |
| `Proc` (arity 0) | `instance_exec`'d in the table view. View helpers (`number_to_currency`, `l`, `link_to`), Arbre tags (`strong`, `span`), and `footer_data` all work. |
| `Proc` (arity 1) | `instance_exec`'d with the unscoped collection as argument. |
| `Arbre::Element` | Inserted directly (e.g. `column footer: ->{ link_to('Export', export_path) }`) |

### Plain-Array collections

`table_for` can be invoked with a hand-rolled Array (in a custom panel, `show`
page, etc.) rather than an AR relation. All footer forms work in both modes —
`Symbol` aggregators auto-fall back to `Enumerable` when the collection is not
an AR relation:

```ruby
items = [
  Item.new(name: "Widget",   qty: 10, price: 5),
  Item.new(name: "Gadget",   qty: 4,  price: 20),
  Item.new(name: "Sprocket", qty: 6,  price: 12)
]

table_for items do
  column :name,  footer: -> { strong { "Totals" } }
  column :qty,   footer: :sum                                  # → 20
  column :price, footer: ->(arr) { number_to_currency(arr.sum(&:price)) }
end
```

Columns without `:footer` get an **empty cell** in the footer row so widths
align with the header.

`<tfoot>` is only rendered when at least one column has `:footer` — tables
without footers are unaffected.

## Styling

`<tfoot> <td>` gets:

- **AA 4 (Tailwind)**: `px-3 py-2 bg-gray-50 dark:bg-gray-800/50 font-semibold border-t border-gray-200 dark:border-gray-700 text-left`
- **AA 3 (Sass)**: no default styling — add to your `active_admin.scss`:
  ```scss
  .index_table tfoot td {
    background: #f3f4f6;
    font-weight: 600;
    border-top: 1px solid #ddd;
    padding: 8px 10px;
  }
  ```

Override defaults globally:

```ruby
# config/initializers/activeadmin_table_footer.rb
ActiveadminTableFooter.configure do |c|
  c.footer_th_class = "px-4 py-3 bg-blue-50 font-bold"
  c.footer_tr_class = ""
end
```

## Testing

Each footer cell carries `td[data-column="<key>"]` AND `td.col.col-<key>` (the
latter for compatibility with [capybara_active_admin](https://github.com/activeadmin-plugins/capybara_active_admin)
matchers). Both selectors work in AA 3 and AA 4:

```ruby
within_table_for("subscriptions") do
  within_table_footer do
    expect(page).to have_table_cell(column: "Seats",      exact_text: "17")
    expect(page).to have_table_cell(column: "Total Cost", exact_text: "$275.00")
  end
end
```

## Use cases

| Domain | Example |
|---|---|
| Billing / subscriptions | SUM(seats × monthly_price) across all pages |
| Orders | COUNT(*), SUM(amount), SUM(tax), MAX(placed_at) |
| Inventory | SUM(qty), SUM(qty × unit_cost) |
| CDR / call records | SUM(duration), SUM(cost), COUNT(DISTINCT caller) |
| Time tracking | SUM(hours), SUM(hours × hourly_rate) |
| Refunds | COUNT, SUM, group-by-reason in a single query |

## How it works

The gem `prepend`s two modules in a `Rails::Engine` `to_prepare` block:

- `ActiveadminTableFooter::TableForExtension` → `ActiveAdmin::Views::TableFor`:
  extracts `footer_data:` option, lazily builds `<tfoot>` when the first column
  with `:footer` is added, back-fills empty cells for prior columns so widths
  align with `<thead>`.
- `ActiveadminTableFooter::IndexAsTableExtension` → `ActiveAdmin::Views::IndexAsTable`:
  wraps the user's index block so `@footer_data_proc` is forwarded to the
  `TableFor` instance before columns are evaluated.

No changes to ActiveAdmin internals, no monkey-patching beyond `prepend`.

## License

MIT
