plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Version « aperçu » compilée par GitHub à chaque envoi (DOCUSAFE_APERCU=1) :
// identifiant distinct (com.docusafe.app.apercu) et clé de test versionnée,
// pour l'installer à côté de la vraie application et la mettre à jour sans
// la désinstaller. Jamais utilisée pour la publication
// (docs/apercu-telephone.md).
val apercu = System.getenv("DOCUSAFE_APERCU") == "1"

android {
    namespace = "com.docusafe.app"
    // Versions imposées par docs/01-analyse.md (D1) et docs/06-dependances.md.
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // « Desugaring » : exigé par flutter_local_notifications (phase 4).
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        // Identifiant définitif après publication (D2).
        applicationId = "com.docusafe.app"
        minSdk = 24
        targetSdk = 36
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["appLabel"] = "DocuSafe"
        // Version aperçu : écran non protégé, pour qu'un émulateur en ligne
        // (Appetize) puisse l'afficher. Jamais dans la version publiée.
        buildConfigField("boolean", "APERCU", apercu.toString())
    }

    buildFeatures {
        buildConfig = true
    }

    signingConfigs {
        create("apercu") {
            storeFile = file("apercu.keystore")
            storePassword = "docusafe-apercu"
            keyAlias = "apercu"
            keyPassword = "docusafe-apercu"
        }
    }

    buildTypes {
        release {
            // Signature de publication : configurée en phase 6, jamais sur un
            // PC infecté (docs/problemes-connus.md). Clés de debug en attendant.
            signingConfig = signingConfigs.getByName("debug")
            if (apercu) {
                applicationIdSuffix = ".apercu"
                manifestPlaceholders["appLabel"] = "DocuSafe aperçu"
                signingConfig = signingConfigs.getByName("apercu")
            }
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
