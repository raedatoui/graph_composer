require 'capistrano_colors'
require 'capistrano/ext/multistage'
require 'rvm/capistrano'
require 'capistrano/notifier/mail'


set :stages, ['staging', 'production']
set :default_stage, 'staging'

set :application, "generator"

set :notify_emails, ["raed.atoui@gmail.com"]

set :unicorn_pid, Proc.new { "#{current_path}/tmp/pids/unicorn.pid" }

ssh_options[:keys] = [File.join(ENV["HOME"], ".ssh", "id_rsa")]

set :repository,  "git@github.com:raedatoui/generator.git"
set :scm, :git
set :deploy_via, :remote_cache

#RVM
set :rvm_ruby_string, Proc.new { "2.0.0@generator" }       # Or whatever env you want it to run in.
set :rvm_type, :user

set :notifier_mail_options, {
  :method => :smtp, # :smtp, :sendmail, or any other valid ActionMailer delivery method
  :from   => 'raed.atoui@gmail.com',
  :to     => ['raed.atoui@gmail.com', 'raed@your-majesty.com'],
  :github => 'raedatoui/generator',
  :smtp_settings => {
      address: "smtp.gmail.com",
      port: 587,
      domain: "gmail.com",
      authentication: "plain",
      enable_starttls_auto: true,
      user_name: "raed.atoui",
      password: "3ntiss@r151"
    }
}


## Branching ##

# Use master by default
set :branch, "origin/master"

namespace :deploy do

  desc "Deploy application"
  task :default do
    update_code
    unicorn.reload
    notify.mail
  end

  desc "Deploy application with assets only"
  task :warm do
    update_code
    assets.compile
    unicorn.reload
    notify.mail
  end

  desc "Deploy application with migrations, assets and bundling"
  task :cold do
    update_code
    bundle.install
    db.migrate
    assets.compile
    unicorn.reload
    notify.mail
  end

  desc "Setup a git based deployment."
  task :setup, :except => { :no_release => true } do
    # 1. Create gemset since it's needed by all actions
    rvm.create_gemset

    # 2. Remove app if exits
    sudo "rm -rf #{deploy_to}"

    # 3. Create folders
    sudo "mkdir -p #{current_path}"
    sudo "mkdir -p #{shared_path}/tmp"
    sudo "mkdir -p #{shared_path}/log"

    # 4. Set the correct permissions
    sudo "chown -R #{user} #{deploy_to}"

    # 5. Clone the project
    run "git clone #{repository} #{current_path}"

    # 6. Install bundler
    run "cd #{current_path} && /usr/bin/env gem install bundler"
  end

  desc "Update the deployed code."
  task :update_code, :except => { :no_release => true } do
    run "cd #{current_path}; git fetch origin; git reset --hard #{branch}"
    finalize_update
  end

  task :finalize_update, :except => { :no_release => true } do
      run "rm -f #{current_path}/log #{current_path}/tmp"
      run "ln -s #{shared_path}/log #{current_path}/log"
      run "ln -s #{shared_path}/tmp #{current_path}/tmp"
  end
end

namespace :db do
  desc "Migrate"
  task :migrate do
    run "cd #{current_path} && /usr/bin/env rake db:migrate RAILS_ENV=#{stage}"
  end
end

namespace :bundle do
  desc "Run bundle:install"
  task :install, :roles => :app do
    run "cd #{current_path} && /usr/bin/env bundle install"
  end
end

namespace :assets do
    desc "clean and precompile assets"
    task :compile do
        run "cd #{current_path} && /usr/bin/env rake assets:clean RAILS_ENV=#{stage}; rake assets:precompile RAILS_ENV=#{stage}"
    end
end

namespace :unicorn do
  desc "start unicorn"
  task :start, :roles => :app do
    run "cd #{current_path} && bundle exec unicorn_rails -c #{current_path}/config/unicorn_#{stage}.rb -E #{stage} -D"
  end
  desc "stop unicorn"
  task :stop, :roles => :app do
    run "kill `cat #{unicorn_pid}`"
  end
  desc "graceful stop unicorn"
  task :graceful_stop, :roles => :app do
    run "kill -s QUIT `cat #{unicorn_pid}`"
  end
  desc "reload unicorn"
  task :reload, :roles => :app do
    if capture("if [ -e #{unicorn_pid} ]; then echo 'true'; fi").strip == 'true'
      run "kill -s USR2 `cat #{unicorn_pid}`"
    else
      unicorn.start
    end
  end
end