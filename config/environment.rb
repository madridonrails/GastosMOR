#require 'custom_error_message'
# Be sure to restart your web server when you modify this file.

# Uncomment below to force Rails into production mode when 
# you don't control web/app server and can't set it the proper way
# ENV['RAILS_ENV'] ||= 'production'


# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '1.2.0' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence over those specified here
  
  # Skip frameworks you're not going to use (only works if using vendor/rails)
  # config.frameworks -= [ :action_web_service, :action_mailer ]
  config.frameworks -= [ :action_web_service ] # we don't use this framework

  # Only load the plugins named here, by default all plugins in vendor/plugins are loaded
  # config.plugins = %W( exception_notification ssl_requirement )

  # Add additional load paths for your own custom dirs
  # config.load_paths += %W( #{RAILS_ROOT}/extras )

  # Force all environments to use the same logger level 
  # (by default production uses :info, the others :debug)
  # config.log_level = :debug

  # Use the database for sessions instead of the file system
  # (create the session table with 'rake db:sessions:create')
  # config.action_controller.session_store = :active_record_store

  # Use SQL instead of Active Record's schema dumper when creating the test database.
  # This is necessary if your schema can't be completely dumped by the schema dumper, 
  # like if you have constraints or database-specific column types
  # config.active_record.schema_format = :sql

  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector

  # Make Active Record use UTC-base instead of local time
  # config.active_record.default_timezone = :utc
  
  # See Rails::Configuration for more options
end

# Add new inflection rules using the following format 
# (all these examples are active by default):
Inflector.inflections do |inflect|
#   inflect.plural /^(ox)$/i, '\1en'
#   inflect.singular /^(ox)en/i, '\1'
#   inflect.irregular 'person', 'people'
  inflect.irregular 'error', 'errores'
#   inflect.uncountable %w( fish sheep )
end

# Add new mime types for use in respond_to blocks:
# Mime::Type.register "text/richtext", :rtf
# Mime::Type.register "application/x-mobile", :mobile

# Include your application configuration below
#include Globalize
#Locale.set_base_language 'es-ES'
#LOCALES = {
#           'en' => 'en-US',
#           'es' => 'es-ES',
#           'es' => 'ca-ES'}.freeze



# The idiomatic way to do this is to write a plugin, but I don't have time to do that.     
class ActiveRecord::Base
  # This class method generates methods like this one:
  #
  # def first_name=(fname)
  #    write_attribute(:first_name, fname)
  #    write_attribute(:first_name_for_sorting, GastosgemUtils.normalize_for_sorting(fname))
  #  end
  def self.add_for_sorting_to(*fields)
    fields.each do |f|
      class_eval <<-EOS
        def #{f}=(v)
          write_attribute(:#{f}, v)
          write_attribute(:#{f}_for_sorting, GastosgemUtils.normalize_for_sorting(v))
        end
      EOS
    end
  end
end

$KCODE = 'u' # everything in this application is UTF-8

# To ease development local configuration is not in SVN.
# A file config/local_config.rb is expected with configuration,
# see config/local_config.rb.example.
require File.join(RAILS_ROOT, 'config', 'local_config.rb')

# To ease development mailer configuration is not in SVN.
# A file config/mailer.rb is expected with configuration,
# see config/mailer.rb.example.
require File.join(RAILS_ROOT, 'config', 'mailer.rb')

# FIX: DoS vulnerabilities in REXML - http://feeds.feedburner.com/~r/RidingRails/~3/372559660/dos-vulnerabilities-in-rexml
require 'rexml-expansion-fix'
