# frozen_string_literal: true

module Foundation
  # Tidewater Roast demo catalog (SPEC M10.3).
  #
  # The application boots and serves every page with an empty database, so no
  # seed is ever required. These rows exist only to make the storefront,
  # shipping, and order-history walkable on a developer machine or in a hosted
  # preview, and they are refused everywhere else — a production deployment
  # must never find invented products in its catalog.
  module DemoSeeds
    PRODUCTS = [
      {
        slug: "colombia-el-dorado", sku: "TW-COL-12", name: "Colombia El Dorado",
        description: "Medium roast · Single origin. Washed process from the Huila region. Notes of brown sugar, red apple, and a clean honey finish.",
        price_cents: 1_850, position: 0, inventory_quantity: 50,
        image_url: "https://images.unsplash.com/photo-1447933601403-0c6688de566e?auto=format&fit=crop&w=800&q=80"
      },
      {
        slug: "ethiopia-yirgacheffe", sku: "TW-ETH-12", name: "Ethiopia Yirgacheffe",
        description: "Light roast · Single origin. Floral and bright with blueberry, bergamot, and jasmine tea notes.",
        price_cents: 2_100, position: 1, inventory_quantity: 50,
        image_url: "https://images.unsplash.com/photo-1509042239860-f550ce710b93?auto=format&fit=crop&w=800&q=80"
      },
      {
        slug: "kenya-aa-karindundu", sku: "TW-KEN-12", name: "Kenya AA Karindundu",
        description: "Medium-light roast · Single origin. Juicy blackcurrant, tomato-bright acidity, and a sweet cane finish.",
        price_cents: 2_300, position: 2, inventory_quantity: 50,
        image_url: "https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?auto=format&fit=crop&w=800&q=80"
      },
      {
        slug: "tidewater-house-blend", sku: "TW-HSE-12", name: "Tidewater House Blend",
        description: "Medium-dark roast · Blend. Chocolate, toasted almond, and molasses. Built for milk drinks and drip alike.",
        price_cents: 1_600, position: 3, inventory_quantity: 50,
        image_url: "https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?auto=format&fit=crop&w=800&q=80"
      },
      {
        slug: "sunrise-espresso", sku: "TW-ESP-12", name: "Sunrise Espresso",
        description: "Dark roast · Espresso blend. Caramel, dark chocolate, and a hint of dried cherry. Pulls thick with a heavy crema.",
        price_cents: 1_900, position: 4, inventory_quantity: 50,
        image_url: "https://images.unsplash.com/photo-1512568400610-62da28bc8a13?auto=format&fit=crop&w=800&q=80"
      },
      {
        slug: "decaf-after-dark", sku: "TW-DEC-12", name: "Decaf After Dark",
        description: "Medium roast · Swiss Water decaf. Smooth cocoa, graham cracker, and a soft caramel sweetness with none of the caffeine.",
        price_cents: 1_750, position: 5, inventory_quantity: 50,
        image_url: "https://images.unsplash.com/photo-1511081692775-05d0f180a065?auto=format&fit=crop&w=800&q=80"
      }
    ].freeze

    DEMO_EMAIL = "demo@tidewater.example"

    # Development or a hosted preview only. Preview runs in the production
    # Rails environment, so the preview flag — not RAILS_ENV alone — is what
    # separates a disposable demo from a real deployment.
    def self.permitted?(rails_env: Rails.env, preview: Foundation.preview?)
      rails_env.development? || preview
    end

    def self.run!(io: $stdout)
      unless permitted?
        io.puts("Skipping demo seeds: they are limited to development and hosted previews.")
        return 0
      end

      unless Foundation.storefront_enabled?
        io.puts("Skipping demo seeds: the storefront is disabled in config/foundation.yml.")
        return 0
      end

      created = seed_products!
      seed_demo_order!
      io.puts("Demo catalog ready: #{PRODUCTS.length} products (#{created} created).")
      created
    end

    # Upserts by slug so repeated runs converge on the same catalog instead of
    # duplicating rows.
    def self.seed_products!
      created = 0

      PRODUCTS.each do |attributes|
        product = Foundation::Storefront::Product.find_or_initialize_by(slug: attributes[:slug])
        created += 1 if product.new_record?
        product.update!(**attributes, currency: "USD", active: true)
      end

      created
    end

    # One fulfilled demo order so the order-history lookup has something to
    # show. Idempotent on the checkout digest.
    def self.seed_demo_order!
      products = Foundation::Storefront::Product.where(slug: %w[colombia-el-dorado tidewater-house-blend]).index_by(&:slug)
      return if products.length < 2

      digest = Digest::SHA256.hexdigest("tidewater-demo-order")
      return if Foundation::Storefront::Order.exists?(checkout_key_digest: digest)

      colombia = products.fetch("colombia-el-dorado")
      house = products.fetch("tidewater-house-blend")
      subtotal = (colombia.price_cents * 2) + house.price_cents
      shipping = Foundation::Storefront::Shipping.cents_for("standard")

      order = Foundation::Storefront::Order.new(
        checkout_key_digest: digest,
        email: DEMO_EMAIL,
        state: "fulfilled",
        currency: "USD",
        subtotal_cents: subtotal,
        total_cents: subtotal + shipping,
        shipping_cents: shipping,
        shipping_method: "standard",
        shipping_name: "Rowan Ellis",
        shipping_line1: "12 Harbor Lane",
        shipping_city: "Norfolk",
        shipping_region: "VA",
        shipping_postal_code: "23510",
        shipping_country: "US",
        terms_version: Foundation::Legal::TERMS_VERSION,
        privacy_version: Foundation::Legal::PRIVACY_VERSION,
        legal_accepted_at: 3.days.ago,
        reservation_expires_at: 2.days.ago,
        paid_at: 3.days.ago,
        fulfilled_at: 2.days.ago,
        simulated: true
      )
      order.line_items.build(
        product: colombia, name: colombia.name, sku: colombia.sku,
        unit_price_cents: colombia.price_cents, currency: "USD", quantity: 2,
        line_total_cents: colombia.price_cents * 2
      )
      order.line_items.build(
        product: house, name: house.name, sku: house.sku,
        unit_price_cents: house.price_cents, currency: "USD", quantity: 1,
        line_total_cents: house.price_cents
      )
      order.save!
    end
  end
end
