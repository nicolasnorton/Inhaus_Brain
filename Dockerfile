# Stage 1: Build Flutter Web
FROM debian:latest AS build-env

# Install dependencies
RUN apt-get update && apt-get install -y curl git wget unzip python3

# Install Flutter
RUN git clone https://github.com/flutter/flutter.git /usr/local/flutter
ENV PATH="/usr/local/flutter/bin:/usr/local/flutter/bin/cache/dart-sdk/bin:${PATH}"

# Run flutter doctor to initialize
RUN flutter doctor

# Copy project files
WORKDIR /app
COPY . .

# Get dependencies and build web
RUN flutter pub get
RUN flutter build web --release

# Stage 2: Serve with Nginx
FROM nginx:alpine
COPY --from=build-env /app/build/web /usr/share/nginx/html

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
