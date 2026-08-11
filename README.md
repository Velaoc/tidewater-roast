<!-- foundation:identity -->
# Tidewater Roast

Online store for Tidewater Roast, a small coffee roaster: browse coffees with photos and prices, cart, guest checkout, and order history lookup.

- Site: https://tidewater-roast.api.holode.xyz
- Support: support@tidewater-roast.api.holode.xyz
<!-- /foundation:identity -->

## What this is

Online store for Tidewater Roast, a small coffee roaster: browse coffees with photos and prices, cart, guest checkout, and order history lookup.

## Who it is for

- Guest shopper
- Customer (order lookup by email via signed links)
- Admin (roaster owner)

## Main features

- **Browse products** — Shop by category; product cards show photo, roast level, price; detail page shows tasting notes
- **Add to cart** — Add bags to a session cart, adjust quantity, see running total
- **Guest checkout** — Checkout with just an email; order completes and receipt is reachable through a signed, expiring access link
- **Past orders** — Customer enters their email on the order-lookup page and sees their order history via signed links
- **Admin manage** — Admin manages products (photo, price, active), categories, and views/fulfills orders

## Core entities

- Product
- Category
- Order
- OrderLineItem
- Cart

## Included foundation modules

- storefront

## Run locally

```bash
bundle install
bin/rails db:prepare
bin/dev
```

Requires Ruby, PostgreSQL, and the usual Rails toolchain. See `bin/setup` if present.

## Demo

Six coffees across three categories (Single Origin, Blends, Espresso) with photos, roast levels, tasting notes and prices; one demo order tied to a demo email shown on the order-lookup page.

## Deploy notes

Production `config.hosts` is derived from `domain` in `config/foundation.yml`. Keep that value aligned with the real host or every request will 403.
