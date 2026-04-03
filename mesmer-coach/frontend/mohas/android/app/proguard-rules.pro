# Flutter engine
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class **.GeneratedPluginRegistrant { *; }

# Google Play Core — referenced by Flutter but not used in direct APK builds
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# Secure storage
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# Image picker
-keep class io.flutter.plugins.imagepicker.** { *; }

# Sqflite
-keep class com.tekartik.sqflite.** { *; }
