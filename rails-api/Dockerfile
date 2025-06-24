# Use the official Ruby image as a base image
FROM ruby:3.1.2

# Install dependencies
RUN apt-get update -qq && apt-get install -y nodejs postgresql-client

# Set environment variables
ENV RAILS_ROOT /var/www/rails-api
WORKDIR $RAILS_ROOT

# Install bundler
RUN gem install bundler -v 2.3.11

# Copy the Gemfile and Gemfile.lock into the Docker image
COPY Gemfile Gemfile.lock ./

# Install gems
RUN bundle install

# Copy the main application
COPY . ./

# Ensure proper ownership and permissions
RUN chown -R 1000:1000 $RAILS_ROOT

# Expose port 3000 to the Docker host, so we can access it from the outside
EXPOSE 4000

# The command to run the Rails server
CMD ["bash", "-c", "rm -f tmp/pids/server.pid && bundle exec rails s -b '0.0.0.0' -e ${RAILS_ENV}"]
