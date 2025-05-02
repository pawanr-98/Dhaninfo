FROM maven:3.9.6-eclipse-temurin-11 as build
WORKDIR /app
COPY . .

RUN mvn -f common-service/pom.xml install -DskipTests && \
    mvn -f common-student/pom.xml install -DskipTests && \
    mvn -f common-exam/pom.xml install -DskipTests && \
    mvn -f course-service/pom.xml clean package -DskipTests

FROM eclipse-temurin:11-jre-alpine
WORKDIR /app
COPY --from=build /app/course-service/target/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]

