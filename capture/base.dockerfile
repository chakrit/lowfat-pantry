# The one place `alpine:3` is named. Every stack builds FROM lowfat-capture-base,
# so the distro choice moves here instead of being restated eight times.
#
# What belongs in this layer is what the *toolchain installers* need — composer's
# installer, gem's fetch, maven's downloads all reach out over TLS — not anything
# the captured commands themselves use. A capture runs the tool and nothing else,
# so adding conveniences here would change the image without changing a sample.
FROM alpine:3

RUN apk add --no-cache ca-certificates curl grep
