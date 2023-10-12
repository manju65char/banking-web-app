FROM openjdk:11
ARG JAR_FILE=target/*.jar
COPY ${JAR_FILE} app.jar

# Set an environment variable to specify the port
ENV PORT 8083

# Expose the port for the container
EXPOSE ${PORT}

# CMD instruction to run the application with the specified port
CMD ["java", "-jar", "/app.jar", "--server.port=${PORT}"]


# Stage 1: Build the application
# FROM openjdk:11 AS builder
# WORKDIR /app
# COPY . /app
# RUN ./mvnw clean package

# Stage 2: Create the final image
# FROM openjdk:11
# ARG JAR_FILE=target/*.jar

# Copy the JAR file from the builder stage
# COPY --from=builder /app/${JAR_FILE} /app/app.jar

# Set an environment variable to specify the port
# ENV PORT 8083

# Expose the port for the container
# EXPOSE ${PORT}

# CMD instruction to run the application with the specified port
# CMD ["java", "-jar", "/app/app.jar", "--server.port=${PORT}"]

