#rails new shopkit_app -d sqlite3 -T
# see http://rdoc.info/github/wycats/thor/master/Thor/Actions.html
is_shopqi_app = yes?('as ShopQi app?(install shopqi-app and shopqi-app-webhook gem)')

##### Gem #####
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
group :development do
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
group :test do
  gem "rspec-rails"
  gem "factory_girl_rails"
  gem 'capybara'
  gem 'database_cleaner'
end


gsub_file 'Gemfile', /#\s*(gem 'therubyracer')/, '\1'

run 'bundle install'
run 'guard init'
run 'spork --bootstrap'

generate 'rspec:install'
generate 'devise:install'

inject_into_file 'config/application.rb', :after => "Rails::Application\n" do <<-RUBY

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

inject_into_file 'config/application.rb', :after => 'config.autoload_paths += %W(#{config.root}/extras)' do <<-'RUBY'

    config.autoload_paths += %W(#{config.root}/lib)
RUBY
end

run "cp config/database.yml config/database.yml.example"
remove_file 'README.rdoc'

append_to_file '.gitignore', <<-END
  .DS_Store

  config/unicorn.conf.rb
  config/database.yml
  config/app_secret_config.yml
END
git :init
git add: ".", commit: "-m 'initial commit'"

remove_file 'public/index.html'
generate(:controller, "home index")

gsub_file 'config/initializers/backtrace_silencers.rb', /#\s*(# Rails.backtrace_cleaner.remove_silencers!)/, '\1'

remove_file 'app/assets/stylesheets/application.css'
create_file 'app/assets/stylesheets/application.css.scss'

remove_file 'app/assets/javascripts/application.js'
create_file 'app/assets/javascripts/application.js.coffee', <<-END
#= require jquery
#= require jquery_ujs
#= require_tree .

$(document).ready ->

END
