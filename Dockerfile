# Stage 1: Build Flutter Web
FROM debian:bookworm-slim AS build-env

# Build Arguments (Passed from Cloud Build or local docker build)
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
ARG DIFY_API_KEY
ARG ELEVEN_LABS_API_KEY
ARG IMAGEN_API_KEY
ARG LYRIA_API_KEY
ARG XAI_API_KEY
ARG RUNWAY_API_KEY
ARG MIDJOURNEY_API_KEY
ARG PINECONE_API_KEY

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    wget \
    unzip \
    python3 \
    libglu1-mesa \
    && rm -rf /var/lib/apt/lists/*

# Install Flutter
RUN git clone https://github.com/flutter/flutter.git /usr/local/flutter
ENV PATH="/usr/local/flutter/bin:/usr/local/flutter/bin/cache/dart-sdk/bin:${PATH}"

# Prepare Flutter
RUN flutter config --enable-web
RUN flutter doctor

# Copy project files
WORKDIR /app
COPY . .

# Build Web with Dart Defines (Baking keys into the web build for the vault to pick up)
RUN flutter pub get
RUN flutter build web --release \
    --dart-define=VERTEX_API_KEY=$VERTEX_API_KEY \
    --dart-define=GEMINI_API_KEY=$GEMINI_API_KEY \
    --dart-define=OPENAI_API_KEY=$OPENAI_API_KEY \
    --dart-define=ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY \
    --dart-define=VEO_API_KEY=$VEO_API_KEY \
    --dart-define=FIREBASE_API_KEY=$FIREBASE_API_KEY \
    --dart-define=FIREBASE_PROJECT_ID=$FIREBASE_PROJECT_ID \
    --dart-define=FIREBASE_MESSAGING_SENDER_ID=$FIREBASE_MESSAGING_SENDER_ID \
    --dart-define=FIREBASE_APP_ID=$FIREBASE_APP_ID \
    --dart-define=APP_ENCRYPTION_KEY=$APP_ENCRYPTION_KEY \
    --dart-define=DIFY_API_KEY=$DIFY_API_KEY \
    --dart-define=ELEVEN_LABS_API_KEY=$ELEVEN_LABS_API_KEY \
    --dart-define=IMAGEN_API_KEY=$IMAGEN_API_KEY \
    --dart-define=LYRIA_API_KEY=$LYRIA_API_KEY \
    --dart-define=XAI_API_KEY=$XAI_API_KEY \
    --dart-define=RUNWAY_API_KEY=$RUNWAY_API_KEY \
    --dart-define=MIDJOURNEY_API_KEY=$MIDJOURNEY_API_KEY \
    --dart-define=PINECONE_API_KEY=$PINECONE_API_KEY

# Stage 2: Serve with Nginx
FROM nginx:alpine

# Copy build artifacts
COPY --from=build-env /app/build/web /usr/share/nginx/html

# EXPOSE port 8080 (Common for Cloud Run)
EXPOSE 8080

# Custom Nginx config to handle SPA routing if necessary
# For now, standard alpine nginx is fine, but you might want a default.conf
RUN sed -i 's/listen \(.*\)80;/listen 8080;/g' /etc/nginx/conf.d/default.conf

CMD ["nginx", "-g", "daemon off;"]
