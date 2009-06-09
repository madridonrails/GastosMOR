require File.dirname(__FILE__) + '/../test_helper'

class ReportMailerTest < Test::Unit::TestCase
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

  def test_report_mail
    response = ReportMailer.deliver_report_mail
    assert_equal 1, ActionMailer::Base.deliveries.length
    assert_equal response, ActionMailer::Base.deliveries[0]
    assert_match %r{Informe #{APP_NAME}:}, response.subject
    assert_equal GastosgemUtils::MAIL_FROM, response.from[0]
    assert_equal GastosgemUtils::REPORTING_RECEIVER, response.to[0]
  end

  private
    def read_fixture(action)
      IO.readlines("#{FIXTURES_PATH}/report_mailer/#{action}")
    end

    def encode(subject)
      quoted_printable(subject, CHARSET)
    end
end
