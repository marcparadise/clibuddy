FROM ruby:latest

RUN mkdir /usr/src/app
ADD . /usr/src/app
WORKDIR /usr/src/app
RUN bundle install

RUN mkdir -p /share
VOLUME ["/share"]

WORKDIR /share
ENTRYPOINT ["bundle", "exec", "/usr/src/app/bin/clibuddy", "run"]
