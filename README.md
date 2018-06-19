# Srcrumwell

Rails project that integrates Trello for scrum management that's hopefully smarter than the average sprint.


## Installation

Srcrumwell is designed to be run locally on the Rails development server with a PostgreSQL database.

### Prerequisites

- [Ruby 2.5+](https://www.ruby-lang.org/en/downloads/)
- [PostgreSQL 9+](http://www.postgresql.org/)
- [Bundler](http://bundler.io/)
- [Git](http://git-scm.com/)

For help setting up Rails, see [gorails.com](https://gorails.com/setup/).

### Rails

Install the application itself using git:

    git clone https://github.com/klenwell/scrumwell.git

Install gems:

    cd scrumwell
    bundle install

### Database

Create your application's postgres database user:

    # Use postgres command line interface
    psql

    # SQL commands
    CREATE USER scrumwell WITH PASSWORD 'scrumwell';
    ALTER ROLE scrumwell SUPERUSER;

Setup database:

    bundle exec rake db:setup
    bundle exec rake db:setup RAILS_ENV=test
