# yarn / npm / pnpm — one runtime, three package managers.
# yarn from the alpine repos is 1.x (classic), which is the line the committed
# samples are written against; pnpm has no alpine package, so it comes from npm.
FROM lowfat-capture-base

RUN apk add --no-cache nodejs npm yarn \
    && npm install -g --no-fund --no-audit pnpm
