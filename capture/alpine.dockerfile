# apk (native) + deno — both cheap on a plain alpine base.
FROM alpine:3

RUN apk add --no-cache deno
