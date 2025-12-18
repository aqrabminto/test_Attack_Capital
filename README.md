# 📱 MediNote Recorder

A Flutter-based audio recording app with background recording, chunked uploads, and cloud storage support.
The Assignment: Medical Transcription App 
Build a Flutter app that doctors can trust with their patient consultations. 
The app records audio during medical visits and streams it to a backend for AI transcription. 
Sounds simple? Here's the catch—it must work flawlessly when: 
● Doctors get phone calls mid-recording 
● They switch to other apps to check drug databases 
● The hospital WiFi drops out 
● Their phone dies at 60% battery (happens more than you'd think) 
Core Requirements 
1. Real-Time Audio Streaming 
● Stream audio chunks to backend during recording (not after) 
● Continue recording with phone locked or app minimized 
● Handle chunk ordering, retries, and network failures 
● Must demonstrate native microphone access with proper gain control 
2. Bulletproof Interruption Handling Must survive without losing data: 
● Phone calls (auto pause/resume) 
● App switching (EMR, calculator, camera) 
● Network outages (queue locally, retry when back) 
● Phone restarts (recover unsent chunks) 
● Memory pressure (when system kills other apps) 
3. Theme & Language (State Management Test) Must survive with no restart required: 
● Manual + system dark/light mode (persisted) 
● English/Hindi full UI language switching (persisted, no restart required) 
Technical Stack 
● Flutter (no Expo/React Native - we need native performance) 
● Platform channels for native features when needed 
● Android foreground service + iOS background audio 
API Reference & Resources 
�
�
Full API Documentation: 
https://docs.google.com/document/d/1hzfry0fg7qQQb39cswEychYMtBiBKDAqIg6LamAKENI/ed
it?usp=sharing 
�
�
Postman Collection (mock backend): 
https://drive.google.com/file/d/1rnEjRzH64ESlIi5VQekG525Dsf8IQZTP/view?usp=sharing 
---

## 🏷 Badges

![Flutter](https://img.shields.io/badge/flutter-3.13.7-blue?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/dart-3.2.1-blue?logo=dart&logoColor=white)
![Platform](https://img.shields.io/badge/platform-Android%20%7C%20iOS-lightgrey)

---

## 📲 Android APK

Download the latest APK from [GitHub Releases](https://github.com/aqrabminto/test_Attack_Capital/releases/download/v1.0.0-test-relese/app-release.apk).

---

## 📹 Video Demo

Watch a Loom video demonstrating all features: [ Demo Video](https://drive.google.com/drive/folders/1YkNpAgNu4TdZoXQqmXyLokGtxK5ePy6L?usp=drive_link).

---

## 🌐 Backend Deployment

Your backend APIs are deployed at:  
[backend-url](http://80.225.222.33:8080)

And backend file at
[backend-file](http://80.225.222.33:8080](https://github.com/aqrabminto/test_Attack_Capital/tree/main/test))

---

## 📄 API Documentation

View the API documentation here: [API Documentation](https://drive.google.com/file/d/1rnEjRzH64ESlIi5VQekG525Dsf8IQZTP/view)

---

## 📬 Postman Collection

Import and test APIs using this Postman collection: [Postman Collection](https://drive.google.com/file/d/1rnEjRzH64ESlIi5VQekG525Dsf8IQZTP/view?usp=sharing)

---

## ⚡ Features

- Background audio recording
- Real-time audio level visualization
- Chunked audio uploads to cloud storage
- Multi-language support (English, Hindi, Spanish)
- Theme switching (Light, Dark, System)

---

## 🛠 Flutter Version

Run the following command in your project:

```bash
flutter --version
flutter pub get
```
