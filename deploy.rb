#变量定义到~/.zshrc
#export CAP_RVM_RUBY=ruby-1.9.3-p194
#export CAP_PORT=10000
#export CAP_WEB_HOST=188.188.188.188
#export CAP_APP_HOST=$CAP_WEB_HOST
#export CAP_DB_HOST=$CAP_WEB_HOST
#export CAP_USER=deploy
require "rvm/capistrano"                                 # Load RVM's capistrano plugin.
require "bundler/capistrano" # 集成bundler和rvm
require "delayed/recipes"
set :rails_env, "production"                             #added for delayed job
set :rvm_ruby_string, ENV['CAP_RVM_RUBY']                # Or whatever env you want it to run in.
set :rvm_type, :user                                     # Copy the exact line. I really mean :user here
#set :bundle_flags,    "--deployment --verbose"          # Just for debug

set :application, "rails_app_name"
set :port, ENV['CAP_PORT']
role :web, ENV['CAP_WEB_HOST']                          # Your HTTP server, Apache/etc
role :app, ENV['CAP_APP_HOST'], jobs: true              # This may be the same as your `Web` server
role :db,  ENV['CAP_DB_HOST'], primary: true            # This is where Rails migrations will run
#role :db,  "your slave db-server here"


set :repository,  "git://github.com/saberma/shopqi-app-#{application}.git"
set :scm, :git
set :deploy_to, "/u/apps/shopqiapp/#{application}" # default
set :deploy_via, :remote_cache # 不要每次都获取全新的repository
set :branch, "master"
set :user, :shopqiapp
set :use_sudo, false

set :pids_path, "#{shared_path}/pids"

depend :remote, :gem, "bundler", ">=1.0.21" # 可以通过 cap deploy:check 检查依赖情况

# If you are using Passenger mod_rails uncomment this:
namespace :deploy do

  task :start do
    run "cd #{current_path} ; bundle exec unicorn_rails -c config/unicorn.rb -D"
  end

  task :stop do
    run "kill -s QUIT `cat #{pids_path}/unicorn.#{application}.pid`"
  end

  task :restart, roles: :app, except: { no_release: true } do
    run "kill -s USR2 `cat #{pids_path}/unicorn.#{application}.pid`"
  end

end

after "deploy:stop",    "delayed_job:stop"
after "deploy:start",   "delayed_job:start"
after "deploy:restart", "delayed_job:restart"
