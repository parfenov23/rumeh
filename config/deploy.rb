# config valid only for current version of Capistrano
lock '3.17.3'

set :application, 'rumeh'
set :repo_url, 'git@github.com:parfenov23/rumeh.git'
if ENV['branch'].nil? || ENV['branch'].empty?
  set :branch, 'main'
else
  set :branch, ENV['branch']
end


set :scm, :git

# Root directory with source code
set :deploy_to, ->{ fetch(:app_dir) }

# Shared directories
set :linked_dirs, %w{log tmp/pids tmp/cache tmp/sockets public/assets public/images public/static public/uploads/offer_m public/uploads/offer_e public/system}
set :linked_files, %w(.env)

# Count stored releases
set :keep_releases, 5
