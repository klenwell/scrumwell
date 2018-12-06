# Scrumwell

Rails project that integrates with Trello to provide work-in-progress (WIP) analytics for improved scrum management.


## Conventions

In the spirit of Rails's conventions-over-configuration ethos, this application requires a Trello board to adopt a few conventions before it can be compatible.

- Set up the following lists to track stories in progress:
  - Wish Heap
  - Groomed Backlog
  - Current Sprint Backlog
- To track completed stories, add a list for each sprint with this name format (YYYYMMDD will be the date the sprint ends):
  - Sprint YYYYMMDD completed
- Install plugin Agile Tools by Corrello and use it to record card user story sizes.

For an example, see this project's own Trello board:

- https://trello.com/b/vmyLroUQ/scrumwell


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

To edit the `credentials.yml.enc` file:

    EDITOR=vi rails credentials:edit

To reset the encrypted `credentials.yml.enc` file:

    rm config/credentials.yml.enc
    EDITOR=vi rails credentials:edit

Then copy-paste contents of `credentials.yml-dist` where indicated below into vi buffer and update values as needed.

### Config Files

Permissions are associated with a Google account and set in the `auth_groups.yml`. First copy over the `-dist` version

    cp -v config/auth_groups.yml{-dist,}

Then edit the file to add users to groups by an email address associated with a Google account.

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

Purge development database:

    rake db:schema:load


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

#### False Positives

To ignore Brakeman warnings, use the `-I` option:

    bundle exec brakeman -I

For more information, see https://brakemanscanner.org/docs/ignoring_false_positives/.

### Local Server

To start the local server:

    bundle exec rails server -b 0.0.0.0 -p 3000

From your browser, head to http://localhost:3000

### Command Line

See lib/tasks for rake modules. To import the Scrumwell Trello board:

    rake scrum:import_board[5b26fe3ad86bfdbb5a8290b1]
