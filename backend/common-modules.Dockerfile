# common-modules.Dockerfile

FROM maven:3.8.5-openjdk-11-slim as common-builder

WORKDIR /app

# Copy only pom.xmls first to leverage Docker layer caching
COPY common-service/pom.xml common-service/
COPY common-student/pom.xml common-student/
COPY common-exam/pom.xml common-exam/

# Now copy actual source code
COPY common-service /app/common-service
COPY common-student /app/common-student
COPY common-exam /app/common-exam

# Build and install to local .m2
RUN mvn install -f common-service/pom.xml && \
    mvn install -f common-student/pom.xml && \
    mvn install -f common-exam/pom.xml

