# Stage 1: Build the Flutter Web App
FROM debian:latest AS build-env

# Install dependencies for Flutter
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Clone Flutter SDK
RUN git clone https://github.com/flutter/flutter.git -b stable --depth 1 /usr/local/flutter
ENV PATH="/usr/local/flutter/bin:/usr/local/flutter/bin/cache/dart-sdk/bin:${PATH}"

# Run flutter doctor to download binaries
RUN flutter doctor

# Copy app source code
WORKDIR /app
COPY . .

# Build-time environment variables
ARG VERTEX_API_KEY
ARG GEMINI_API_KEY
ARG OPENAI_API_KEY
ARG ANTHROPIC_API_KEY
ARG VEO_API_KEY
ARG FIREBASE_API_KEY
ARG FIREBASE_PROJECT_ID
ARG FIREBASE_MESSAGING_SENDER_ID
ARG FIREBASE_APP_ID
ARG APP_ENCRYPTION_KEY

# Build the web application
# Note: Cleaning before build ensures no stale artifacts are included
RUN flutter clean && \
    flutter pub get && \
    flutter build web --release --no-tree-shake-icons \
    --dart-define=VERTEX_API_KEY=$VERTEX_API_KEY \
    --dart-define=GEMINI_API_KEY=$GEMINI_API_KEY \
    --dart-define=OPENAI_API_KEY=$OPENAI_API_KEY \
    --dart-define=ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY \
    --dart-define=VEO_API_KEY=$VEO_API_KEY \
    --dart-define=FIREBASE_API_KEY=$FIREBASE_API_KEY \
    --dart-define=FIREBASE_PROJECT_ID=$FIREBASE_PROJECT_ID \
    --dart-define=FIREBASE_MESSAGING_SENDER_ID=$FIREBASE_MESSAGING_SENDER_ID \
    --dart-define=FIREBASE_APP_ID=$FIREBASE_APP_ID \
    --dart-define=APP_ENCRYPTION_KEY=$APP_ENCRYPTION_KEY

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
