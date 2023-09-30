FROM openjdk:11
ARG JAR_FILE=target/*.jar
COPY ${JAR_FILE} app.jar

# Set an environment variable to specify the port
ENV PORT 8083

# Expose the port for the container
EXPOSE ${PORT}

# CMD instruction to run the application with the specified port
CMD ["java", "-jar", "/app.jar", "--server.port=${PORT}"]

