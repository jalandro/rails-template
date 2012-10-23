# encoding: utf-8
#rails new shopkit_app -d sqlite3 -T
# see http://rdoc.info/github/wycats/thor/master/Thor/Actions.html
# 统一获取交互参数
is_shopqi_app = yes?('as ShopQi app?(install shopqi-app and shopqi-app-webhook gem)')
if is_shopqi_app
  client_id = ask('Your ShopQi app client_id?') || 'f04bfb5c3f6a0380e2a8f5c64a1aed6bdb1ac7554e0a77a3f1992e087bce3479'
  secret = ask('Your ShopQi app secret?') || '7d561bb675cf3eba72830a99f0c70321d822643219b89a43b7b329ca9426a503'
  app_name = ask('Your ShopQi app name?') || '快递跟踪'
end

##### Gem 安装 #####
gem "devise"
# ShopQi
if is_shopqi_app
  gem 'shopqi-app'
  gem 'shopqi-app-webhook'
end
# 实体
gem 'settingslogic' # 用于保存密钥等信息
#gem 'seedbank'
# 视图
unless is_shopqi_app
  gem 'haml'
  gem 'bootstrap-sass'
end
gem 'jquery-rails'
gem 'spine-rails'
gem 'ruby-haml-js'
# 后台任务、定时
gem 'whenever', require: false
# 其他
gem 'exception_notification' # 出现异常时要发邮件给管理员
# 部署
gem 'unicorn'
# 开发
gem_group :development do
  gem 'haml-rails'
  gem 'rvm-capistrano', '~> 1.2.5'
  gem 'letter_opener' # 发送的邮件直接在浏览器中打开
  gem 'guard-livereload'
  gem 'guard-spork'
  gem 'guard-rspec'
  gem 'guard-bundler'
  gem 'guard-unicorn'
  #gem 'guard-delayed'
end
# 测试
gem_group :test do
  gem "rspec-rails"
  gem "factory_girl_rails"
  gem 'capybara'
  gem 'database_cleaner'
end
gem_group :development, :test do
  gem "awesome_print"
end
gsub_file 'Gemfile', /#\s*(gem 'therubyracer')/, '\1'
run 'bundle install'


##### 基本配置 #####
insert_into_file 'config/database.yml', "  host: localhost\n", after: "encoding:\sunicode\n", force: true
run "cp config/database.yml config/database.yml.example" # 项目内拷贝
gsub_file 'config/database.yml', /username:.+/, "username: #{ENV['DB_USERNAME'] || :postgres}"
gsub_file 'config/database.yml', /password:.+/, "password: #{ENV['DB_PASSWORD']}"
insert_into_file 'config/database.yml', "  port: #{ENV['DB_PORT'] || 5432}\n", after: "database: #{app_name}_production\n"

insert_into_file 'config/environments/development.rb', "  config.action_mailer.delivery_method = :letter_opener\n", after: "config.action_mailer.raise_delivery_errors = false\n"
insert_into_file 'config/environments/production.rb', "  config.action_mailer.delivery_method = :sendmail\n", after: "config.action_mailer.raise_delivery_errors = false\n"
gsub_file 'config/initializers/backtrace_silencers.rb', /#\s*(# Rails.backtrace_cleaner.remove_silencers!)/, '\1'
insert_into_file 'config/application.rb', after: 'config.autoload_paths += %W(#{config.root}/extras)' do <<-'RUBY'

    config.autoload_paths += %W(#{config.root}/lib)
RUBY
end
rake "db:drop db:create"
generate 'devise:install', "--force"


##### 扩展工具 #####
create_file 'config/initializers/datetime_format.rb', <<-END
Time::DATE_FORMATS.merge!(
  :serial => "%Y%m%d",
  :full => "%Y-%m-%d %H:%M:%S",
  :short => "%m-%d %H:%M",
)

#Date::DATE_FORMATS.merge!()
END


##### 测试环境 #####
generate 'rspec:install', "--force"
run 'guard init'
run 'spork --bootstrap'
insert_into_file 'config/application.rb', after: "Rails::Application\n" do <<-RUBY

      # don't generate RSpec tests for views and helpers
      config.generators do |g|
        g.template_engine :haml
        g.test_framework :rspec, fixture: true, views: false
        g.fixture_replacement :factory_girl, dir: "spec/factories"
        g.stylesheets false
        g.javascripts false
        g.helper false
        g.view_specs false
        g.helper_specs false
      end
RUBY

end


##### 前端配置 #####
remove_file 'README.rdoc'
create_file 'README.md'
remove_file 'public/index.html'
remove_file 'public/favicon.ico'
get         'https://github.com/saberma/rails-template/blob/master/favicon.ico?raw=true', 'public/favicon.ico'
remove_file 'app/assets/stylesheets/application.css'
create_file 'app/assets/stylesheets/application.css.scss.erb'
remove_file 'app/assets/javascripts/application.js'
create_file 'app/assets/javascripts/application.js.coffee', <<-END
#= require jquery
#= require jquery_ujs
#= require_tree .

$(document).ready ->

END


##### 生成默认控制器 #####
generate :controller, "home index", "--force"
gsub_file 'config/routes.rb', "get \"home/index\"\n", ''
route "root :to => 'home#index'"


##### 生成 ShopQi 应用 #####
if is_shopqi_app
  generate :shopqi_app, "#{client_id} #{secret} --force"
  generate :shopqi_app_webhook, "--force"
  run 'bundle install'
  rake "db:migrate"
  rake "db:migrate", env: :test
  gsub_file 'config/app_secret_config.yml', 'app_name: ShopQi App Example', "app_name: #{app_name}"
  run "cp config/app_secret_config.yml config/app_secret_config.yml.example"
  gsub_file 'config/app_secret_config.yml.example', client_id, 'f04bfb5c3f6a0380e2a8f5c64a1aed6bdb1ac7554e0a77a3f1992e087bce3479'
  gsub_file 'config/app_secret_config.yml.example', secret, '7d561bb675cf3eba72830a99f0c70321d822643219b89a43b7b329ca9426a503'
end


##### 定时任务 #####
run 'wheneverize .'


##### travis-ci #####
create_file '.travis.yml', <<-END
language: ruby

rvm: 1.9.3

script:
  - bundle exec rake db:drop db:create db:schema:load --trace 2>&1
  - bundle exec rspec spec
END


##### Git #####
append_to_file '.gitignore', <<-END
.DS_Store

config/unicorn.conf.rb
config/database.yml
config/app_secret_config.yml
END
git :init
git add: ".", commit: "-m 'initial commit'"
