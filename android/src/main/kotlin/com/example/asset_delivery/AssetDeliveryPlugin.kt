package com.example.asset_delivery

import androidx.annotation.NonNull

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** AssetDeliveryPlugin */
class AssetDeliveryPlugin: FlutterPlugin, MethodCallHandler {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel : MethodChannel
  private lateinit var manager: AssetPackManager
  private val coroutineScope = CoroutineScope(Dispatchers.Main)

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "asset_delivery")
    channel.setMethodCallHandler(this)

    // Initialize AssetPackManager and register AssetPackStateListener
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
            assetPackStates.packStates()[assetPackName] ?: throw IllegalStateException("Asset pack state not found")

        Log.d("fetchAssetPackState", assetPackState.status.toString())

        if (assetPackState.status == AssetPackStatus.COMPLETED) {
          Log.d("AssetPack", "Asset Pack is ready to use: $assetPackName")
          result.success(assetPackState.status) // Send result back to Flutter
        } else {
          Log.d("AssetPack", "Asset Pack not ready: Status = ${assetPackState.status}")
          result.success(assetPackState.status) // Send the status to Flutter
        }
      } catch (e: Exception) {
        Log.e("AssetDeliveryPlugin", e.message.toString())
        result.error("ERROR", e.message, null)  // Return an error to the Flutter side
      }
    }
  }

  private fun getAbsoluteAssetPath(assetPack: String): String? {
    val assetPackPath: AssetPackLocation = manager.getPackLocation(assetPack) ?: return null
    return assetPackPath.assetsPath()
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    manager.unregisterListener(assetPackStateListener)
    channel.setMethodCallHandler(null)
  }
}
