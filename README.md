此 template 用于快速生成 Rails 项目、ShopQi App 应用

### 配置(可选)

将以下数据库配置加入 `~/.zshrc` 或者 `~/.bashrc`

    export DB_USERNAME=foo
    export DB_PASSWORD=
    export DB_PORT=5432

### 使用

    rails new project_name -m ../template.rb -d postgresql --skip-test-unit --skip-javascript

### 参考资源

[Generator](http://guides.rubyonrails.org/generators.html)
[Thor's documentation](http://rdoc.info/github/wycats/thor/master/Thor/Actions.html)

### 类似项目

https://github.com/RailsApps/rails-composer

http://railswizard.org (翻墙)
