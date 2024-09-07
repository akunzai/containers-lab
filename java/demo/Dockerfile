# https://hub.docker.com/_/maven
FROM maven:3-eclipse-temurin-17 AS builder
WORKDIR /src
COPY . .
RUN --mount=type=cache,target=/root/.m2 mvn clean package

# https://hub.docker.com/_/eclipse-temurin
FROM eclipse-temurin:17-jre
WORKDIR /app
COPY --from=builder /src/target/*.jar ./app.jar
EXPOSE 8080
ENV JAVA_OPTS=""
USER www-data
CMD ["sh","-c","java $JAVA_OPTS -jar /app/app.jar"]