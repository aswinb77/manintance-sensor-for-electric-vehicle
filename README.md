# Maintenance Sensor for Electric Vehicles

This repository contains both hardware and software components for an electric vehicle maintenance sensor project.

## Project Structure

- `Hardware/` — Arduino/TinyML hardware code and model files.
- `Software/elctric_ev_ml/` — Flutter application code for managing the EV maintenance sensor.

## Getting Started

### Hardware
1. Open the Arduino sketch in `Hardware/TinyML-prediction/TinyML-prediction.ino`.
2. Use the provided TinyML model `Hardware/TinyML-prediction/motor_tinyml_model.tflite`.
3. Compile and upload to a compatible Arduino or microcontroller board.

### Software
1. Open the Flutter app in `Software/elctric_ev_ml/`.
2. Run `flutter pub get` to install dependencies.
3. Launch the app with `flutter run`.

## Notes

- The Flutter app includes platform targets for Android, iOS, macOS, Windows, Linux, and Web.
- The hardware folder contains the TinyML model header file and Arduino sketch.
