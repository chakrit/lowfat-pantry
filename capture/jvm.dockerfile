# mvn — the JDK and maven both from the alpine repos.
FROM lowfat-capture-base

RUN apk add --no-cache openjdk21-jdk maven
