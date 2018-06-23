# Scrumwell

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

### Credentials

Credentials are encrypted in `credentials.yml.enc`.

To use the existing `credentials.yml.enc` file, you'll need to get the key from the project's current maintainer and add it to the `master.key` file.

To reset the encrypted `credentials.yml.enc` file:

    rm config/credentials.yml.enc
    EDITOR=vi rails credentials:edit

Then copy-paste contents of `credentials.yml-dist` where indicated below into vi buffer and update values as needed.

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


## Development

### Run Tests

    bundle exec rake test

### Code Analysis
[Brakeman](https://github.com/presidentbeef/brakeman) and [Rubocop](https://github.com/bbatsov/rubocop) are configured to run automatically whenever tests are run. To run them independently:

```
# security analysis: this will provide additional detail
bundle exec brakeman

# style analysis
bundle exec rubocop
```

### Local Server

To start the local server:

    bundle exec rails server -b 0.0.0.0 -p 3000

From your browser, head to http://localhost:3000
