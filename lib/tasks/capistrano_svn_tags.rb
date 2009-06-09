Capistrano.configuration(:must_exist).load do

  set :svn_tag_dir, 'tags' # new config var to denote the tag sub-directory in the svn repository  
  
  desc <<-DESC
  Update all servers with the provided tag of the source code. All this does
  is do a checkout of the provided svn tag (as defined by the svn module).
  DESC
  task :update_tag, :roles => [:app, :db, :web] do
  
    puts "  * deploying tag #{release}"
    on_rollback { delete release_path, :recursive => true }
    source.checkout_tag(self)
    run <<-CMD
      rm -rf #{release_path}/log #{release_path}/public/system &&
      ln -nfs #{shared_path}/log #{release_path}/log &&
      ln -nfs #{shared_path}/system #{release_path}/public/system
    CMD

  end

  desc <<-DESC
  Deploy svn tag, reset symlink and restart server.
  DESC
  task :deploy_tag, :roles => [:app, :db, :web] do
    set_release_tag

    transaction do
      update_tag    
      symlink_tag      
    end
  end
  
  desc <<-DESC
  Deploy svn tag, migrate, compile .po files to .mo and reset symlink and restart server.
  Note that everything is done in a transaction
  DESC
  task :deploy_tag_with_migrations, :roles => [:app, :db, :web] do
    set_release_tag

    transaction do
      update_tag
      symlink_tag
      migrate
    end
  end
  
  
  desc <<-DESC
  Update the 'current' symlink to point to the latest version of
  the application's code.
  DESC
  task :symlink_tag, :except => { :no_release => true } do
    on_rollback { run "ln -nfs #{previous_release} #{current_path}" }
    run "ln -nfs #{release_path} #{current_path}"
  end
  
  def set_release_tag
    set :release, ENV['TAG']
    unless release
      puts "  * no tag specified, assuming latest"
      set(:release) {source.latest_tag}
    end
  end
  
  
end

module Capistrano

  #override a configuration object method to return the correct release_path for the tag.
  class Configuration
  
    # Return the full path to the named release. If a release is not specified,
    # the provided tag name (passed as a cli parameter) is used.
    def tag_path(tag_name = release)
      File.join(releases_path, tag_name)
    end
    alias_method :release_path, :tag_path
    
  end
  
  # add a method to the subversion object to checkout tags
  module SCM
    class Subversion
      
      def latest_tag
        configuration.logger.debug "querying latest tag ..." unless @latest_revision
        tags_dir = configuration.repository + '/' + configuration.svn_tag_dir + '/'
        @latest_revision = svn_ls(tags_dir).split("\n").last.chomp('/')
      end
      alias_method :latest_revision, :latest_tag
      
      # checkout a tag from a pre-configured svn tag dir.
      def checkout_tag(actor)
        op = configuration[:checkout] || "co"
        username = configuration[:svn_username] ? "--username #{configuration[:svn_username]}" : ""
        command = "#{svn} #{op} #{username} -q #{configuration.repository}/#{configuration.svn_tag_dir}/#{configuration.release} #{actor.release_path} &&"        
        run_checkout(actor, command, &svn_stream_handler(actor))         
      end
      
    private
      def svn_ls(path)
        `svn ls #{path}`
      end
    end
  end
end

