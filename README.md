# 🎭 Lupus in Pocket - Multiplayer Party Game

![Flutter](https://img.shields.io/badge/Flutter-3.x-blue?style=for-the-badge&logo=flutter)
![Firebase](https://img.shields.io/badge/Firebase-Auth%20%7C%20Storage%20%7C%20DB-orange?style=for-the-badge&logo=firebase)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web-green?style=for-the-badge&logo=googlechrome)

<p align="center">
  <img src="./assets/images/readme_preview.gif" width="500" alt="Lupus Demo" />
</p>

## 🚀 Live Demo & Downloads

* **🌐 Web Version**: Play directly in your browser at [lupus-pocket-web.app](https://lupus-in-pocket.web.app)
* **📱 Android APK**: Download the latest stable APK from the [Releases page](https://github.com/Gigiux6/LupusInFabula/releases).

Lupus in Pocket is a vibrant, immersive multiplayer party game inspired by the classic "Lupus in Pocket" tabletop game. Players assume secret roles, vote, and navigate narrative phases in real time.

## 🚀 Main Features

* **Real-time Multiplayer**: Instant room creation and joining with unique codes.
* **Dynamic Game Modes**:
  * **Timed Mode** – Race against the clock.
  * **Classic Mode** – Traditional turn‑based play.
  * **Custom Mode** – Create your own secret identities.
* **Smart Sync** – Seamless state synchronization using Firebase.
* **Multilingual Support** – Italian, English, Spanish, German, French.
* **Rich Aesthetics** – Dark mode, glassmorphism UI, smooth micro‑animations.
* **In‑game Notes** – Track clues and answers.

## 🛠️ Technology Stack

* **Frontend**: Flutter (Dart)
* **Backend**: Firebase (Auth, Realtime Database, Firestore, Storage)
* **State Management**: Provider
* **Audio**: Audioplayers for immersive sound effects
* **Graphics**: Modern design system with responsive layouts

## 📱 Getting Started

### Prerequisites
* Flutter SDK (latest)
* Firebase project with Realtime Database/Firestore enabled

### Installation
1. **Clone the repository**:
   ```bash
   git clone https://github.com/Gigiux6/LupusInFabula.git
   ```
2. **Install dependencies**:
   ```bash
   flutter pub get
   ```
3. **Configure Firebase**:
   - Add `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) to the appropriate folders.
   - For Web, initialize Firebase in `index.html` or via `firebase_options.dart`.
4. **Run the app**:
   ```bash
   flutter run
   ```

## 🌍 Localization
The app automatically detects system language or allows manual selection in settings.
* 🇮🇹 Italian
* 🇺🇸 English
* 🇪🇸 Spanish
* 🇩🇪 German
* 🇫🇷 French

## 🤝 Contributing
Contributions are welcome! Open issues or submit pull requests to improve the game.

## 📜 License
This project is licensed under the MIT License – see the `LICENSE` file for details.

---
*Created with ❤️ by Gigiux6*
