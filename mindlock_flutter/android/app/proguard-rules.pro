# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Kotlin
-keep class kotlin.** { *; }
-keep class kotlinx.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# MindLock
-keep class com.mindlock.app.** { *; }

# Drift SQLite
-keep class com.tekartik.sqflite.** { *; }

# JSON
-keepattributes *Annotation*
-keepclassmembers class ** {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Prevent stripping of native methods
-keepclasseswithmembernames class * {
    native <methods>;
}
