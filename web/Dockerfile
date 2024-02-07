ARG RUBY_VERSION=3.2.2
FROM ruby:$RUBY_VERSION-slim

ENV LANG=ja_JP.UTF-8 \
    TZ=Asia/Tokyo

WORKDIR /web

RUN apt-get -y update && apt-get install -y \
    build-essential \
    libpq-dev \
    nodejs \
    git && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY Gemfile /web/Gemfile
COPY Gemfile.lock /web/Gemfile.lock

RUN bundle install
