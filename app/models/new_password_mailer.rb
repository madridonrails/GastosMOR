require 'gastosgem_utils'

class NewPasswordMailer < ActionMailer::Base
  
  self.raise_delivery_errors = true
  
  SUBJECT = "Nuevo password para #{APP_NAME}"
  
  # Configures the mail with new password to be sent to the user.
  # This method assumes the validity of its invocation has been
  # checked in the controller.
  def mail_with_new_password(user, new_passwd)
    @subject    = SUBJECT
    @recipients = user.email
    @from       = GastosgemUtils::MAIL_FROM
    @sent_on    = Time.now
    @headers    = {}
    
    @charset = 'utf-8'
    @content_type = 'text/html'
    
    @body["email"] = user.email
    @body["print_name"] = user.print_name
    @body["passwd"]=new_passwd
    @body["company_name"]=user.enterprise.name    
    @body["domain"]="#{user.enterprise.short_name}.#{DOMAIN_NAME}"
  end
end
