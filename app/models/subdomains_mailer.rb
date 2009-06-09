require 'gastosgem_utils'

class SubdomainsMailer < ActionMailer::Base
  
  self.raise_delivery_errors = true
  
  SUBJECT = "Direccion de acceso a #{APP_NAME}"
  
  # Configures the mail with valid subdomains to be sent to the user.
  # This method assumes the validity of its invocation has been
  # checked in the controller.
  def mail_with_subdomains(users)
    enterprises = users.collect {|u| u.enterprise}
    @subject    = SUBJECT
    @body       = { :user => users[0], :enterprises => enterprises }
    @recipients = users[0].email
    @from       = GastosgemUtils::MAIL_FROM
    @sent_on    = Time.now
    @headers    = {}
    @charset = 'utf-8'
    @content_type = 'text/html'
  end
end
