---
description: Clean, Build, and Deploy to Production (Firebase & GitHub)
---

# Production Deployment Workflow

This workflow handles the full clean, build, and deployment process for the Inhaus Brain application.

## 1. Clean and Prepare
1.  Clean the Flutter project to remove old artifacts.
    ```bash
    flutter clean
    ```
2.  Get the latest dependencies.
    ```bash
    flutter pub get
    ```

## 2. Build for Production
3.  Build the web application in release mode (CanvasKit renderer is recommended for performance, but auto is fine. Using standard build).
    ```bash
    flutter build web --release --web-renderer canvaskit
    ```

## 3. Deploy to Firebase (gclout)
4.  Deploy all Firebase services (Hosting, Functions, Firestore, Storage) to production.
    ```bash
    npx firebase deploy
    ```

## 4. Push to GitHub
5.  Add all changes to git.
    ```bash
    git add .
    ```
6.  Commit changes with a release message.
    ```bash
    git commit -m "chore: Production release - Fix Veo Polling, LiteRT Routing & UI Enhancements"
    ```
7.  Push the current branch to origin.
    ```bash
    git push origin feature/reports-oauth-litert-enhancements
    ```
