package com.docusafe.app

import android.app.Activity
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.StatFs
import android.net.Uri
import android.provider.OpenableColumns
import android.view.WindowManager
import androidx.activity.result.ActivityResultLauncher
import androidx.activity.result.contract.ActivityResultContracts
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.UUID
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

    // « Partager vers DocSafe » : fichiers reçus, copiés dans cache/shared_in,
    // en attente d'être repris par Dart (canal docusafe/share_in).
    private var shareChannel: MethodChannel? = null
    private val pendingShares = mutableListOf<Map<String, String>>()

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
        if (savedInstanceState == null) {
            handleShareIntent(intent)
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleShareIntent(intent)
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

        shareChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "docusafe/share_in").also {
            it.setMethodCallHandler { call, result ->
                when (call.method) {
                    "takePending" -> {
                        val items = synchronized(pendingShares) {
                            val copy = pendingShares.toList()
                            pendingShares.clear()
                            copy
                        }
                        result.success(items)
                    }
                    else -> result.notImplemented()
                }
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

    /**
     * Fichiers partagés depuis une autre application. Seuls les contenus
     * « content:// » sont acceptés (jamais un chemin « file:// », qui pourrait
     * désigner un fichier privé de DocSafe). Chaque fichier est copié, au plus
     * MAX_SHARE_BYTES + 1 octets : un fichier trop gros arrive tronqué et sera
     * refusé par la vérification de l'importation, sans remplir le téléphone.
     */
    private fun handleShareIntent(intent: Intent?) {
        if (intent == null) return
        val uris: List<Uri> = when (intent.action) {
            Intent.ACTION_SEND -> listOfNotNull(intent.streamUri())
            Intent.ACTION_SEND_MULTIPLE -> intent.streamUris()
            else -> return
        }.filter { it.scheme == "content" }
        if (uris.isEmpty()) return
        ioExecutor.execute {
            val dir = File(cacheDir, "shared_in")
            dir.deleteRecursively()
            val received = mutableListOf<Map<String, String>>()
            for (uri in uris) {
                try {
                    val target = File(File(dir, UUID.randomUUID().toString()).apply { mkdirs() }, displayName(uri))
                    contentResolver.openInputStream(uri)?.use { input ->
                        target.outputStream().use { output -> copyAtMost(input, output, MAX_SHARE_BYTES + 1) }
                    } ?: continue
                    received.add(mapOf("path" to target.path, "name" to target.name))
                } catch (e: Exception) {
                    // Fichier illisible : ignoré.
                }
            }
            if (received.isEmpty()) return@execute
            synchronized(pendingShares) {
                pendingShares.clear()
                pendingShares.addAll(received)
            }
            mainHandler.post { shareChannel?.invokeMethod("sharedAvailable", null) }
        }
    }

    @Suppress("DEPRECATION")
    private fun Intent.streamUri(): Uri? =
        if (Build.VERSION.SDK_INT >= 33) getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java)
        else getParcelableExtra(Intent.EXTRA_STREAM) as? Uri

    @Suppress("DEPRECATION")
    private fun Intent.streamUris(): List<Uri> =
        (if (Build.VERSION.SDK_INT >= 33) getParcelableArrayListExtra(Intent.EXTRA_STREAM, Uri::class.java)
        else getParcelableArrayListExtra<Uri>(Intent.EXTRA_STREAM)) ?: emptyList()

    private fun displayName(uri: Uri): String {
        var name: String? = null
        contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)?.use { cursor ->
            if (cursor.moveToFirst()) name = cursor.getString(0)
        }
        // Jamais de séparateur de dossier dans un nom venu d'une autre application.
        val clean = (name ?: "document").replace(Regex("[/\\\\\u0000]"), "_").trim().take(120)
        return if (clean.isEmpty() || clean == "." || clean == "..") "document" else clean
    }

    private fun copyAtMost(input: java.io.InputStream, output: java.io.OutputStream, limit: Long) {
        val buffer = ByteArray(1 shl 16)
        var total = 0L
        while (total < limit) {
            val read = input.read(buffer, 0, minOf(buffer.size.toLong(), limit - total).toInt())
            if (read < 0) break
            output.write(buffer, 0, read)
            total += read
        }
    }

    companion object {
        /** Taille maximale d'un document (DocumentLimits.maxFileSizeBytes). */
        private const val MAX_SHARE_BYTES = 100L * 1000 * 1000
    }
}
