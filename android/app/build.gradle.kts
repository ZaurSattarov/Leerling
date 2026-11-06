import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // Firebase Cloud Messaging (push notificaties, Fase 5) -- moet na de
    // Android/Kotlin-plugins staan, leest android/app/google-services.json.
    id("com.google.gms.google-services")
}

// Maps SDK: MAPS_API_KEY uit het gitignorede local.properties of de omgeving.
val localMapsProperties = Properties().apply {
    val bestand = rootProject.file("local.properties")
    if (bestand.exists()) load(FileInputStream(bestand))
}
val mapsApiKey: String =
    (localMapsProperties.getProperty("MAPS_API_KEY") ?: System.getenv("MAPS_API_KEY")) ?: ""

val keyPropertiesFile = rootProject.file("key.properties")
val keyProperties = Properties()
if (keyPropertiesFile.exists()) {
    keyProperties.load(FileInputStream(keyPropertiesFile))
}

android {
    namespace = "com.klantio.leerling"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    signingConfigs {
        create("release") {
            keyAlias = keyProperties["keyAlias"] as String?
            keyPassword = keyProperties["keyPassword"] as String?
            storeFile = (keyProperties["storeFile"] as String?)?.let { keyPropertiesFile.parentFile.resolve(it) }
            storePassword = keyProperties["storePassword"] as String?
        }
    }

    defaultConfig {
        applicationId = "com.klantio.leerling"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["mapsApiKey"] = mapsApiKey
    }

    buildTypes {
        release {
            if (mapsApiKey.isBlank()) throw GradleException(
                "MAPS_API_KEY is verplicht voor release builds. " +
                "Voeg toe aan android/local.properties of stel de omgevingsvariabele in."
            )
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}
