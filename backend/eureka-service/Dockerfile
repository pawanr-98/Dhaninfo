FROM maven:3.9.6-eclipse-temurin-11 AS build
WORKDIR /app
COPY . .

# You're already inside eureka-service, so just use the pom.xml directly
RUN mvn clean package -DskipTests

FROM eclipse-temurin:11-jre-alpine
WORKDIR /app
COPY --from=build /app/target/*.jar app.jar
EXPOSE 8761
ENTRYPOINT ["java", "-jar", "app.jar"]
