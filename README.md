## 🐺 Guess the Lupus: Lupus in Pocket - Digital Party Game

![Flutter](https://img.shields.io/badge/Flutter-3.x-blue?style=for-the-badge&logo=flutter)
![Firebase](https://img.shields.io/badge/Firebase-Auth%20%7C%20Storage%20%7C%20DB-orange?style=for-the-badge&logo=firebase)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web-green?style=for-the-badge&logo=googlechrome)

<p align="center">
  <img src="./assets/images/readme_preview.gif" width="500" alt="Guess Me Demo">
</p>

## 📝 Description
**Lupus in Pocket** è un'applicazione multiplayer cross-platform ispirata al celebre gioco di società *Lupus in Pocket*. Sviluppata con **Flutter** e supportata da un'infrastruttura **Firebase**, l'app digitalizza l'esperienza del party game classico, eliminando la necessità di un mazzo di carte fisico e automatizzando le fasi di gioco.

Il progetto si concentra sulla creazione di un'atmosfera immersiva e dinamica, permettendo ai giocatori di gestire ruoli segreti, votazioni e fasi narrative direttamente dai propri dispositivi in tempo reale.

## 👁️ The Vision
L'obiettivo di Lupus in Pocket è colmare il divario tra l'interazione sociale faccia a faccia e il gaming digitale. Invece di isolare i giocatori, l'app funge da "narratore digitale" e supporto logistico, facilitando le dinamiche di gruppo e rendendo il gioco accessibile anche a chi non conosce le regole complesse del modulo originale.

Il design è studiato per mantenere alta la tensione tipica del gioco, utilizzando temi dinamici e feedback visivi che si adattano al ritmo della narrazione.

## 🎨 Immersive Design & UI
Il gioco vanta un sistema di **Dynamic Theming** basato sullo stato della partita:
* **☀️ Giorno (The Village)**: Un'interfaccia chiara, ispirata alla pergamena antica e al legno di cedro, per le fasi di discussione pubblica.
* **🌙 Notte (The Tavern)**: Un'atmosfera oscura, dominata da blu profondi e luci soffuse (glow), dedicata alle azioni segrete dei Lupi e dei ruoli speciali.

## 🚀 Key Features
- **Real-time Multiplayer**: Sincronizzazione istantanea delle fasi di gioco e delle votazioni tramite Firebase Realtime Database/Firestore.
- **Dynamic Role Assignment**: Distribuzione automatica e segreta dei ruoli (Lupi, Veggente, Medico, Contadini, ecc.).
- **Profile Customization**: Sistema di caricamento foto profilo e avatar personalizzati tramite **Firebase Storage**, con ottimizzazione e compressione automatica delle immagini.
- **Cross-Platform Play**: Esperienza fluida e coerente su Android, iOS e Web grazie ad un'unica codebase Flutter.

## 🛠️ Tech Stack
- **Framework**: Flutter 3.x
- **Language**: Dart
- **Backend**: Firebase (Authentication, Cloud Firestore, Cloud Storage)
- **Image Processing**: Compressione e ridimensionamento lato client per performance ottimali.
- **State Management**: Gestione reattiva dello stato per riflettere i cambiamenti della partita in tempo reale.

## ⚙️ Setup for Developers
1. Clone the repo: `git clone https://github.com/Gigiux6/LupusInFabula`
2. Install dependencies: `flutter pub get`
3. Configure your `google-services.json` in the android/app folder.
4. Run `gcloud storage buckets update` for CORS settings to enable web uploads.

## 📱 Try the App
Puoi testare **Guess Me** direttamente sul tuo browser o installando l'APK sul tuo dispositivo Android.

* **🌐 Web Version**: [Link alla tua Web App](https://tuo-progetto.web.app)
* **🤖 Android App**: [Scarica l'ultimo APK](../../releases/latest)

> **Nota per Android**: Per installare l'APK, assicurati di aver abilitato l'installazione da "Origini Sconosciute" nelle impostazioni del tuo dispositivo.
