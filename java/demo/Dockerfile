# https://hub.docker.com/_/maven
FROM docker.io/library/maven:3-eclipse-temurin-21-alpine AS builder
WORKDIR /src
COPY . .
RUN --mount=type=cache,target=/root/.m2 mvn clean package

# https://hub.docker.com/_/eclipse-temurin
FROM docker.io/library/eclipse-temurin:21-jre-alpine
RUN --mount=type=cache,target=/var/cache/apk,sharing=locked \
	apk update && apk upgrade;
WORKDIR /app
COPY --from=builder /src/target/*.jar ./app.jar
EXPOSE 8080
ENV JAVA_OPTS=""
USER nobody
CMD ["sh","-c","java $JAVA_OPTS -jar /app/app.jar"]