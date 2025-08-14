// build.gradle.kts
import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin debe ir después de los plugins de Android y Kotlin.
    id("dev.flutter.flutter-gradle-plugin")
}

// Cargamos las propiedades locales (si existen)
val localProperties = Properties().apply {
    val localPropertiesFile = rootProject.file("local.properties")
    if (localPropertiesFile.exists()) {
        localPropertiesFile.inputStream().bufferedReader(Charsets.UTF_8).use { load(it) }
    }
}

// Asignamos versión por defecto si no existen en local.properties
val flutterVersionCode = localProperties.getProperty("flutter.versionCode") ?: "1"
val flutterVersionName = localProperties.getProperty("flutter.versionName") ?: "1.0"

android {
    namespace = "com.caldensmart.fabrica"
    compileSdk = 35
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.caldensmart.fabrica"
        minSdk = 24
        targetSdk = 34
        versionCode = flutterVersionCode.toInt()
        versionName = flutterVersionName
    }

    buildTypes {
        getByName("release") {
            // TODO: Aquí deberías colocar tu signingConfig propio para el release
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    // Ruta de tu carpeta Flutter
    source = "../.."
}
