# =============================================================================
# A set of rake tasks for invoking the Capistrano automation utility.
# =============================================================================

# Invoke the given actions via Capistrano
def cap(*parameters)
  begin
    require 'rubygems'
  rescue LoadError
    # no rubygems to load, so we fail silently
  end

  require 'capistrano/cli'

  Capistrano::CLI.new(parameters.map { |param| param.to_s }).execute!
end

namespace :remote do

  # TODO - Write descriptions for wrappers
  # Wrappers for capistrano svn tags
  task(:deploy_tag) { cap :deploy_tag }
  task(:update_tag) { cap :update_tag }
  
  # Wrappers for capistrano configurations files (database.yml, mongrel_cluster.yml)
  task(:database_configuration_setup) { cap :database_configuration_setup }
  task(:mongrel_configuration_setup) { cap :mongrel_configuration_setup }
  task(:horasgem_configuration_setup) { cap :horasgem_configuration_setup }
  task(:mailer_configuration_setup) { cap :mailer_configuration_setup }

  # Wrappers for capistrano mongrel actions
  task(:start_mongrel_cluster) { cap :start_mongrel_cluster }
  task(:restart_mongrel_cluster) { cap :restart_mongrel_cluster }
  task(:stop_mongrel_cluster) { cap :stop_mongrel_cluster }

  # Wrapper for a complete deploy tag
  desc "A macro-task that deploy a tag, create configuration files(ddbb & mongrel), migrate and restart mongrel."
  task(:long_deploy_tag) { cap :long_deploy_tag }

  # Wrapper for themes tasks
  task(:theme_link_cache) { cap :theme_link_cache}
  task(:theme_create_cache) { cap :theme_create_cache}  # Deprecated use theme_link_cache
  task(:theme_update_cache) { cap :theme_update_cache}  # Deprecated use theme_link_cache
  

  desc "Removes unused releases from the releases directory."
  task(:cleanup) { cap :cleanup }

  desc "Used only for deploying when the spinner isn't running."
  task(:cold_deploy) { cap :cold_deploy }

  desc "A macro-task that updates the code, fixes the symlink, and restarts the application servers."
  task(:deploy) { cap :deploy }

  desc "Similar to deploy, but it runs the migrate task on the new release before updating the symlink."
  task(:deploy_with_migrations) { cap :deploy_with_migrations }

  desc "Displays the diff between HEAD and what was last deployed."
  task(:diff_from_last_deploy) { cap :diff_from_last_deploy }

  desc "Disable the web server by writing a \"maintenance.html\" file to the web servers."
  task(:disable_web) { cap :disable_web }

  desc "Re-enable the web server by deleting any \"maintenance.html\" file."
  task(:enable_web) { cap :enable_web }

  desc "A simple task for performing one-off commands that may not require a full task to be written for them."
  task(:invoke) { cap :invoke }

  desc "Run the migrate rake task."
  task(:migrate) { cap :migrate }

  desc "Restart the FCGI processes on the app server."
  task(:restart) { 
    cap :restart 
  }

  desc "A macro-task that rolls back the code and restarts the application servers."
  task(:rollback) { cap :rollback }

  desc "Rollback the latest checked-out version to the previous one by fixing the symlinks and deleting the current release from all servers."
  task(:rollback_code) { cap :rollback_code }

  desc "Set up the expected application directory structure on all boxes"
  task(:setup) { cap :setup }

  desc "Begin an interactive Capistrano session."
  task(:shell) { cap :shell }

  desc "Enumerate and describe every available task."
  task(:show_tasks) { cap :show_tasks, '-q' }

  desc "Start the spinner daemon for the application (requires script/spin)."
  task(:spinner) { cap :spinner }

  desc "Update the 'current' symlink to point to the latest version of the application's code."
  task(:symlink) { cap :symlink }

  desc "Updates the code and fixes the symlink under a transaction"
  task(:update) { cap :update }

  desc "Update all servers with the latest release of the source code."
  task(:update_code) { cap :update_code }

  desc "Update the currently released version of the software directly via an SCM update operation"
  task(:update_current) { cap :update_current }

  desc "Execute a specific action using capistrano"
  task :exec do
    unless ENV['ACTION']
      raise "Please specify an action (or comma separated list of actions) via the ACTION environment variable"
    end

    actions = ENV['ACTION'].split(",")
    actions.concat(ENV['PARAMS'].split(" ")) if ENV['PARAMS']

    cap(*actions)
  end
end

desc "Push the latest revision into production (delegates to remote:deploy)"
task :deploy => "remote:deploy"

desc "Rollback to the release before the current release in production (delegates to remote:rollback)"
task :rollback => "remote:rollback"
