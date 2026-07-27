# apk (native to the base) + deno, from the alpine community repo.
FROM lowfat-capture-base

RUN apk add --no-cache deno
