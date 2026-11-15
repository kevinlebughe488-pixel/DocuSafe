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

// Clé d'envoi Google Play (« upload key », docs/publication/signature.md) :
// lue dans android/key.properties (poste sain, fichier jamais versionné) ou
// dans les variables d'environnement remplies par les secrets GitHub. Jamais
// créée ni utilisée sur un PC infecté. Google Play signe ensuite l'application
// avec sa propre clé (« Play App Signing »).
val uploadKey: Map<String, String>? = run {
    val file = rootProject.file("key.properties")
    if (file.exists()) {
        val props = java.util.Properties().apply { file.inputStream().use { load(it) } }
        mapOf(
            "storeFile" to props.getProperty("storeFile"),
            "storePassword" to props.getProperty("storePassword"),
            "keyAlias" to props.getProperty("keyAlias"),
            "keyPassword" to props.getProperty("keyPassword"),
        )
    } else {
        val path = System.getenv("DOCUSAFE_UPLOAD_KEYSTORE")
        if (path.isNullOrEmpty()) {
            null
        } else {
            mapOf(
                "storeFile" to path,
                "storePassword" to (System.getenv("DOCUSAFE_UPLOAD_STORE_PASSWORD") ?: ""),
                "keyAlias" to (System.getenv("DOCUSAFE_UPLOAD_KEY_ALIAS") ?: ""),
                "keyPassword" to (System.getenv("DOCUSAFE_UPLOAD_KEY_PASSWORD") ?: ""),
            )
        }
    }
}

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
        if (uploadKey != null) {
            create("upload") {
                storeFile = file(uploadKey.getValue("storeFile"))
                storePassword = uploadKey.getValue("storePassword")
                keyAlias = uploadKey.getValue("keyAlias")
                keyPassword = uploadKey.getValue("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            // Publication : clé d'envoi si elle est fournie ; sinon clé de
            // débogage (fichier utilisable pour les vérifications, refusé par
            // Google Play).
            signingConfig = if (uploadKey != null) {
                signingConfigs.getByName("upload")
            } else {
                signingConfigs.getByName("debug")
            }
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
