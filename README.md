# tapresearch_flutter_plugin

In-app Monetization SDK via Surveys by TapResearch

## What This Is

A Flutter plugin that wraps the native TapResearch SDK (in-app survey monetization) for iOS and Android. 
The plugin uses Flutter's standard method channel pattern to bridge Dart code with native Swift (iOS) and Kotlin (Android) implementations.

## Supported Platforms
- iOS
- Android

## Getting Started
Run the example app bundled within this plugin to see how easy it is to show surveys.

- First, you need to start your emulator or connected device, then: 
  - cd example
  - flutter run

- Second, if you need to change the API TOKEN and/or User Identifier, please modify 
example/lib/main.dart and re-run.  The ones provided in the example should work fine.  

Note: the API TOKEN and User Identifier will be different for iOS and Android.

## Screenshots

![Home Screen](./screenshots/home_screen.png)
Demonstrates most commonly used features

![Survey Wall](./screenshots/survey_wall.png)
Standard Survey Wall provided by TapResearch SDK

![Survey Wall Preview](./screenshots/survey_wall_preview.png)
Survey Wall Preview.  Demonstrates you can further customize the look and feel.