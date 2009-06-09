require File.dirname(__FILE__) + '/../test_helper'

class SubdomainsMailerTest < Test::Unit::TestCase
  FIXTURES_PATH = File.dirname(__FILE__) + '/../fixtures'
  CHARSET = "utf-8"

  include ActionMailer::Quoting

  def setup
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []

    @expected = TMail::Mail.new
    @expected.set_content_type "text", "plain", { "charset" => CHARSET }
    @expected.mime_version = '1.0'
  end

  def test_mail_with_subdomains
    @user = User.find(:first)
    response = SubdomainsMailer.deliver_mail_with_subdomains([@user])
    assert_equal 1, ActionMailer::Base.deliveries.length
    assert_equal response, ActionMailer::Base.deliveries[0]
    assert_equal SubdomainsMailer::SUBJECT, response.subject
    assert_equal GastosgemUtils::MAIL_FROM, response.from[0]
    assert_equal @user.email, response.to[0]
    assert_match %r{#{@user.print_name}, estos}, response.body
    assert_match %r{Empresa: #{@user.enterprise.name}}, response.body
    assert_match %r{http://#{@user.enterprise.short_name}.#{DOMAIN_NAME}}, response.body
  end

  private
    def read_fixture(action)
      IO.readlines("#{FIXTURES_PATH}/subdomains_mailer/#{action}")
    end

    def encode(subject)
      quoted_printable(subject, CHARSET)
    end
end
