import android.util.Log
import com.google.android.play.core.assetpacks.AssetPackManager
import com.google.android.play.core.assetpacks.AssetPackState
import com.google.android.play.core.assetpacks.model.AssetPackStatus

class AssetPackStateListener(
    private val assetPackManager: AssetPackManager,
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
                val totalSize = assetPackState.totalBytesToDownload()
                val percent = downloaded.toDouble() / totalSize.toDouble()
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
        val statusMap = mapOf("status" to status,
        "downloadProgress" to downloadProgress)
        methodChannel.invokeMethod("onAssetPackStatusChange", statusMap)
    }
}