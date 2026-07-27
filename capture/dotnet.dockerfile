# dotnet build / test — the SDK from the alpine community repo, not Microsoft's image.
FROM lowfat-capture-base

RUN apk add --no-cache dotnet8-sdk

# The SDK prints a first-run banner and a telemetry notice otherwise, both of which
# would land in a captured sample as output the tool does not normally emit.
ENV DOTNET_NOLOGO=1 \
    DOTNET_CLI_TELEMETRY_OPTOUT=1 \
    DOTNET_SKIP_FIRST_TIME_EXPERIENCE=1
