# Dependencies:

* ruby 2.5.1p57
* bundler 1.16.1
* postgresql 10.4
* redis-server 4.0.10

# Dev dependencies

* ganache-cli 6.1.8

# Deployment:

* follow https://gorails.com/deploy/ubuntu/18.04
  * generate a new ssh key for the vps and add it to github with `ssh-keygen`
  * set `server_name` in `/etc/nginx/sites-enabled/dreamx-api` to your specific domain for the certbot
  * when you run `createdb`, the database name must match with the one specified in database.yml
  * environment variables that must be set before `cap production deploy`:
    * POSTGRES_USERNAME
    * POSTGRES_PASSWORD
    * SERVER_PRIVATE_KEY
    * CONTRACT_ADDRESS
    * FEE_COLLECTOR_ADDRESS
    * ETHEREUM_HOST (if deploying to main net)
  * you will need to temporarily make your database user a superuser to avoid PG::InsufficientPrivilege on the first deployment:
    * Connect to PostgreSQL as the superuser (not your database user):
      ```
      $ sudo su postgres
      $ \psql
      ```
    * Make your database user a superuser: `$ alter role your_user superuser;`
    * Run `cap production deploy` from your local machine
    * Remove superuser from your database user: `$ alter role your_user nosuperuser;`
    * Leave PostgreSQL shell: `$ \q`
* start redis at boot `sudo systemctl enable redis-server.service`
* double-check, make sure CONTRACT_ADDRESS is not checksummed and is deployed, SERVER_PRIVATE_KEY is funded, FEE_COLLECTOR_ADDRESS is not checksummed and is the right address, ETHEREUM_HOST is pointing to the right network
* add domain
* add ssl certificate https://certbot.eff.org/lets-encrypt/ubuntubionic-nginx
* add tokens & markets by running `bundle exec rake db:seed RAILS_ENV=production`
* run `Transaction.sync_nonce` to make sure off-chain nonce is in sync with the current on-chain nonce of `SERVER_PRIVATE_KEY`
* log rotation: https://gorails.com/guides/rotating-rails-production-logs-with-logrotate

# Running the test suite

* clone this repo
* `bundle`
* rake ganache:up
* rake test

# TODOS

* update deployed contract address in contract.md
* WebSocket API compatibility with 3rd-party clients
* replacing the frontend matching engine with a matching engine more scalable
* withdrawal-only frontend

# Manual backups

* always shut down the service and perform a manual backup before deploying: https://www.digitalocean.com/docs/databases/postgresql/how-to/import-databases/#export-an-existing-database

# Terminating the exchange

* shut down the server
* terminate the contract
* put up the withdrawal-only frontend to call directWithdraw

# Disaster handling

* shut down nginx: `sudo service nginx start`
* pause block processing: `Config.set('processing_new_blocks', 'false')`
* investigate

# Fee schedule

* order minimum: 0.1 ETH
* taker: 0.1%
* maker: 0.1%
