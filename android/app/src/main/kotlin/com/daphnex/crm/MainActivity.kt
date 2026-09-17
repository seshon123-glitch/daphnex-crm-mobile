package com.daphnex.crm

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.ClipData
import android.content.Intent
import android.net.Uri
import android.provider.OpenableColumns
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    private val channelName = "com.daphnex.crm/document_picker"
    private val pickDocumentRequestCode = 9421
    private var pendingPickerResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channelName
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "pickDocument" -> pickDocument(result)
                "sharePdf" -> sharePdf(
                    call.argument<String>("filePath"),
                    call.argument<String>("fileName"),
                    call.argument<String>("mimeType"),
                    call.argument<String>("text"),
                    call.argument<String>("subject"),
                    call.argument<String>("targetPackage"),
                    result
                )
                else -> result.notImplemented()
            }
        }
    }

    private fun sharePdf(
        filePath: String?,
        fileName: String?,
        mimeType: String?,
        text: String?,
        subject: String?,
        targetPackage: String?,
        result: MethodChannel.Result
    ) {
        try {
            if (filePath.isNullOrBlank()) {
                result.error("share_pdf_missing_file", "Quote PDF is not available to share.", null)
                return
            }
            val file = File(filePath)
            if (!file.exists() || !file.isFile) {
                result.error("share_pdf_missing_file", "Quote PDF is not available to share.", null)
                return
            }
            if (file.length() <= 0L) {
                result.error("share_pdf_empty_file", "Quote PDF is empty and cannot be shared.", null)
                return
            }
            val contentUri = FileProvider.getUriForFile(
                this,
                "${applicationContext.packageName}.fileprovider",
                file
            )
            val shareIntent = Intent(Intent.ACTION_SEND).apply {
                type = mimeType ?: "application/pdf"
                putExtra(Intent.EXTRA_STREAM, contentUri)
                putExtra(Intent.EXTRA_TEXT, text ?: "")
                putExtra(Intent.EXTRA_SUBJECT, subject ?: fileName ?: "Quotation PDF")
                clipData = ClipData.newUri(contentResolver, fileName ?: file.name, contentUri)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }
            if (!targetPackage.isNullOrBlank()) {
                try {
                    grantUriPermission(
                        targetPackage,
                        contentUri,
                        Intent.FLAG_GRANT_READ_URI_PERMISSION
                    )
                    startActivity(Intent(shareIntent).setPackage(targetPackage))
                    result.success(null)
                    return
                } catch (_: ActivityNotFoundException) {
                    // Fall back to the normal Android share sheet below.
                }
            }
            startActivity(Intent.createChooser(shareIntent, "Share quote PDF"))
            result.success(null)
        } catch (error: Exception) {
            result.error("share_pdf_failed", "Could not open PDF sharing.", null)
        }
    }

    private fun pickDocument(result: MethodChannel.Result) {
        if (pendingPickerResult != null) {
            result.error("picker_busy", "A document picker is already open.", null)
            return
        }

        pendingPickerResult = result
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "*/*"
            putExtra(
                Intent.EXTRA_MIME_TYPES,
                arrayOf(
                    "application/pdf",
                    "application/msword",
                    "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
                    "image/jpeg",
                    "image/png"
                )
            )
        }
        startActivityForResult(intent, pickDocumentRequestCode)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != pickDocumentRequestCode) return

        val result = pendingPickerResult
        pendingPickerResult = null
        if (result == null) return

        if (resultCode != Activity.RESULT_OK || data?.data == null) {
            result.success(null)
            return
        }

        try {
            result.success(copyDocumentToCache(data.data!!))
        } catch (error: Exception) {
            result.error("document_copy_failed", "Could not prepare the selected document.", null)
        }
    }

    private fun copyDocumentToCache(uri: Uri): Map<String, Any> {
        val resolver = applicationContext.contentResolver
        val mimeType = resolver.getType(uri) ?: "application/octet-stream"
        val displayName = safeDisplayName(uri)
        val uploadsDir = File(cacheDir, "daphnex_uploads")
        uploadsDir.mkdirs()
        val destination = File(uploadsDir, displayName)

        resolver.openInputStream(uri).use { input ->
            if (input == null) error("Unable to open selected document.")
            FileOutputStream(destination).use { output -> input.copyTo(output) }
        }

        return mapOf(
            "filePath" to destination.absolutePath,
            "fileName" to displayName,
            "mimeType" to mimeType,
            "fileSize" to destination.length()
        )
    }

    private fun safeDisplayName(uri: Uri): String {
        val resolver = applicationContext.contentResolver
        var name = "crm-document"
        resolver.query(uri, null, null, null, null)?.use { cursor ->
            val index = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
            if (index >= 0 && cursor.moveToFirst()) {
                name = cursor.getString(index) ?: name
            }
        }
        return name
            .replace(Regex("[\\\\/:*?\"<>|]"), "-")
            .replace(Regex("\\s+"), " ")
            .trim()
            .ifEmpty { "crm-document" }
    }
}
