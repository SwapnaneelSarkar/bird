# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-keepnames class com.google.android.gms.** { *; }
-keep class com.google.android.recaptcha.** { *; }
-keep class io.grpc.** { *; }

# SSL/TLS
-keep class javax.net.ssl.** { *; }
-keep class org.apache.http.** { *; }
-keep class com.android.org.conscrypt.** { *; }
-keep class org.conscrypt.** { *; }