# 📱 Kasyaba Mobile (Flutter)

The Android mobile client for Kasyaba, designed with an Ultra-Luxury Dark Fintech aesthetic (Obsidian glass surfaces with Champagne Gold and Emerald metallic accents).

---

## 🚀 Quick Setup

For complete, end-to-end instructions on running the backend, database, and Flutter mobile app together, see the **[Main Project README](../README.md)**.

### Running Just the Mobile App

1. Ensure your Flutter environment is ready:
   ```bash
   flutter doctor
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Start your Android Emulator or connect an Android device via USB.

4. Run in debug mode:
   ```bash
   # Connects automatically to local backend on Android emulator (http://10.0.2.2:3000)
   flutter run
   ```

   *If testing on a physical phone over local Wi-Fi, provide your computer's IP:*
   ```bash
   flutter run --dart-define=API_BASE_URL=http://YOUR_LOCAL_IP:3000
   ```

---

## 🧪 Testing & Analysis

```bash
# Run all unit and widget tests
flutter test

# Run static analysis
dart analyze
```

---

## 🏗️ Architecture

* **Framework:** Flutter with Material 3 and custom luxury theme.
* **State Management:** Riverpod (`flutter_riverpod`).
* **Networking & Offline:** Dio HTTP client with retry policies, token refresh intercepts, and local mutation queues.
* **Charts:** `fl_chart` with custom high-contrast luxury glow curves.
