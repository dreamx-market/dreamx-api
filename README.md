# Before going live

* fix the lines marked with the 'debugging only' comments

# Dependencies:

* ruby 2.5.1p57
* bundler 1.16.1
* postgresql 10.4
* redis-server 4.0.10

# Dev dependencies

* ganache-cli 6.1.8

# Deployment:

* follow https://gorails.com/deploy/ubuntu/18.04
  * set `server_name` in `/etc/nginx/sites-enabled/dreamx-api` to your specific domain for the certbot
  * when you run `createdb`, the database name must match with the one specified in database.yml
  * you will need to temporarily make your database user a superuser to avoid PG::InsufficientPrivilege on the first deployment:
    1. Connect to the server: `$ ssh user@server`
    2. Connect to PostgreSQL as the superuser (not your database user):
      ```
      $ sudo su postgres
      $ \psql
      ```
    3. Make your database user a superuser: `$ alter role your_user superuser;`
    4. Run `cap production deploy` from your local machine
    5. Remove superuser from your database user: `$ alter role your_user nosuperuser;`
    6. Leave PostgreSQL shell: `$ \q`
  * environment variables that must be set before `cap production deploy`:
    * POSTGRES_USERNAME
    * POSTGRES_PASSWORD
    * SERVER_PRIVATE_KEY
    * CONTRACT_ADDRESS
    * FEE_COLLECTOR_ADDRESS
    * ETHEREUM_HOST (if deploying to main net)
* start redis at boot `sudo systemctl enable redis-server.service`
* double-check, make sure CONTRACT_ADDRESS is not checksummed and deployed, SERVER_PRIVATE_KEY is funded, FEE_COLLECTOR_ADDRESS is not checksummed and is the right address, ETHEREUM_HOST is pointing to the right network
* add domain
* add ssl certificate https://certbot.eff.org/lets-encrypt/ubuntubionic-nginx
* add tokens & markets by running `bundle exec rake db:seed RAILS_ENV=production`
* run `Transaction.sync_nonce` to make sure off-chain nonce is in sync with the current on-chain nonce of `SERVER_PRIVATE_KEY`
* automated daily backup: https://github.com/hieudoan2609/dreamx-api-backup
* log rotation: https://gorails.com/guides/rotating-rails-production-logs-with-logrotate

## Errors

### Error during cap production deploy:

#### Cannot load such file — bundler/setup

1. Make sure `capistrano-rails` is installed

2. Add to Capfile `require 'capistrano/bundler'`

```
require "capistrano/bundler" # Rails needs bundler
require "capistrano/rails/migrations"
require "capistrano/passenger"
require "capistrano/rbenv"
require "whenever/capistrano"
```

# Running the test suite

* clone this repo
* `bundle`
* rake ganache:up
* rake test

# TODOS

* update deployed contract address in contract.md
* WebSocket API compatibility with 3rd-party clients
* replacing the frontend matching engine with a matching engine more scalable

# HANDLING SUPPORT ISSUES

## Deposits of non-listed tokens:

* validate its authenticity, list the tokens as non-tradable and manually create the deposits to match with their on-chain balances for them to withdraw, if happens too frequently, figure out a more effective solution
