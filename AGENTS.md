# MiiNegocio (posagenda)

Rails 8.1.1 · Ruby 3.4.4 · PostgreSQL · Kamal deploy · Spanish (MX)

## Quick start

```sh
bin/setup                  # first time
bin/dev                    # dev server (port 3000)
bin/ci                     # full local CI: setup → rubocop → security audit → test → system → seeds
bin/rails test             # unit/integration tests (Minitest)
bin/rails test:system      # system tests (Selenium headless Chrome)
bin/rubocop                # lint (rubocop-rails-omakase style)
bin/kamal deploy           # deploy to production (Docker-based)
```

## Architecture

- **Multi-tenant**: `Corp` is the central organizational unit (businesses). Users belong to corps.
- **Auth**: Devise with 3 separate models — `User` (business owner), `Admin` (platform admin), `Customer` (end client).
- **Panel routing**: `/panel/*` (user panel), `/admin/*` (admin panel), `/e/:sku` (public corp pages).
- **Multi-database** (dev/prod): `primary`, `queue` (Solid Queue), `cable` (Solid Cable). Test uses a single DB.
- **PDF generation**: `app/pdfs/` with Prawn (prawn, prawn-svg, prawn-table).
- **Background jobs**: Solid Queue (runs in Puma in dev; `SOLID_QUEUE_IN_PUMA=true` in prod).
- **Caching**: Solid Cache (production only).
- **Payments**: Stripe (`stripe` gem, ~> 19.1).
- **SMS**: `SmsService.sms(to:, code:, body:)` (lib/sms_service.rb).
- **Telegram**: `telegram-bot` gem, `Gtools.telegram_noti(message:)`.

## Key conventions

- **Locale**: `:es` default, `:en` also available. Timezone `America/Mexico_City`. ActiveRecord default timezone `:local`.
- **Field helpers**: Use `n_field` (number), `t_field` (text), `p_field` (password), `e_field` (email), `a_field` (textarea), `s_field` (select) from `ApplicationHelper` — they auto-detect required fields and render Bulma markup.
- **SEO**: `SeoHelper#set_page_meta(title:, description:, ...)` in views. Custom sitemaps at `/sitemap.xml`.
- **CSS framework**: Bulma (`.is-rounded`, `.is-danger` classes visible in helpers).
- **Frontend**: Import maps + Hotwire (Turbo + Stimulus). No Webpack/Node build step.

## Custom Rake tasks

```sh
bin/rails corps:normalize_business_hours   # migrate business_hours JSON format
bin/rails corps:cobranza                   # daily billing for all corps
bin/rails sat:gen_products                 # seed SAT catalog products
bin/rails va:gen_events                    # generate ~100 fake events (Faker)
bin/rails va:dummy_bill                    # create dummy Stripe bill (corp_id=1)
bin/rails va:telegram_noti                 # test Telegram notification
bin/rails va:sms                           # test SMS sending
```

## Testing

- **Framework**: Minitest (not RSpec). Fixtures in `test/fixtures/*.yml`.
- **Parallel**: `parallelize(workers: :number_of_processors)` in `test_helper.rb`.
- **System tests**: `driven_by :selenium, using: :headless_chrome` — screenshots on failure go to `tmp/screenshots`.
- **CI pipeline** (`.github/workflows/ci.yml`): `scan_ruby` (brakeman + bundler-audit) → `scan_js` (importmap audit) → `lint` (rubocop) → `test` (rails test) → `system-test` (rails test:system).

## Deployment

- **Kamal** (Docker-based, `bin/kamal deploy`). Config in `config/deploy.yml`.
- Server: `64.23.234.167`, domain: `miinegocio.com`.
- First run: `bin/kamal setup`. Subsequent: `bin/kamal deploy`.
- Container image: `rocinante99/posagenda`.
- Kamal aliases: `bin/kamal console`, `bin/kamal logs`, `bin/kamal dbc`, `bin/kamal seed`.
- Postgres runs as a Kamal accessory on the same host (port 5432).
- Secrets: `RAILS_MASTER_KEY`, `POSTGRES_PASSWORD`, `KAMAL_REGISTRY_PASSWORD`.

## Notable lib files

- `lib/gtools.rb` — general tools (cobranza, dummy_bill, telegram_noti)
- `lib/ftools.rb` — CFDI/factura tools
- `lib/factura.rb` — factura (Mexican SAT) library
- `lib/deep.rb` — DeepSeek AI API related
- `lib/cadena/` — XML CFDI generation
- `lib/sms_service.rb` — SMS gateway
