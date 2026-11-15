package com.docusafe.app

import android.app.Activity
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.StatFs
import android.view.WindowManager
import androidx.activity.result.ActivityResultLauncher
import androidx.activity.result.contract.ActivityResultContracts
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.Executors

/**
 * Activité principale.
 *
 * - Hérite de FlutterFragmentActivity : obligatoire pour la fenêtre biométrique
 *   des paquets local_auth et flutter_secure_storage.
 * - Pose FLAG_SECURE avant le premier affichage : captures d'écran bloquées et
 *   aperçu masqué dans les applications récentes (docs/04-securite.md §15).
 *   Le côté Dart peut le retirer si l'utilisateur autorise les captures.
 * - Version « aperçu » (BuildConfig.APERCU) : jamais de FLAG_SECURE, sinon un
 *   émulateur en ligne n'affiche qu'un écran noir (docs/apercu-telephone.md).
 */
class MainActivity : FlutterFragmentActivity() {

    // « Enregistrer sous » : fichier à copier et réponse Dart en attente.
    private var pendingSourcePath: String? = null
    private var pendingResult: MethodChannel.Result? = null
    private lateinit var createDocument: ActivityResultLauncher<Intent>
    private val ioExecutor = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun onCreate(savedInstanceState: Bundle?) {
        // Doit être enregistré avant que l'activité ne démarre.
        createDocument = registerForActivityResult(
            ActivityResultContracts.StartActivityForResult(),
        ) { activityResult -> onDocumentCreated(activityResult.resultCode, activityResult.data) }
        // Sécurisé par défaut, avant que quoi que ce soit ne soit dessiné.
        if (!BuildConfig.APERCU) {
            window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
        }
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "docusafe/screen_security")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "setSecure" -> {
                        val secure = call.argument<Boolean>("secure") ?: true
                        if (secure && !BuildConfig.APERCU) {
                            window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        } else {
                            window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        }
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "docusafe/platform")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "androidSdkInt" -> result.success(Build.VERSION.SDK_INT)
                    "freeBytes" -> result.success(StatFs(filesDir.path).availableBytes)
                    "saveFile" -> saveFile(
                        call.argument<String>("path"),
                        call.argument<String>("name"),
                        call.argument<String>("mimeType"),
                        result,
                    )
                    else -> result.notImplemented()
                }
            }
    }

    /**
     * Ouvre le sélecteur « Enregistrer sous » du système, puis copie le
     * fichier par petits morceaux vers l'emplacement choisi (sans le charger
     * en mémoire). Réponse : true si enregistré, false si annulé.
     */
    private fun saveFile(path: String?, name: String?, mimeType: String?, result: MethodChannel.Result) {
        if (path == null || name == null || pendingResult != null) {
            result.error("bad_request", null, null)
            return
        }
        pendingSourcePath = path
        pendingResult = result
        val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = mimeType ?: "application/octet-stream"
            putExtra(Intent.EXTRA_TITLE, name)
        }
        createDocument.launch(intent)
    }

    private fun onDocumentCreated(resultCode: Int, data: Intent?) {
        val result = pendingResult ?: return
        val source = pendingSourcePath
        pendingResult = null
        pendingSourcePath = null
        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null || source == null) {
            result.success(false)
            return
        }
        ioExecutor.execute {
            try {
                contentResolver.openOutputStream(uri, "w").use { output ->
                    requireNotNull(output)
                    File(source).inputStream().use { input -> input.copyTo(output, 1 shl 20) }
                }
                mainHandler.post { result.success(true) }
            } catch (e: Exception) {
                mainHandler.post { result.error("write_failed", null, null) }
            }
        }
    }
}
