# Dependencies:

* ruby 2.5.1p57
* postgresql 10.4
<!-- * redis-server 4.0.10 -->

# Dev dependencies

* ganache-cli 6.1.8

# Deployment:

* create a postgresql superuser for production environment, add it into config/database.yml
* duplicate config/application.yml.sample into config/application.yml to set environemnt variables
* rake db:create
* rake db:migrate

# Running the test suite

* rake ganache:up
* rake test
