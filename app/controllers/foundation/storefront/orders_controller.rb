# frozen_string_literal: true

module Foundation
  module Storefront
    class OrdersController < BaseController
      def show
        @order = Order.includes(:line_items).find_by!(public_reference: params[:id])
        head :not_found unless ReceiptAccess.allowed?(order: @order, user: current_user, token: params[:access_token])
      end

      # Past-order lookup: a customer enters the email they checked out with
      # and sees their orders. Links carry a signed, expiring token so the
      # receipt stays private without requiring an account.
      def lookup
        @orders = []
      end

      def lookup_results
        email = params.dig(:orders, :email).to_s.strip
        if email.present?
          @orders = Order.for_email(email)
            .where(state: %w[paid fulfilled refunded])
            .order(created_at: :desc)
            .to_a
        else
          @orders = []
        end
        render :lookup
      rescue ActionController::ParameterMissing
        @orders = []
        render :lookup
      end
    end
  end
end
