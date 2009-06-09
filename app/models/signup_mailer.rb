class SignupMailer < ActionMailer::Base

  self.raise_delivery_errors = true

  ACTIVATION_SUBJECT = "Activacion de tu cuenta en #{APP_NAME}"
  ACTIVATED_SUBJECT = "Tu cuenta en #{APP_NAME} ha sido activada"

  def activation_mail(user, activation_link, activation_page)
    setup_email(user)    
    @subject    = ACTIVATION_SUBJECT
    @body       = { :activation_link => activation_link, :activation_page => activation_page, :activation_code => user.activation_code, :domain =>  user.enterprise.short_name, :email => user.email}
  end

  def activated_mail(user, access_link)
    setup_email(user)
    @subject    = ACTIVATED_SUBJECT
    @body       = { :access_link => access_link}
  end

  protected
  def setup_email(user)
    @recipients  = "#{user.email}"
    @from        = GastosgemUtils::MAIL_FROM
    @sent_on     = Time.now
    @headers    = {}
    @charset = 'utf-8'
    @content_type = 'text/html'
  end

end
