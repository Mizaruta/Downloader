<div align="center">

<img src="extension/chrome/icons/icon128.png" alt="Logo" width="128" height="128" />

# Modern Downloader

**Téléchargeur de médias moderne, rapide et respectueux de la vie privée**  
*Modern, fast & privacy-focused media downloader*

[![Stars](https://img.shields.io/github/stars/Mizaruta/Downloader?style=for-the-badge&logo=github&color=blueviolet)](https://github.com/Mizaruta/Downloader/stargazers)
[![Release](https://img.shields.io/github/v/release/Mizaruta/Downloader?style=for-the-badge&color=orange)](https://github.com/Mizaruta/Downloader/releases)
[![License](https://img.shields.io/github/license/Mizaruta/Downloader?style=for-the-badge&color=green)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Windows-blue?style=for-the-badge&logo=windows)](https://www.microsoft.com/windows)

[![Flutter](https://img.shields.io/badge/Built%20with-Flutter-02569B?style=flat-square&logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Language-Dart-0175C2?style=flat-square&logo=dart)](https://dart.dev)

</div>

---

## 📖 Table of Contents / Table des matières

- [🇫🇷 Français](#-français)
  - [Présentation](#-présentation)
  - [Fonctionnalités](#-fonctionnalités)
  - [Installation](#-installation)
- [🇬🇧 English](#-english)
  - [Overview](#-overview)
  - [Features](#-features)
  - [Installation](#-installation-1)
- [🛠️ Tech Stack](#-tech-stack)
- [🤝 Contributing](#-contributing)

---

## 🇫🇷 Français

### ✨ Présentation

**Modern Downloader** est une application de bureau native conçue avec **Flutter** pour offrir une expérience de téléchargement **premium** sur Windows.

Il remplace les lignes de commande complexes par une interface graphique élégante et fluide, vous permettant de télécharger facilement :
- 🎥 **Vidéos** (YouTube, Twitch, etc.)
- 🎵 **Audio** (MP3, AAC)
- 🖼️ **Galeries d'images** (Pinterest, Twitter, etc.)

### ⚡ Fonctionnalités

| Catégorie | Détails |
|-----------|---------|
| **🌍 Universel** | Supporte **1000+ sites** via l'intégration de `yt-dlp` et `gallery-dl`. |
| **🚀 Performance** | Téléchargements ultra-rapides multi-threadés grâce au moteur **aria2c**. |
| **🛡️ Confidentialité** | Support natif de **Tor (SOCKS5)**, gestion isolée des cookies, zéro télémétrie. |
| **🎨 Design** | Interface "Glassmorphism" moderne, mode sombre natif, animations fluides (60fps). |
| **🔧 Outils** | Conversion automatique (FFmpeg), extraction de métadonnées, intégration des sous-titres. |

### 🚀 Installation

**Prérequis :**
- Windows 10 ou 11
- [Flutter SDK](https://docs.flutter.dev/get-started/install/windows) installé
- [Git](https://git-scm.com/) installé

```bash
# 1. Cloner le projet
git clone https://github.com/Mizaruta/Downloader.git
cd Downloader

# 2. Installer les dépendances
flutter pub get

# 3. Lancer l'application
flutter run -d windows
```

> **Note :** Pour générer un exécutable release : `flutter build windows`

---

## 🇬🇧 English

### ✨ Overview

**Modern Downloader** is a native desktop application built with **Flutter** to provide a **premium** downloading experience on Windows.

It replaces complex command-line tools with a sleek and smooth GUI, allowing you to easily download:
- 🎥 **Videos** (YouTube, Twitch, etc.)
- 🎵 **Audio** (MP3, AAC)
- 🖼️ **Image Galleries** (Pinterest, Twitter, etc.)

### ⚡ Features

| Category | Details |
|----------|---------|
| **🌍 Universal** | Supports **1000+ websites** via integrated `yt-dlp` and `gallery-dl`. |
| **🚀 Performance** | Ultra-fast multi-threaded downloads powered by the **aria2c** engine. |
| **🛡️ Privacy** | Native **Tor (SOCKS5)** support, isolated cookie management, zero telemetry. |
| **🎨 Design** | Modern "Glassmorphism" UI, native dark mode, smooth 60fps animations. |
| **🔧 Tools** | Automatic conversion (FFmpeg), metadata extraction, subtitle integration. |

### 🚀 Installation

**Requirements:**
- Windows 10 or 11
- [Flutter SDK](https://docs.flutter.dev/get-started/install/windows) installed
- [Git](https://git-scm.com/) installed

```bash
# 1. Clone the repository
git clone https://github.com/Mizaruta/Downloader.git
cd Downloader

# 2. Install dependencies
flutter pub get

# 3. Run the app
flutter run -d windows
```

> **Note:** To build a release executable: `flutter build windows`

---

## 🛠️ Tech Stack

Everything that makes this project tick:

- **Frontend:** [Flutter](https://flutter.dev) (Dart)
- **State Management:** [Riverpod](https://riverpod.dev)
- **Navigation:** [GoRouter](https://pub.dev/packages/go_router)
- **Core Engines:**
  - `yt-dlp` (Video/Audio extraction)
  - `gallery-dl` (Image extraction)
  - `aria2c` (Download acceleration)
  - `FFmpeg` (Media conversion)

## 🤝 Contributing

Contributions are perfectly welcome! ❤️

1.  **Fork** the repository
2.  Create your **Feature Branch** (`git checkout -b feature/AmazingFeature`)
3.  **Commit** your changes (`git commit -m 'Add some AmazingFeature'`)
4.  **Push** to the branch (`git push origin feature/AmazingFeature`)
5.  Open a **Pull Request**

---

<div align="center">

**Mizaruta / Downloader** © 2023-2026

[![License](https://img.shields.io/github/license/Mizaruta/Downloader?style=flat-square)](LICENSE)

</div>