# Ruby version that works well with Rails 4.2 and the updated Gemfile
FROM ruby:2.6.10

# Install system dependencies for Rails, sqlite3, and native extensions
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
      build-essential \
      nodejs \
      libsqlite3-dev && \
    rm -rf /var/lib/apt/lists/*

# App directory
ENV APP_HOME=/opt/mowoli
WORKDIR $APP_HOME

# Use a separate bundle path so gems are cached across builds
ENV BUNDLE_PATH=/bundle \
    BUNDLE_BIN=/bundle/bin \
    GEM_HOME=/bundle \
    PATH="/bundle/bin:${PATH}"

# Bundler version compatible with this app
RUN gem install bundler -v 1.17.3

# Install gems (do this before copying the full app to leverage Docker cache)
COPY Gemfile Gemfile.lock ./
RUN bundle _1.17.3_ install --jobs=4 --retry=3

# Now copy the rest of the app
COPY . .

# Runtime directories (for DB, MWL, HL7 export)
RUN mkdir -p var/mwl var/db var/hl7
VOLUME ["${APP_HOME}/var/mwl", "${APP_HOME}/var/db", "${APP_HOME}/var/hl7"]

# Environment variables used by the app
ENV MWL_DIR="${APP_HOME}/var/mwl" \
    HL7_EXPORT_DIR="${APP_HOME}/var/hl7" \
    SCHEDULED_PERFORMING_PHYSICIANS_NAME="Simpson^Bart" \
    ISSUER_OF_PATIENT_ID="MOWOLI" \
    RAILS_ENV=development

# Rails / Puma listens on 3000 by default
EXPOSE 3000

# Start the app with Puma
#CMD ["bundle", "exec", "puma", "--config", "config/puma.rb"]
CMD ["bash", "-lc", "bundle exec rake db:migrate RAILS_ENV=${RAILS_ENV:-development} && bundle exec puma --config config/puma.rb"]

