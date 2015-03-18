require 'test_helper'
require 'securerandom'

class RemoteKomojuTest < Test::Unit::TestCase
  def setup
    @gateway = KomojuGateway.new(fixtures(:komoju))

    @amount = 100
    @credit_card = credit_card('4111111111111111')
    @declined_card = credit_card('4123111111111059')
    @konbini = {
      type: 'konbini',
      store: 'lawson',
      email: 'test@example.com',
      phone: '09011112222'
    }

    @options = {
      order_id: SecureRandom.uuid,
      description: 'Store Purchase'
    }
  end

  def test_successful_credit_card_purchase
    response = @gateway.purchase(@amount, @credit_card, @options)
    assert_success response
    assert_equal 'Transaction succeeded', response.message
  end

  def test_successful_konbini_purchase
    response = @gateway.purchase(@amount, @konbini, @options)
    assert_success response
    assert_equal 'Transaction succeeded', response.message
  end

  def test_failed_purchase
    response = @gateway.purchase(@amount, @declined_card, @options)
    assert_failure response
    assert_equal 'card_declined', response.error_code
  end

  def test_invalid_login
    gateway = KomojuGateway.new(login: 'abc')
    response = gateway.purchase(@amount, @credit_card, @options)
    assert_failure response
  end
end
