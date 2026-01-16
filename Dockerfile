# Stage 1: Build the Flutter Web App
FROM debian:latest AS build-env

# Install dependencies for Flutter
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Clone Flutter SDK
RUN git clone https://github.com/flutter/flutter.git -b stable /usr/local/flutter
ENV PATH="/usr/local/flutter/bin:/usr/local/flutter/bin/cache/dart-sdk/bin:${PATH}"

# Run flutter doctor to download binaries
RUN flutter doctor

# Copy app source code
WORKDIR /app
COPY . .

# Build the web application
# Note: Cleaning before build ensures no stale artifacts are included
RUN flutter clean && \
    flutter pub get && \
    flutter build web --release --no-tree-shake-icons

# Stage 2: Serve via Nginx
FROM nginx:alpine

# Copy the build artifacts
COPY --from=build-env /app/build/web /usr/share/nginx/html

# Expose port (Cloud Run defaults to 8080)
EXPOSE 8080

# Overwrite default Nginx config to listen on 8080
RUN echo "server { listen 8080; location / { root /usr/share/nginx/html; index index.html index.htm; try_files \$uri \$uri/ /index.html; } }" > /etc/nginx/conf.d/default.conf

# Start Nginx
CMD ["nginx", "-g", "daemon off;"]
