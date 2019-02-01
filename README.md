# Dependencies:

* ruby 2.5.1p57
* postgresql 10.4

# Deployment:

* create a postgresql superuser for production environment, add it into config/database.yml
* set environment variables in config/application.yml
* rake db:create
* rake db:migrate
