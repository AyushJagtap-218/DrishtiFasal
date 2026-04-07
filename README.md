# DrishtiFasal (Android)

DrishtiFasal is an offline-first Flutter application that diagnoses crop diseases using a hybrid TensorFlow Lite model plus contextual data stored in a CSV. The app currently targets Android only; run it on an Android device or emulator to get disease, crop, and recommendation insights without relying on a backend.

## What the app does

- **Performs on-device inference.** `lib/services/model_service.dart` loads `assets/models/hybrid_model_float32.tflite`, preprocesses the uploaded leaf image, validates it, normalizes tabular inputs (temperature, humidity, rainfall, week, stage), executes the interpreter, and returns a `label` + `confidence` pair that represents the detected disease.
- **Enforces leaf-only uploads.** `_isLeafImage` inspects the sampled pixels to confirm enough green content before prediction, so random non-leaf photos are rejected with a clear error.
- **Displays CSV-backed recommendations.** `result_screen.dart` reads `assets/data/crop_stage_disease_mapping.csv`, normalizes disease names, builds an index, and matches the predicted label and stage to surface the crop name, treatment, prevention, and symptoms text on the result screen.
- **Keeps UI consistent.** The result screen preserves the project’s existing theme: first showing the detected disease, crop name, confidence, and stage, then listing recommendations (or a “No action required” message when the model says healthy). Loading and CSV errors show dedicated cards so the UX stays informative.

## Android Setup & Run

1. **Install Flutter** (3.11+) and Android tooling, then accept any required Android component licenses.
2. **Fetch packages from the project root**:
   ```bash
   flutter pub get
   ```
3. **Ensure assets are wired up** – confirm `assets/models/hybrid_model_float32.tflite` and `assets/data/crop_stage_disease_mapping.csv` appear under `flutter/assets` in `pubspec.yaml`.
4. **Run on Android**:
   ```bash
   flutter run
   ```
   Pick your connected Android phone or emulator when Flutter prompts for a device. The app launches in debug mode and shows logs for CSV loading and disease matching.

## Key Files

- `assets/models/hybrid_model_float32.tflite` – the model that fuses image features with weather/season signals.
- `assets/data/crop_stage_disease_mapping.csv` – contains columns like `Crop`, `Disease`, `Crop_Stage`, plus `Symptoms`, `Prevention`, and `Treatment`. The loader normalizes disease labels (lowercase, stripped punctuation/underscores) so they align with the model’s output (e.g., `Cedar_apple_rust`, `Tomato_Yellow_Leaf_Curl_Virus`).
- `lib/services/model_service.dart` – handles preprocessing, leaf checks, model inference, softmax, and returns label/confidence plus stage info.
- `lib/screens/loading_screen.dart` → `ResultScreen` – runs the model, then `result_screen.dart` matches the predicted disease/stage to the CSV and renders crop name + recommendation cards.

## CSV Matching Details

- At startup the result screen logs the number of rows and disease keys it indexed (`✅ CSV Loaded: … rows, … disease keys`), giving you a quick sanity check that the data was parsed.
- The matching sequence first tries the normalized label (e.g., `cedar apple rust`) via `_findRowsForDisease`. If that fails, it falls back to comparing the raw label string so labels like `Cedar_apple_rust` still find their rows.
- Stage filtering (`Crop_Stage`) prefers a row whose stage matches the predicted stage but will still return a disease row even if the stage differs.

## Testing & Validation

- Run Flutter analyzer:
  ```bash
  flutter analyze
  ```
- During `flutter run`:
  - Upload an image of a known disease (e.g., Cedar apple rust) and confirm the “Detected Crop” card shows the crop from the CSV plus relevant treatment/prevention text.
  - Healthy results should hide suggestion cards and display the “No action required” text instead.
  - Console logs show whether the CSV had the appropriate disease key; missing matches log the available keys to help you tune the file.

## Distribution Notes

- This project is Android-only for now. You can generate signed APKs via:
  ```bash
  flutter build apk --release
  ```
- Keep the CSV and TFLite assets bundled in the release so disease recommendations stay available offline.
