# Keep audio_service / just_audio_background / media3 untuk notifikasi release — jangan obfuscate updateNotification
-keep class com.ryanheise.audioservice.** { *; }
-keep class com.ryanheise.just_audio.** { *; }
-keep class com.ryanheise.just_audio_background.** { *; }
-keep class androidx.media3.** { *; }
-keep class androidx.media.** { *; }
-keep class android.support.v4.media.** { *; }
-keep class com.ryanheise.audioservice.AudioService { *; }
-keep class com.ryanheise.audioservice.AudioServicePlugin* { *; }
-keepattributes *Annotation*,Signature,EnclosingMethod,InnerClasses,Exceptions,SourceFile,LineNumberTable
-dontwarn com.ryanheise.**
-dontwarn androidx.media3.**
# Keep Flutter
# Keep notification icon tidak di-strip (keep.xml sudah jaga drawable)
-keepclassmembers class **.R$drawable { public static <fields>; }
# Fix crash updateNotification r8-map-id di Infinix — jangan optimize away
-keepclassmembers class * { @android.webkit.JavascriptInterface <methods>; }
