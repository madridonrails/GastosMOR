class Report < ActiveRecord::Base

  # Generates the complete report
  # Results are stored on a Hash, to be accessed on the report view
  # Current reports are:
  # - signups: created enterprises on the given time range
  # - updates: updated enterprises on the given time range
  def generate
    
    # report starts after the last one
    last_report = Report.find(:first, :order => 'created_at DESC')
    gastosgem_first_day = Time.parse('2007-01-15')
    report_from = last_report.created_at rescue gastosgem_first_day
    self.save
    results = {}
    results[:title] = "Informe #{APP_NAME}: #{report_from} - #{Time.now}"
    results[:body]  = {
       :signups => Enterprise.find(:all, :conditions => ['created_at > ?', report_from]),
       :updates => Enterprise.find(:all, :conditions => ['updated_at > ? AND updated_at > created_at', report_from])
    }
    results
  end
  
end