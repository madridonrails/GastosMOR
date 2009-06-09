class ReportMailer < ActionMailer::Base

  self.raise_delivery_errors = true

  def report_mail
    setup_email
    report    = Report.new
    data      = report.generate
    @subject  = data[:title]
    @body     = data[:body]
  end
  
  protected
  def setup_email
    @recipients  = GastosgemUtils::REPORTING_RECEIVER
    @from        = GastosgemUtils::MAIL_FROM
    @sent_on     = Time.now
    @headers    = {}
  end

end
