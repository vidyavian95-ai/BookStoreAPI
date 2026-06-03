# stage-1 -build the application
FROM maven:3.9.6-eclipse-temurin-17 AS build
WORKDIR /app
COPY pom.xml .
RUN mvn dependency:go-offline
COPY src ./src
RUN mvn clean package
RUN pwd && ls -lrt 

# stage-2 -create image

FROM eclipse-temurin:17-jdk-alpine 
WORKDIR /app
COPY --from=build app/target/*.jar app.jar
EXPOSE 8080
CMD ["java", "-jar", "app.jar"]