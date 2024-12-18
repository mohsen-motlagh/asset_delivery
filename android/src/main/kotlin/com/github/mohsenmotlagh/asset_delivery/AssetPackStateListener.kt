import android.util.Log
import com.google.android.play.core.assetpacks.AssetPackState
import com.google.android.play.core.assetpacks.model.AssetPackStatus
import io.flutter.plugin.common.MethodChannel

class AssetPackStateListener(
    private var methodChannel: MethodChannel
) : (AssetPackState) -> Unit {

    override fun invoke(assetPackState: AssetPackState) {
        when (assetPackState.status()) {
            AssetPackStatus.PENDING -> {
                Log.d("====asset status====", "Pending")
                sendStatusToFlutter("Pending", 0.0)
            }
            AssetPackStatus.DOWNLOADING -> {
                Log.d("====asset status====", "Downloading")
                val downloaded = assetPackState.bytesDownloaded()
                Log.d("====asset download bytes====", downloaded.toString())
                val totalSize = assetPackState.totalBytesToDownload()
                Log.d("====asset totoal size====", totalSize.toString())
                val percent = downloaded.toDouble() / totalSize.toDouble()
                Log.d("====asset percent====", percent.toString())
                sendStatusToFlutter("Downloading", percent)
            }
            AssetPackStatus.TRANSFERRING -> {
                Log.d("====asset status====", "TRANSFERRING")
                sendStatusToFlutter("Transferring assets", 0.99)
            }
            AssetPackStatus.COMPLETED -> {
                Log.d("====asset status====", "COMPLETED")
                sendStatusToFlutter("Asset pack is ready to use.", 100.0)
            }
            AssetPackStatus.FAILED -> {
                Log.d("====asset status====", "FAILED")
                sendStatusToFlutter("Failed: ${assetPackState.errorCode()}", 0.0)
            }
            AssetPackStatus.CANCELED -> {
                Log.d("====asset status====", "CANCELED")
                sendStatusToFlutter("Canceled.", 0.0)
            }
            AssetPackStatus.NOT_INSTALLED -> {
                Log.d("====asset status====", "NOT_INSTALLED")
                sendStatusToFlutter("Not Installed.", 0.0)
            }
            AssetPackStatus.UNKNOWN -> {
                Log.d("====asset status====", "UNKNOWN")
                sendStatusToFlutter("Unknown status.", 0.0)
            }
        }
    }

    private fun sendStatusToFlutter(status: String, downloadProgress: Double) {
        Log.d("==== inside send to flutter====1111111", downloadProgress.toString()),
        val statusMap = mapOf("status" to status,
        "downloadProgress" to downloadProgress)
        Log.d("==== inside send to flutter====", statusMap.toString()),
        methodChannel.invokeMethod("onAssetPackStatusChange", statusMap)
    }
}