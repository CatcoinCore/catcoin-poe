# Flutter / plugins (R8 release)
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.embedding.**

# Gson / JSON (if used by plugins)
-keepattributes Signature
-keepattributes *Annotation*

# --- Play Console "App optimization": repackage classes ---
# Collapse all retained classes into a single root package: smaller DEX and
# stronger obfuscation. R8 full mode honours -repackageclasses; pair it with
# -allowaccessmodification so R8 may widen access to repackage/inline more.
# Aggressive — a release build must be runtime-smoke-tested, since plugins
# that reflect by name can need extra -keep rules. Manifest-referenced classes
# (e.g. the flutterlocalnotifications receivers) are auto-kept by R8.
-repackageclasses ''
-allowaccessmodification
