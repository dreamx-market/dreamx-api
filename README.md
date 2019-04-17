# Dependencies:

* ruby 2.5.1p57
* bundler 1.16.1
* postgresql 10.4
* redis-server 4.0.10

# Dev dependencies

* ganache-cli 6.1.8

# Deployment:

* https://gorails.com/deploy/ubuntu/18.04
* start redis at boot `sudo systemctl enable redis-server.service`
* override necessary environment variables
* double-check, make sure CONTRACT_ADDRESS is deployed, PRIVATE_KEY is funded, ETHEREUM_HOST is pointing to the right network
* add domain
* add ssl certificate https://certbot.eff.org/lets-encrypt/ubuntubionic-nginx
* add tokens & markets

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

#### Cannot create extension "citext"

Are you getting the following error when running your Capistrano deployment?

```
PG::InsufficientPrivilege: ERROR:  permission denied to create extension "citext"
HINT:  Must be superuser to create this extension.
: CREATE EXTENSION IF NOT EXISTS "citext"
```

You will need to temporarily make your database user a superuser.

1. Connect to the server: `$ ssh user@server`
2. Connect to PostgreSQL as the superuser (not your database user):

    ```
    $ sudo su postgres
    $ \psql
    ```
3. Make your database user a superuser: `$ alter role your_user superuser;`
4. Run `cap production deploy` from your local machine. This time it should succeed
5. Remove superuser from your database user: `$ alter role your_user nosuperuser;`
6. Leave PostgreSQL shell: `$ \q`

# Running the test suite

* rake ganache:up
* rake test

# Remaining issues

* scalability of the front-end based matching engine
