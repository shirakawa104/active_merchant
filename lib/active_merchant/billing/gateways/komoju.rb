require 'json'
require 'komoju'

module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    class KomojuGateway < Gateway
      self.live_url = "https://gateway-sandbox.degica.com/api/v1"
      self.supported_countries = ['JP']
      self.default_currency = 'JPY'
      self.money_format = :cents
      self.homepage_url = 'https://komoju.com/'
      self.display_name = 'Komoju'
      self.supported_cardtypes = [:visa, :master, :american_express, :jcb]

      STANDARD_ERROR_CODE_MAPPING = {
        "bad_verification_value" => "incorrect_cvc",
        "card_expired" => "expired_card",
        "card_declined" => "card_declined",
        "invalid_number" => "invalid_number"
      }

      def initialize(options = {})
        requires!(options, :login)
        @api_key = options[:login]
        super
      end

      def purchase(money, payment, options = {})
        params = {
          amount: amount(money),
          description: options[:description],
          payment_details: payment_details(payment, options),
          currency: options[:currency] || currency(money),
          external_order_num: options[:order_id]
        }
        commit(params)
      end

      private

      def payment_details(payment, options)
        details = if payment.is_a?(CreditCard)
                    credit_card_payment_details(payment, options)
                  else
                    payment
                  end

        details[:email] = options[:email] if options[:email]
        details
      end

      def credit_card_payment_details(card, options)
        details = {}
        details[:type] = 'credit_card'
        details[:number] = card.number
        details[:month] = card.month
        details[:year] = card.year
        details[:verification_value] = card.verification_value
        details[:given_name] = card.first_name
        details[:family_name] = card.last_name
        details
      end

      def create_payment_request(params)
        Komoju.connect(@api_key, url: self.live_url).payments.create(params)
      end

      def api_request(params)
        response = nil
        begin
          response = create_payment_request(params)
        rescue Excon::Errors::HTTPStatusError => e
          response = JSON.parse(e.response.body)
        end
        response
      end

      def commit(params)
        response = api_request(params)
        success = !response.key?("error")
        message = success ? "Transaction succeeded" : response["error"]["message"]
        Response.new(success, message, response,
                     error_code: success ? nil : error_code(response["error"]["code"]),
                     authorization: success ? response["id"] : nil)
      end

      def error_code(code)
        STANDARD_ERROR_CODE_MAPPING[code] || code
      end
    end
  end
end
