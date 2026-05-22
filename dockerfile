FROM eclipse-temurin:17-jdk-alpine
WORKDIR /app
COPY . /app/
RUN mvn clean install
COPY target/*.jar app.jar
EXPOSE 8080
CMD ["java", "-jar", "app.jar"]