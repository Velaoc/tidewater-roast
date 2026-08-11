# frozen_string_literal: true

# Tidewater Roast ships physical coffee, so orders carry a shipping address
# and a shipping charge. The foundation's digital-only invariant
# (total == subtotal) is replaced by total == subtotal + shipping.
class AddShippingToStorefrontOrders < ActiveRecord::Migration[8.1]
  def change
    change_table :storefront_orders do |t|
      t.string :shipping_name
      t.string :shipping_line1
      t.string :shipping_line2
      t.string :shipping_city
      t.string :shipping_region
      t.string :shipping_postal_code
      t.string :shipping_country, limit: 2
      t.string :shipping_method, null: false, default: "standard"
      t.bigint :shipping_cents, null: false, default: 0
      t.index :email
    end

    reversible do |dir|
      dir.up do
        execute <<~SQL
          ALTER TABLE storefront_orders DROP CONSTRAINT storefront_orders_total_matches_subtotal;
          ALTER TABLE storefront_orders ADD CONSTRAINT storefront_orders_total_matches_items
            CHECK (total_cents = subtotal_cents + shipping_cents);
        SQL
      end
      dir.down do
        execute <<~SQL
          ALTER TABLE storefront_orders DROP CONSTRAINT storefront_orders_total_matches_items;
          ALTER TABLE storefront_orders ADD CONSTRAINT storefront_orders_total_matches_subtotal
            CHECK (subtotal_cents = total_cents);
        SQL
      end
    end
  end
end
