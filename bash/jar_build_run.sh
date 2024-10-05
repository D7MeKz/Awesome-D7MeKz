#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Define variables
PROJECT_DIR=$(pwd)
JAR_FILE="$PROJECT_DIR/build/libs/$(basename $PROJECT_DIR)-0.0.1-SNAPSHOT.jar" # Adjust if necessary

# Clean previous builds
echo "Cleaning previous builds..."
./gradlew clean

# Compile the project and package it as a JAR
echo "Building the project..."
./gradlew build

# Check if the build was successful
if [ -f "$JAR_FILE" ]; then
    echo "Build successful! JAR file created at $JAR_FILE"
else
    echo "Build failed! No JAR file found."
    exit 1
fi

# Run the Spring Boot application
echo "Running the application..."
java -jar "$JAR_FILE"
