#!/bin/bash
set -e

echo "🧠 Inhaus Brain: Initializing Setup..."

# 1. Check for Flutter
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter not found. Please install Flutter SDK."
    exit 1
else
    echo "✅ Flutter found: $(flutter --version | head -n 1)"
fi

# 2. Install Flutter Dependencies
echo "📦 Installing Flutter dependencies..."
flutter pub get

# 3. Check for Firebase Functions dependencies
if [ -d "functions" ]; then
    echo "⚡ Found Cloud Functions. Installing Node dependencies..."
    cd functions
    if command -v npm &> /dev/null; then
        npm install
        echo "✅ Node dependencies installed."
    else
        echo "⚠️ npm not found. Skipping Cloud Functions setup."
    fi
    cd ..
fi

# 4. Check for .env file
if [ ! -f ".env" ]; then
    echo "📄 .env file missing. Creating from .env.example..."
    if [ -f ".env.example" ]; then
        cp .env.example .env
        echo "✅ .env created. PLEASE UPDATE YOUR API KEYS."
    else
        echo "⚠️ .env.example not found. Please create .env manually."
    fi
fi

# 5. Check for Firebase Tools
if ! npx firebase --version &> /dev/null; then
    echo "ℹ️ Firebase Tools not found globally, but will be used via npx when needed."
fi

echo "🚀 Setup Complete! You are ready to build."
echo "💡 To start: flutter run -d chrome"
