package com.github.mohsenmotlagh.asset_delivery

import android.content.res.AssetManager
import android.util.Log
import com.google.android.play.core.assetpacks.AssetPackLocation
import com.google.android.play.core.assetpacks.AssetPackManager
import com.google.android.play.core.assetpacks.AssetPackManagerFactory
import com.google.android.play.core.assetpacks.AssetPackState
import com.google.android.play.core.assetpacks.AssetPackStates
import com.google.android.play.core.assetpacks.model.AssetPackStatus
import com.google.android.play.core.ktx.requestPackStates
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.InputStream
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

/** AssetDeliveryPlugin */
class AssetDeliveryPlugin : FlutterPlugin, MethodCallHandler {

  private lateinit var channel: MethodChannel
  private lateinit var manager: AssetPackManager
  private lateinit var assetPackStateListener: AssetPackStateListener
  private val coroutineScope = CoroutineScope(Dispatchers.Main)
  private lateinit var applicationContext: android.content.Context

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "asset_delivery")
    channel.setMethodCallHandler(this)

    // Initialize AssetPackManager and register AssetPackStateListener
    applicationContext = flutterPluginBinding.applicationContext
    manager = AssetPackManagerFactory.getInstance(flutterPluginBinding.applicationContext)
    assetPackStateListener = AssetPackStateListener(channel)
    manager.registerListener(assetPackStateListener)
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
      "fetch" -> {
        val assetPackName = call.argument<String>("assetPack") ?: ""
        manager.fetch(listOf(assetPackName))
        result.success(true)
      }
      // get assets path
      "getAssets" -> {
        val assetPackName = call.argument<String>("assetPack") ?: ""
        val assetPath = getAbsoluteAssetPath(assetPackName)
        if (assetPath != null) {
          result.success(assetPath)
        } else {
          result.error("ASSET_PATH_ERROR", "Asset path not found", null)
        }
      }
      "fetchAssetPackState" -> {
        val assetPackName = call.argument<String>("assetPack") ?: ""
        fetchAssetPackState(result, assetPackName)
      }
      "getInstallTimeAssetBytes" -> {
        val assetPackName = call.argument<String>("assetPack") ?: ""
        val assetBytes = getInstallTimeAssetBytes(assetPackName)
          result.success(assetBytes)
      }
      else -> {
        result.notImplemented()
      }
    }
  }

  private fun fetchAssetPackState(result: Result, assetPackName: String) {
    coroutineScope.launch {
      try {
        val assetPackStates: AssetPackStates = manager.requestPackStates(listOf(assetPackName))
        val assetPackState: AssetPackState =
                assetPackStates.packStates()[assetPackName]
                        ?: throw IllegalStateException("Asset pack state not found")

        Log.d("fetchAssetPackState", assetPackState.status().toString())

          val assetPackStatus = assetPackState.status()


        if (assetPackStatus == AssetPackStatus.COMPLETED) {
          Log.d("AssetPack", "Asset Pack is ready to use: $assetPackName")
          result.success(assetPackStatus) // Send result back to Flutter
        } else {
          Log.d("AssetPack", "Asset Pack not ready: Status = ${assetPackState.status()}")
          result.success(assetPackStatus) // Send the status to Flutter
        }
      } catch (e: Exception) {
        Log.e("AssetDeliveryPlugin", e.message.toString())
        result.error("ERROR", e.message, null) // Return an error to the Flutter side
      }
    }
  }

  private fun getAbsoluteAssetPath(assetPack: String): String? {
    val assetPackPath: AssetPackLocation = manager.getPackLocation(assetPack) ?: return null
    return assetPackPath.assetsPath()
  }

  private fun getInstallTimeAssetBytes(relativeAssetPath: String): ByteArray {
    val assetManager: AssetManager = applicationContext.assets
    val stream: InputStream = assetManager.open(relativeAssetPath)
    val bytes = stream.readBytes()
    stream.close()
    return bytes
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    manager.unregisterListener(assetPackStateListener)
    channel.setMethodCallHandler(null)
  }
}
