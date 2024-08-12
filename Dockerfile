FROM eclipse-temurin:22-alpine
COPY . .
RUN apk add --no-cache ruby
RUN gem install bundler
RUN bundle install
CMD bundle exec ruby app.rb
