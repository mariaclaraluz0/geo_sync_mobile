plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val signingProperties = java.util.Properties()
val signingPropertiesFile = rootProject.file("key.properties")
if (signingPropertiesFile.exists()) {
    signingPropertiesFile.inputStream().use(signingProperties::load)
}

android {
    namespace = "com.example.mobile"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // Defina o identificador oficial via -PgeoSyncApplicationId=... antes
        // da publicação. O padrão mantém builds locais compatíveis.
        applicationId = providers.gradleProperty("geoSyncApplicationId")
            .orElse("com.example.mobile").get()
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            if (signingPropertiesFile.exists()) {
                signingConfig = signingConfigs.create("release") {
                    keyAlias = signingProperties["keyAlias"] as String
                    keyPassword = signingProperties["keyPassword"] as String
                    storeFile = file(signingProperties["storeFile"] as String)
                    storePassword = signingProperties["storePassword"] as String
                }
            }
        }
    }
}

flutter {
    source = "../.."
}
