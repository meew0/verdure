FROM eclipse-temurin:22-alpine
COPY . .
RUN apk update && apk add --virtual build-dependencies build-base ffmpeg
RUN apk add --no-cache ruby ruby-dev
RUN gem install bundler
RUN bundle install
CMD bundle exec ruby app.rb
