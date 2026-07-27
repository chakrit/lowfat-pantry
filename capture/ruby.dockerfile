# rspec — the gem alone; a Gemfile-less crash is exactly what we're after.
FROM lowfat-capture-base

RUN apk add --no-cache ruby \
    && gem install --no-document rspec
