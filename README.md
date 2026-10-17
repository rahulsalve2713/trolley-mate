# 🛒 TrolleyMate
> **Scan. Shop. Skip the queue.**

TrolleyMate is a Smart Shopping Trolley system that combines Hardware (ESP32) and Software (Flutter + Firebase) to eliminate supermarket billing queues.

## 🚀 Features
- **Barcode Scanning:** Scan products to instantly add them to your cart.
- **Real-time Sync:** Cart updates live across the Mobile App, Trolley LCD, and Billing Booth.
- **Theft-Proof:** Weight sensor integration (HX711) to verify cart items.
- **Admin Dashboard:** Manage products, categories, and view real-time analytics.
- **Smart Exit Gate:** Auto-unlocks via Firebase when payment is completed.

## 🛠 Tech Stack
- **Frontend:** Flutter (Mobile App + Web Billing Booth)
- **Backend:** Firebase (Auth, Firestore, Realtime Database)
- **Hardware:** ESP32, L298N Motor Driver, 16x2 I2C LCD
- **Communication:** UDP (Trolley Control), HTTP (Firebase Sync)

## ⚙️ Setup Instructions
Since this project uses Firebase, sensitive keys are not included in this repository.
To run this locally:
1. Create a Firebase project.
2. Add `google-services.json` to `android/app/`.
3. Generate `firebase_options.dart` using the FlutterFire CLI.
4. Run `flutter pub get` and `flutter run`.

## 📱 Screenshots
*(Add a screenshot of your app here later!)*
