# MGetIt with Umlaut, with 360Link

## Setup

1. `git clone https://github.com/mlibrary/mgetit`
2. `bundle install --path .bundle`
3. add a `config/database.yml` example:

    ```yaml
    default: &default
      host: YOUR_HOST_HERE
      adapter: mysql2
      encoding: utf8
      pool: 5
      username: YOUR_USERNAME_HERE
      password: YOUR_PASSWORD_HERE
      database: YOUR_DATABASE_HERE
    development:
      <<: *default
    test:
      <<: *default
    production:
      <<: *default
    ```
4. If needed, adjust `config/application.rb`

    ```ruby
    config.relative_url_root = "/path/to/application"
    config.action_controller.relative_url_root = "/path/to/application"
    ```
    
5. `bundle exec rake db:migrate`
6. `bundle exec rackup`


