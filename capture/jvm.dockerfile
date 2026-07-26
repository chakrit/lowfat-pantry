# mvn — maven from the alpine repos rather than the (much larger) maven image.
FROM eclipse-temurin:21-jdk-alpine

RUN apk add --no-cache maven
