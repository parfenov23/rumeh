set :app_dir, '/home/rumeh.ru/kernel'
server 'root@62.217.181.245', roles: %w{app db web}

# Specify rails app environment
set :rails_env, 'production'
set :nginx_server_name, 'rumeh.ru'

# Specify ruby version (for bundler)
set :rbenv_ruby, '2.7.0'