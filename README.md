# 概要
`VSCode` + `Docker` + `Docker-compose` +`Rails`のデバッグの設定

# 事前設定
以下がインストールされている事
- **Docker Desktop**
- **Visual Studio Code**
- **VSCode rdbg Ruby Debugger**

# 環境構築
- `Dockerfile`の構成は下記
```Dockerfile
FROM ruby:3.2.2
ENV LANG=ja_JP.UTF-8
ENV TZ=Asia/Tokyo

RUN apt-get -y update && apt-get install -y \
    build-essential \
    libpq-dev \
    nodejs && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /web
COPY Gemfile /web/Gemfile
COPY Gemfile.lock /web/Gemfile.lock

RUN bundle install
```

- `compose.yml`の構成は下記
`compose.yml`には、デバッグを行う為の設定を記述
(`dbg -n --open --host 0.0.0.0 --port 12345`と`"12345:12345"`がデバッグ用の設定となる)
```compose.yml
version: "3.9"
services:
  db:
    container_name: pgsql
    image: postgres:latest
    env_file: ./db/conf/.env
    volumes:
      - ./db/postgres_volume:/var/lib/postgresql/data
    ports:
      - "5432:5432"
    restart: always
  web:
    container_name: ruby_debug_environment
    build: ./web
    command: >
      bash -c "
        rm -f tmp/pids/server.pid &&
        bundle install &&
        rails db:migrate &&
        rdbg -n --open --host 0.0.0.0 --port 12345 -c -- bundle exec rails s -p 3000 -b '0.0.0.0'
      "
    volumes:
      - ./web:/web
    ports:
      - "3000:3000"
      - "12345:12345"
    depends_on:
      - db

```

- `DB`用の`env`ファイルを作成する。　必要に応じて追加も可能
```db/conf/.env
POSTGRES_USER=任意のユーザー名
POSTGRES_PASSWORD=任意のパスワード
POSTGRES_DB=任意のDB名
```

- `Rails`の環境を作成するコマンド
```sh
docker-compose run web rails new . --force --database=postgresql --skip-docker --skip-test
```

- `Gemfile`に下記を記載する
(`Rspec`、`debug`を追加)
```ruby
# RubyでHTTPリクエストを簡単に扱うためのライブラリ
gem 'faraday'

group :development, :test do
  # デバッグ導入
  gem "debug"

  # Rspecの導入
  gem 'rspec-rails'
  gem 'factory_bot_rails'
end
```

- 再度、ビルドを行う
```sh
docker compose build --no-cache

# docker imageのnoneを消去
docker rmi $(docker images -f "dangling=true" -q)
```

- `database.yml`の`development`と`test`に`.env`で記載した`DB`情報を記載する
<font color="red">※ 下記は入力例</font>
```database.yml
default: &default
  adapter: postgresql
  encoding: unicode
  # For details on connection pooling, see Rails configuration guide
  # https://guides.rubyonrails.org/configuring.html#database-pooling
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>

development:
  <<: *default
  database: # 任意のDB名
  username: # 任意のユーザー名
  password: # 任意のパスワード
  host: db # サービス名を記述する(基本はdb)
  port: 5432

test:
  <<: *default
  database: # 任意のDB名
  username: # 任意のユーザー名
  password: # 任意のパスワード
  host: db # サービス名を記述する
  port: 5432
```

- `DB`を作成する
```sh
docker compose run web rails db:create
```

- コンテナーを立ち上げる
```sh
docker compose up -d
```

- `Rspec`を導入する
```sh
docker exec ruby_debug_environment bundle exec rails g rspec:install
```


# デバッグの設定方法
## launch.jsonの設定
- 通常のデバッグと`Rspec`のデバッグの設定を`launch.json`に記載する
:::note warn
- Rspecのデバッグをする場合は、ローカル環境に`Ruby`と`Rails`が動作する環境を構築する必要があります
:::
```launch.json
{
    "version": "0.2.0",
    "configurations": [
        # 通常のデバッグ設定
        {
            "type": "rdbg",
            "name": "Debug Ruby",
            "request": "attach",
            "debugPort": "localhost:12345",
            "localfsMap": "/app:${workspaceFolder}",
        },
        # Rspecのデバッグ設定
        {
            "type": "rdbg",
            "name": "Debug Rspec with current file",
            "rdbgPath": "bundle exec rdbg",
            "request": "launch",
            "command": "rspec",
            "script": "${file}",
            "args": ["-p", "port番号"],
            "askParameters": true,
            "env": {
                "DATABASE_URL": "データベースの種類://DBのユーザー名:DBのパスワード@localhost:port番号/接続するデータベースの名"
            }
        }
    ]
}
```

- `env`に、`Rspec`で使用するテスト`DB`の接続情報を記載する事で、`Rspec`のデバッグ起動時に、その`DB`を参照する
- `DATABASE_URL`には、`/config/database.yml`の`test`に記載した内容を記述する
```json
# 入力例
"env": {
    "DATABASE_URL": "postgresql://root:postgres@localhost:5432/ruby_debug_development_test"
}
```

# 参考記事
- [[公式]クィックスタート: Compose と Rails](https://docs.docker.jp/compose/rails.html)
- [[公式]vscode-rdbg](https://github.com/ruby/vscode-rdbg)
- [Docker上のRailsアプリをvscode-rdbgのTCP/IP接続でリモートデバッグする](https://zenn.dev/trysmr/articles/3f63e7622ef5e4)
- [VSCodeでDockerを使ったRailsを開発しよう~Ruby3.1以降 Debug編~](https://blog.uzumaki-inc.jp/vscodedockerrailsruby31-debug)

