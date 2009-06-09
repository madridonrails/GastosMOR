require File.dirname(__FILE__) + '/../test_helper'
require 'signup_mailer'

class SignupMailerTest < Test::Unit::TestCase
  FIXTURES_PATH = File.dirname(__FILE__) + '/../fixtures'
  CHARSET = "utf-8"

  include ActionMailer::Quoting

  def setup
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []

    @expected = TMail::Mail.new
    @expected.set_content_type "text", "plain", { "charset" => CHARSET }
  end

  def test_activation_mail
    @user = User.find(:first)
    activation_page = 'activation page'
    activation_link = 'activation link'
    @user.activation_code = 'activation code'
    response = SignupMailer.deliver_activation_mail(@user, activation_page, activation_link)
    assert_equal 1, ActionMailer::Base.deliveries.length
    assert_equal response, ActionMailer::Base.deliveries[0]
    assert_equal SignupMailer::ACTIVATION_SUBJECT, response.subject
    assert_equal GastosgemUtils::MAIL_FROM, response.from[0]
    assert_equal @user.email, response.to[0]
    assert_match %r{#{activation_page}}, response.body
    assert_match %r{#{activation_link}}, response.body
    assert_match %r{#{@user.activation_code}}, response.body
    assert_match %r{http://#{@user.enterprise.short_name}.#{DOMAIN_NAME}}, response.body
    assert_match %r{#{@user.email}}, response.body
  end

  def test_activated
    @user = User.find(:first)
    access_link = 'access link'
    response = SignupMailer.deliver_activated_mail(@user, access_link)
    assert_equal 1, ActionMailer::Base.deliveries.length
    assert_equal response, ActionMailer::Base.deliveries[0]
    assert_equal SignupMailer::ACTIVATED_SUBJECT, response.subject
    assert_equal GastosgemUtils::MAIL_FROM, response.from[0]
    assert_equal @user.email, response.to[0]
    assert_match %r{#{access_link}}, response.body
  end

  private
    def read_fixture(action)
      IO.readlines("#{FIXTURES_PATH}/signup_mailer/#{action}")
    end

    def encode(subject)
      quoted_printable(subject, CHARSET)
    end
end
