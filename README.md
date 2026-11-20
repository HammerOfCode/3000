# Gym Ready

Gym Ready is an offline Flutter workout planner. Sign in with **user** for both the ID and password, enter your height and weight, and open **Equipment** to record what your gym has. Choose a body area, experience level, and time limit under **Workout**, then tap **Build routine**. The swap button shows available replacements for the same exercise slot.

The app can build bodyweight routines before you enter any equipment. Use **Add equipment** to save machines by name. Choose an exercise match to include that machine in recommendations, or keep it as an inventory entry. Your profile and equipment are saved on the device. The muscle mass field accepts an optional reading from a body composition assessment.

## Run on Android

1. Install Flutter and Android Studio. In Android Studio, install the Flutter plugin and set its Flutter SDK path if prompted. This project was developed with Flutter 3.44.8.
2. Run `flutter doctor -v`. If the Android toolchain flags missing command-line tools or licenses, open **Tools > SDK Manager > SDK Tools**, install **Android SDK Command-line Tools (latest)**, and run `flutter doctor --android-licenses`.
3. Open this project folder in Android Studio. In **Tools > Device Manager**, start **Medium Phone**. If you need to create it, choose a Medium Phone hardware profile and install a compatible Android system image.
4. Open `lib/main.dart`, choose the emulator in the device selector, and click **Run**. You can also run these commands from the project folder.

```powershell
flutter pub get
flutter devices
flutter run -d emulator-5554
```

If `flutter devices` shows a different ID, use that ID in the last command. For an installable Android debug APK, run `flutter build apk --debug`. Flutter writes it under `build/app/outputs/flutter-apk/app-debug.apk`.

If the emulator stalls during startup, try **Cold Boot Now** in Device Manager. You can also create a Medium Phone with a stable Android system image or use a physical Android phone with USB debugging enabled. For either device, use its ID from `flutter devices`.

## Run on iOS

On a Mac, install Flutter and Xcode and complete [Flutter's iOS setup](https://docs.flutter.dev/platform-integration/ios/setup). Then open the project folder in a terminal and run the following.

```bash
flutter pub get
open -a Simulator
flutter devices
flutter run -d <iOS-device-id>
```

Replace `<iOS-device-id>` with the simulator ID from `flutter devices`. For a physical iPhone, configure **Runner** signing in Xcode first.

## Run the checks

```text
flutter analyze
flutter test
```

The tests cover mock sign-in, measurement validation and persistence, saved equipment, bodyweight fallback, equipment filtering, workout length, and exercise swaps.
