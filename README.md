# ResPOS - Buffet Restaurant POS System

A complete offline-first Point of Sale (POS) system designed specifically for buffet-style restaurants. Built with **Flutter**, ResPOS runs seamlessly on Android Tablets, macOS, and Windows, offering a premium user experience with modern design and powerful features.

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![SQLite](https://img.shields.io/badge/SQLite-07405E?style=for-the-badge&logo=sqlite&logoColor=white)
![Riverpod](https://img.shields.io/badge/Riverpod-2D2D2D?style=for-the-badge&logo=riverpod&logoColor=white)

## 🎯 Project Overview

ResPOS is optimized for high-volume buffet environments where speed and reliability are paramount. It handles the unique logic of "Entry Charges" (Headcount) combined with "À La Carte" (Extra orders) in a single seamless flow.

### ✨ Key Features

*   **Offline-First**: Powered by SQLite (`sqflite`). reliability guaranteed even without internet.
*   **Smart Table Management**:
    *   Visual grid with real-time status (🟢 Available, 🔴 Occupied, 🟡 Cleaning).
    *   One-tap table opening with headcount calculation.
*   **Buffet & À La Carte Logic**:
    *   AUTO-calculate buffet costs based on adult/child tiers.
    *   Seamlessly add extra charge items (alcohol, special dishes) to the same bill.
*   **🖨️ Thermal Printer Integration**:
    *   Bluetooth Thermal Printer support (`blue_thermal_printer`).
    *   Generates professional 58mm/80mm receipts via ESC/POS commands.
    *   Configurable via dedicated **Printer Settings**.
*   **🗣️ Voice Announcements**:
    *   Integrated Text-to-Speech (`flutter_tts`) for total amount announcements (e.g., "Total amount is 500 Baht").
    *   Enhances accessibility and confirms transactions audibly.
*   **🌍 Multi-Language Support**:
    *   Full support for **English** and **Thai** (ไทย).
    *   Instant language switching without restarting.
*   **🎨 Modern Theming**:
    *   **modern_dark**: Sleek glassmorphism effects and neon accents.
    *   **popular_light**: Clean Material 3 design with vibrant colors.
    *   Customizable via Settings.
*   **📊 Reports & Analytics**:
    *   Built-in charts (`fl_chart`) for sales visualization.
    *   Detailed transaction history.

## 📱 Application Screens

### 1. Dashboard & Table Selection
*   **Instant Overview**: See the entire restaurant's status at a glance.
*   **Quick Actions**: Tap a green table to open, tap a red table to order.

### 2. POS Ordering Interface
*   **Master-Detail Layout**: Optimized for tablets.
    *   *Left*: Interactive Menu with images and category filters.
    *   *Right*: Real-time Bill Summary with quantity controls.
*   **Smart Pricing**: Automatically distinguishes between "Included in Buffet" (0.00) and "Extra Charge" items.

### 3. Payment & Checkout
*   **Split Logic Presentation**: Clearly separates Buffet Heads vs. Extra Orders in the receipt view.
*   **Payment Methods**: Cash (with auto-change calculator) and QR Payment placeholders.
*   **Voice Confirmation**: Announces the total to pay automatically.

### 4. Settings Center
*   **Printer**: Scan/Connect Bluetooth printers, Test Print.
*   **General**: Toggle themes, Change language, Reset Database.

## 🔧 Tech Stack

*   **Framework**: Flutter (Dart)
*   **State Management**: Riverpod (Providers, StateNotifiers)
*   **Storage**: SQLite (Data), Local File System (Images), Shared Preferences (Settings)
*   **Printing**: `blue_thermal_printer`, `esc_pos_utils_plus`
*   **UI/UX**: `flutter_screenutil` (Responsive), `animate_do` (Animations), `google_fonts`
*   **TTS**: `flutter_tts`

## 🚀 Getting Started

### Prerequisites
*   Flutter SDK installed.
*   Android Studio / VS Code.
*   **For Windows**: Visual Studio 2022 (with "Desktop development with C++" workload).

### Installation

1.  **Clone the repository**:
    ```bash
    git clone <repository-url>
    cd ResPOS
    ```

2.  **Install Dependencies**:
    ```bash
    flutter pub get
    ```

3.  **Run the App**:
    *   **Android**: Connect device or emulator.
        ```bash
        flutter run
        ```
    *   **Windows**:
        ```bash
        flutter run -d windows
        ```

### ⚠️ Android Build Note
This project uses **AGP (Android Gradle Plugin) 8.2.1** and **Kotlin 1.9.22** to ensure maximum compatibility with the `blue_thermal_printer` plugin.
*   If you encounter a `VerifyException` during build, ensure you are NOT using AGP 8.3+.
*   The `build.gradle.kts` includes specific dependency resolution strategies to force compatibility.

## 📂 Project Structure

```
lib/
├── main.dart                  # Entry & App Config
├── models/                    # Database Entities (Table, Order, Item)
├── screens/                   # UI Pages (POS, Settings, Dashboard)
├── services/
│   ├── database_helper.dart   # SQLite Logic
│   └── printer/               # Bluetooth & Receipt Logic
├── providers/                 # Riverpod State Providers
└── utils/                     # Helpers (Currency formatting, Theme)
```

## 📄 License
Proprietary & Confidential.

---
**ResPOS** - *Professional Buffet Solutions.*
