# frozen_string_literal: true

module Foundation
  module Storefront
    # Shipping rules for Tidewater Roast. Flat rates for physical coffee:
    # standard domestic shipping is a flat $5.50 per order; a second flat
    # tier (priority) exists for admin/explicit selection. Demo-friendly and
    # honest: rates are visible at checkout before any charge is created.
    class Shipping
      METHODS = {
        "standard" => { name: "Standard (5–7 business days)", cents: 550 },
        "priority" => { name: "Priority (2–3 business days)", cents: 1_250 }
      }.freeze

      class << self
        def methods
          METHODS
        end

        def cents_for(method)
          METHODS.fetch(method.to_s, METHODS.fetch("standard"))[:cents]
        end

        def name_for(method)
          METHODS.fetch(method.to_s, METHODS.fetch("standard"))[:name]
        end

        def valid_method?(method)
          METHODS.key?(method.to_s)
        end
      end
    end
  end
end
