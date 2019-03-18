# Dependencies:

* ruby 2.5.1p57
* postgresql 10.4

# Dev dependencies

* ganache-cli

# Deployment:

* create a postgresql superuser for production environment, add it into config/database.yml
* duplicate config/application.yml.sample into config/application.yml to set environemnt variables
* rake db:create
* rake db:migrate
