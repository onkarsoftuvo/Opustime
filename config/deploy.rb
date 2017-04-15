require 'mina/bundler'
require 'mina/rails'
require 'mina/git'
require 'mina/rbenv' # for rbenv support. (http://rbenv.org)
# require 'mina/rvm' # for rvm support. (http://rvm.io)

# Basic settings:
#   domain       - The hostname to SSH to.
#   deploy_to    - Path to deploy into.
#   repository   - Git repo to clone from. (needed by mina/git)
#   branch       - Branch name to deploy. (needed by mina/git)
# set :domain,   '34.195.133.66' # Production Server
# set :domain,   '54.145.168.78' # Development Server
# set :domain,   '34.195.243.44' # Staging Server
# set :domain,   '54.145.168.78' # Development Server
set :domain,   '127.0.0.1' # Staging Server

# set :domain,   '52.90.11.165'  # production server
set :deploy_to, '/home/ubuntu/opustime'
set :repository, 'git@github.com:onkarsoftuvo/Opustime.git'
set :branch, 'master'
set :user, 'ubuntu'
set :forward_agent, true
set :port, '22'
set :term_mode, nil
set :bundle_gemfile, "#{deploy_to}/#{current_path}/Gemfile"
set :faye_config, 'faye.ru'
set :faye_pid, "#{deploy_to}/#{shared_path}/pids/faye.pid"
set :puma_socket, "#{deploy_to}/#{shared_path}/sockets/puma.sock"
set :puma_pid, "#{deploy_to}/#{shared_path}/pids/puma.pid"
# set delayed_job config
set :delayed_job, lambda { "bin/delayed_job" }
set :delayed_job_pid_dir, lambda { "#{deploy_to}/#{shared_path}/pids" }
set :keep_releases, 2
# Manually create these paths in shared/ (eg: shared/config/database.yml) in your server.
# They will be linked in the 'deploy:link_shared_paths' step.
set :shared_paths, ['config/database.yml', 'config/secrets.yml', 'log', 'pids', 'sockets']

# This task is the environment that is loaded for most commands, such as
# `mina deploy` or `mina rake`.
task :environment do
  # For those using RVM, use this to load an RVM version@gemset.
  queue 'echo "-----> Loading environment" '
  invoke :'rbenv:load'
  # invoke :'rvm:use[ruby-2.2.2@default]'
end

# Put any custom mkdir's in here for when `mina setup` is ran.
# For Rails apps, we'll make some of the shared paths that are shared between
# all releases.
task :setup => :environment do
  queue! %[mkdir -p "#{deploy_to}/#{shared_path}/log"]
  queue! %[chmod g+rx,u+rwx "#{deploy_to}/#{shared_path}/log"]

  queue! %[mkdir -p "#{deploy_to}/#{shared_path}/pids"]
  queue! %[chmod g+rx,u+rwx "#{deploy_to}/#{shared_path}/pids"]

  queue! %[mkdir -p "#{deploy_to}/#{shared_path}/sockets"]
  queue! %[chmod g+rx,u+rwx "#{deploy_to}/#{shared_path}/sockets"]

  queue! %[mkdir -p "#{deploy_to}/#{shared_path}/scripts"]
  queue! %[chmod g+rx,u+rwx "#{deploy_to}/#{shared_path}/scripts"]

  queue! %[mkdir -p "#{deploy_to}/#{shared_path}/config"]
  queue! %[chmod g+rx,u+rwx "#{deploy_to}/#{shared_path}/config"]

  queue! %[touch "#{deploy_to}/#{shared_path}/config/database.yml"]
  queue! %[touch "#{deploy_to}/#{shared_path}/config/secrets.yml"]
  queue %[echo "-----> Be sure to edit '#{deploy_to}/#{shared_path}/config/database.yml' and 'secrets.yml'."]

end

desc "Deploys the current version to the server."
task :deploy => :environment do

  deploy do
    # Put things that will set up an empty directory into a fully set-up
    # instance of your project.
    invoke :'git:clone'
    invoke :'deploy:link_shared_paths'
    invoke :'bundle:install'
    invoke :'rails:db_migrate'
    invoke :'rails:assets_precompile'
    invoke :'deploy:cleanup'
    invoke :'monit_scripts_symlinking'
    to :launch do
      # Restart application
      invoke :'opustime:restart'
    end
  end
end


desc 'Setup monit scripts symlink'
task :monit_scripts_symlinking do
  # creating symlinks for monit scripts
  queue "echo '--------------->Creating symlink for monit scripts'"
  queue! "sudo ln -nfs #{deploy_to}/#{current_path}/scripts/monit/delayed_job.config /etc/monit/conf.d/delayed_job.config"
  queue! "sudo ln -nfs #{deploy_to}/#{current_path}/scripts/monit/sidekiq.config /etc/monit/conf.d/sidekiq.config"
  queue! "sudo ln -nfs #{deploy_to}/#{current_path}/scripts/monit/redis.config /etc/monit/conf.d/redis.config"
  queue! "sudo ln -nfs #{deploy_to}/#{current_path}/scripts/monit/puma.config /etc/monit/conf.d/puma.config"
  queue! "sudo ln -nfs #{deploy_to}/#{current_path}/scripts/monit/faye.config /etc/monit/conf.d/faye.config"
  queue! "sudo ln -nfs #{deploy_to}/#{current_path}/scripts/monit/mysql.config /etc/monit/conf.d/mysql.config"
  queue! "sudo ln -nfs #{deploy_to}/#{current_path}/scripts/monit/nginx.config /etc/monit/conf.d/nginx.config"

end

desc 'Removing expired wait lists through cron jobs'
task :update_cron_tab => :environment do
  queue "echo '--------------->Updating Cron tab'"
  queue 'bundle exec whenever -w'
end


namespace :faye do
  desc "Restart Faye Server"
  task :restart do
    queue %[echo "-----> Faye starting in #{rails_env}"]
    queue "cd #{deploy_to}/#{current_path}/scripts && bash faye.sh restart"
  end

end

namespace :nginx do
  desc 'Restart Nginx Server'
  task :restart do
    queue "echo '--------------->Restarting nginx...!'"
    queue 'sudo /etc/init.d/nginx restart'
  end
end


namespace :monit do
  desc 'Reload Monit'
  task :reload do
    queue "echo '--------------->Reloading monit...!'"
    # queue 'sudo monit reload'
  end
end

namespace :sidekiq do
  desc "Restart Sidekiq"
  task :restart do
    queue %[echo "-----> Sidekiq starting in #{rails_env}"]
    queue "cd #{deploy_to}/#{current_path}/scripts && bash sidekiq.sh #{rails_env} restart"
  end

end

namespace :delayed_job do
  desc "Restart Delayed_job"
  task :restart do
    queue %[echo "-----> Delayed_job starting in #{rails_env}"]
    queue "cd #{deploy_to}/#{current_path}/scripts && bash delayed_job.sh #{rails_env} restart"
  end

end


namespace :puma do
  desc "Restart the application"
  task :restart do
    queue 'echo "-----> Restarting Puma Server"'
    queue "cd #{deploy_to}/#{current_path}/scripts && bash puma.sh #{rails_env} restart"
  end

end


# all rake tasks need to run once after new db setup
namespace :rake_tasks do
  desc 'Execute all rake task with db:seed'
  task :start_execution => :environment do
    queue "echo '---------------> Running rake tasks in #{rails_env}' "
    queue "echo '--------------->Executing rake db:seed' "
    queue "cd #{deploy_to}/#{current_path} && RAILS_ENV=production bundle exec rake db:seed"
    queue "echo '--------------->Executing add_drop_down rake task'"
    queue "cd #{deploy_to}/#{current_path} && RAILS_ENV=production bundle exec rake adding_tab_models"
    queue "cd #{deploy_to}/#{current_path} && RAILS_ENV=production bundle exec rake remove_tab_models"
    queue "echo '--------------->Executing opustime_time_zones rake task'"
    queue "cd #{deploy_to}/#{current_path} && RAILS_ENV=production bundle exec rake timeZone:save"
    queue "cd #{deploy_to}/#{current_path} && RAILS_ENV=production bundle exec rake timeZone:save_formatted"
    queue "echo '--------------->Executing set_value_into_additional_tab rake task'"
    queue "cd #{deploy_to}/#{current_path} && RAILS_ENV=production bundle exec rake set_blank_addition_tab_with_value"
    queue "echo '--------------->Executing wait_list_removal rake task'"
    queue "cd #{deploy_to}/#{current_path} && RAILS_ENV=production bundle exec rake auto_remove_waitlist_on_expire"
    # Restart application
    invoke :'opustime:restart'

  end
end

namespace :opustime do
  desc 'Restart all services'
  task :restart => :environment do
    queue "echo '--------------->Restarting Application' "
    invoke :'update_cron_tab'
    invoke :'puma:restart'
    invoke :'sidekiq:restart'
    invoke :'delayed_job:restart'
    invoke :'faye:restart'
    invoke :'monit:reload'
    invoke :'nginx:restart'
  end

end


desc "Rolls back the latest release"
task :rollback => :environment do
  queue! %[echo "-----> Rolling back to previous release for instance: #{domain}"]

  # Delete existing sym link and create a new symlink pointing to the previous release
  queue %[echo -n "-----> Creating new symlink from the previous release: "]
  queue %[ls "#{deploy_to}/releases" -Art | sort | tail -n 2 | head -n 1]
  queue! %[ls -Art "#{deploy_to}/releases" | sort | tail -n 2 | head -n 1 | xargs -I active ln -nfs "#{deploy_to}/releases/active" "#{deploy_to}/current"]

  # Remove latest release folder (active release)
  queue %[echo -n "-----> Deleting active release: "]
  queue %[ls "#{deploy_to}/releases" -Art | sort | tail -n 1]
  queue! %[ls "#{deploy_to}/releases" -Art | sort | tail -n 1 | xargs -I active rm -rf "#{deploy_to}/releases/active"]
  # Restart application
  invoke :'opustime:restart'
end

desc 'Setup monit scripts symlink'
task :monit_scripts_copying => :environment do
  # copying monit scripts
  queue "echo '--------------->Copy monit scripts local to remote'"
  queue! "sudo cp -f #{deploy_to}/#{current_path}/scripts/monit/* /etc/monit/conf.d/"
  # copying shell scripts
  queue! "sudo cp -f #{deploy_to}/#{current_path}/scripts/* #{deploy_to}/shared/scripts"
  # Restart application
  invoke :'opustime:restart'
end
