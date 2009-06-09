set :application, "gastosgem"
set :repository,  "https://larry.aspgems.com:8083/ayto-madrid/#{application}/trunk"
set :user, "#{application}"
ssh_options[:config] = false
set :use_sudo, false
set :keep_releases, 2
set :rails_env, "production"

set(:scm_username) { Capistrano::CLI.ui.ask("Type is your svn username: ") }
set(:scm_password){ Capistrano::CLI.password_prompt("Type your svn password for user #{scm_username}: ") }

set :deploy_via, :export
set :deploy_to, "/home/#{user}/app"

role :app, "hal.aspgems.com"
role :web, "hal.aspgems.com"
role :db,  "hal.aspgems.com", :primary => true

files=%w(database.yml mailer.rb local_config.rb)
dirs=%w(config system/images)
after "deploy:update","deploy:symlink_config"
after "deploy:setup","deploy:create_dirs"

# Here comes the app config
after "deploy:update","#{application}:default"
after "deploy:symlink","#{application}:symlink_user_pictures"

namespace :deploy do

  task :symlink_config, :roles => :app do
    files.each do |f|
      run "ln -nfs #{shared_path}/config/#{f} #{current_path}/config/#{f}"
    end
  end

  task :restart, :roles => :app do
    run "touch  #{current_path}/tmp/restart.txt"
  end

  task :create_dirs, :roles => :app do
    dirs.each do |d|
      run "mkdir -p #{shared_path}/#{d}"
      run "echo #{shared_path}/#{d}"
    end
  end

  desc "Enables maintenance mode in the app"
  task :maintenance_on, :roles => :app do
    run "cp current/public/system/maintenance.html.disabled current/public/system/maintenance.html"
  end

  desc "Disables maintenance mode in the app"
  task :maintenance_off, :roles => :app do
    run "rm current/public/system/maintenance.html"
  end
end

# Here comes the application namespace for custom tasks

namespace application do

  desc "symlink user uploaded pictures"
  task :symlink_user_pictures, :roles => :app do
    run "ln -nfs #{shared_path}/upload/users #{current_path}/public/upload/users"
  end


  desc "Default theme_link_cache and theme_link_logos"
  task :default, :roles => :app do
    theme_link_cache
    theme_link_logos
  end

  desc "Create a link between themes and public/themes directory"
  task :theme_link_cache, :roles => :app do
    run "rm -rf #{current_path}/public/themes && " +
      "ln -nfs #{shared_path}/themes #{current_path}/public/themes"
  end

  desc "Create a link between public/logos and shared/logos directory"
  task :theme_link_logos, :roles => :app do
    run "rm -rf #{current_path}/public/logos && " +
      "ln -nfs #{shared_path}/logos #{current_path}/public/logos"
  end
end


