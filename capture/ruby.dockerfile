# rspec — the gem alone; a Gemfile-less crash is exactly what we're after.
FROM ruby:3-alpine

RUN gem install --no-document rspec
