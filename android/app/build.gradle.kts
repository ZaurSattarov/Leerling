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

val keyPropertiesFile = rootProject.file("key.properties")
val keyProperties = Properties()
if (keyPropertiesFile.exists()) {
    keyProperties.load(FileInputStream(keyPropertiesFile))
}

// Live Aankomst (Feature 2, Fase 3): Google Maps API-key voor Android.
// NOOIT hardcoded en NOOIT gecommit. Lokaal: voeg toe aan het al-gitignorede
// android/local.properties:
//   MAPS_API_KEY=<jouw Android Leerling-key uit Google Cloud>
// CI: zet de omgevingsvariabele MAPS_API_KEY. Een build zonder een van
// beide faalt hieronder expliciet -- een lege key mag nooit stilzwijgend
// als geldige productieconfig doorgaan.
val localPropertiesFile = rootProject.file("local.properties")
val localProperties = Properties()
if (localPropertiesFile.exists()) {
    localProperties.load(FileInputStream(localPropertiesFile))
}
val mapsApiKey: String =
    (localProperties.getProperty("MAPS_API_KEY") ?: System.getenv("MAPS_API_KEY"))
        ?.takeIf { it.isNotBlank() }
        ?: throw GradleException(
            "Google Maps API-key ontbreekt. Voeg 'MAPS_API_KEY=<jouw-key>' toe aan " +
                "android/local.properties (lokaal, al gitignored), of zet de " +
                "omgevingsvariabele MAPS_API_KEY (CI). Zie AGENTS.md/CLAUDE.md " +
                "voor welke key dit moet zijn (Android Leerling, com.klantio.leerling)."
        )

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
            keyAlias = keyProperties["keyAlias"] as String
            keyPassword = keyProperties["keyPassword"] as String
            storeFile = keyPropertiesFile.parentFile.resolve(keyProperties["storeFile"] as String)
            storePassword = keyProperties["storePassword"] as String
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
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}
