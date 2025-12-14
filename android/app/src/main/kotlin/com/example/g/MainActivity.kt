package com.example.g

import android.content.ContentValues
import android.os.Build
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream

class MainActivity: FlutterFragmentActivity() {
    private val CHANNEL = "com.cash.receipts/media_store"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "saveToGallery") {
                val path = call.argument<String>("path")
                val name = call.argument<String>("name")
                
                if (path != null && name != null) {
                    try {
                        val file = File(path)
                        if (file.exists()) {
                            val contentResolver = contentResolver
                            val imageCollection = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                                MediaStore.Images.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
                            } else {
                                MediaStore.Images.Media.EXTERNAL_CONTENT_URI
                            }

                            val imageDetails = ContentValues().apply {
                                put(MediaStore.Images.Media.DISPLAY_NAME, name)
                                put(MediaStore.Images.Media.MIME_TYPE, "image/jpeg")
                                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                                    put(MediaStore.Images.Media.RELATIVE_PATH, "Pictures/CASH Receipts")
                                    put(MediaStore.Images.Media.IS_PENDING, 1)
                                }
                            }

                            val imageUri = contentResolver.insert(imageCollection, imageDetails)
                            
                            imageUri?.let { uri ->
                                contentResolver.openOutputStream(uri).use { outputStream ->
                                    FileInputStream(file).use { inputStream ->
                                        inputStream.copyTo(outputStream!!)
                                    }
                                }
                                
                                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                                    imageDetails.clear()
                                    imageDetails.put(MediaStore.Images.Media.IS_PENDING, 0)
                                    contentResolver.update(uri, imageDetails, null, null)
                                }
                                
                                result.success(true)
                            } ?: result.error("SAVE_FAILED", "Failed to create media store entry", null)
                        } else {
                            result.error("FILE_NOT_FOUND", "Image file not found", null)
                        }
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                } else {
                    result.error("INVALID_ARGS", "Path or name is null", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
