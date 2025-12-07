# Keep all ONNX Runtime classes (prevents R8 from stripping them)
-keep class ai.onnxruntime.** { *; }

# Optional: Keep Flutter plugin classes
-keep class io.flutter.plugins.** { *; }

# Optional: Keep model assets intact
-keepclassmembers class * {
    @androidx.annotation.Keep *;
}

