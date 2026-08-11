# frozen_string_literal: true

module Foundation
  module Storefront
    class Order < ApplicationRecord
      self.table_name = "storefront_orders"

      STATES = %w[pending paid fulfilled canceled refunded].freeze
      TRANSITIONS = {
        "pending" => %w[paid canceled],
        "paid" => %w[fulfilled refunded],
        "fulfilled" => %w[refunded],
        "canceled" => [],
        "refunded" => []
      }.freeze

      STATES.each { |value| define_method("#{value}?") { state == value } }

      belongs_to :user, optional: true, inverse_of: :storefront_orders
      has_many :line_items, class_name: "Foundation::Storefront::LineItem",
        dependent: :destroy, inverse_of: :order
      has_many :payment_events, class_name: "Foundation::Storefront::PaymentEvent",
        dependent: :nullify, inverse_of: :order

      before_validation :assign_public_reference, on: :create
      before_validation :normalize_fields

      validates :public_reference, presence: true, uniqueness: true
      validates :checkout_key_digest, presence: true, uniqueness: true
      validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }, length: { maximum: 254 }
      validates :state, inclusion: { in: STATES }
      validates :currency, format: { with: /\A[A-Z]{3}\z/ }
      validates :subtotal_cents, :total_cents, :shipping_cents,
        numericality: { only_integer: true, greater_than_or_equal_to: 0 }
      validates :terms_version, :privacy_version, :legal_accepted_at, :reservation_expires_at, presence: true
      validates :stripe_session_id, :provider_payment_id, uniqueness: true, allow_nil: true
      validates :shipping_method, inclusion: { in: Shipping::METHODS.keys }
      validates :shipping_country, format: { with: /\A[A-Z]{2}\z/ }, allow_nil: true
      validates :shipping_name, :shipping_line1, :shipping_city, :shipping_postal_code, :shipping_country,
        presence: true, if: :requires_shipping_address?
      validate :totals_match

      scope :for_email, ->(email) { where("lower(email) = ?", email.to_s.strip.downcase) }

      scope :for_email, ->(email) { where("lower(email) = ?", email.to_s.strip.downcase) }

      def transition_to!(new_state, at: Time.current)
        new_state = new_state.to_s
        raise InvalidTransition, "#{state} cannot transition to #{new_state}" unless TRANSITIONS.fetch(state).include?(new_state)

        attributes = { state: new_state }
        attributes["#{new_state}_at"] = at if has_attribute?("#{new_state}_at")
        update!(attributes)
      end

      def shipping_address
        return if shipping_name.blank?

        [ shipping_line1, shipping_line2, shipping_city, shipping_region, shipping_postal_code, shipping_country ]
          .compact_blank.join(", ")
      end

      class InvalidTransition < StandardError; end

      private

      def requires_shipping_address?
        shipping_cents.positive?
      end

      def assign_public_reference
        self.public_reference ||= loop do
          candidate = SecureRandom.base58(24)
          break candidate unless self.class.exists?(public_reference: candidate)
        end
      end

      def normalize_fields
        self.email = email.to_s.strip.downcase
        self.currency = currency.to_s.strip.upcase
        self.shipping_country = shipping_country.to_s.strip.upcase.presence
        self.shipping_cents = shipping_cents.to_i
      end

      def totals_match
        errors.add(:total_cents, "must equal subtotal plus shipping") unless total_cents == subtotal_cents + shipping_cents
      end
    end
  end
end
