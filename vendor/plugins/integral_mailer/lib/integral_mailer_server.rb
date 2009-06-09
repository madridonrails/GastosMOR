require 'net/smtp'
require 'logger'
require 'fileutils'

class IntegralMailerServer
  include FileUtils
  
  def self.reloadable?; false; end
  
  def initialize
    log_dir = "#{RAILS_ROOT}/log"; mkdir_p(log_dir)
    @log = Logger.new("#{log_dir}/integral_mailer.log", 5, 10*1024)
    @log.info "Initializing"
  end
  
  def send_mail(helo_domain, from_email, destination_emails, data)
    t = Thread.new do
      destination_emails.each do |dest_email|

        mx_records = MXLookup.for_email(dest_email)
        mx_records.each do |mx_record|
          begin
            Net::SMTP.start(mx_record[:host], 25, helo_domain) do |smtp|
              smtp.send_message data, from_email, dest_email
              @log.info("Message sent to #{dest_email} via #{mx_record[:host]}")
            end; break
          rescue => e
            @log.warn "#{e.class.to_s} when sending message to #{dest_email} via #{mx_record[:host]}:"
            @log.warn "\t#{e.message}"
          end
        end # mx_records.each
        
      end # destination_emails.each
    end # Thread.new 
  end # send_mail
end