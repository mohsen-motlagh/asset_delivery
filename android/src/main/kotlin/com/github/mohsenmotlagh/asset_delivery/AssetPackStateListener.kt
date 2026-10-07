package com.github.mohsenmotlagh.asset_delivery

import android.util.Log
import com.google.android.play.core.assetpacks.AssetPackState
import com.google.android.play.core.assetpacks.model.AssetPackStatus

private const val TAG = "AssetDelivery"

/**
 * Translates Play Asset Delivery state callbacks into the platform-neutral
 * payload consumed by the Dart side.
 *
 * The status strings emitted here must stay in sync with the `AssetPackStatus`
 * enum in `lib/src/asset_pack_status.dart`; they are matched by name.
 */
class AssetPackStateListener(
    private val onUpdate: (Map<String, Any?>) -> Unit
) : (AssetPackState) -> Unit {

    override fun invoke(assetPackState: AssetPackState) {
        val status = when (assetPackState.status()) {
            AssetPackStatus.PENDING -> "pending"
            AssetPackStatus.DOWNLOADING -> "downloading"
            AssetPackStatus.TRANSFERRING -> "transferring"
            AssetPackStatus.COMPLETED -> "completed"
            AssetPackStatus.FAILED -> "failed"
            AssetPackStatus.CANCELED -> "canceled"
            AssetPackStatus.NOT_INSTALLED -> "notInstalled"
            AssetPackStatus.WAITING_FOR_WIFI -> "waitingForWifi"
            else -> "unknown"
        }

        val downloaded = assetPackState.bytesDownloaded()
        val total = assetPackState.totalBytesToDownload()

        // A resident pack reports total == 0, which would make the ratio NaN.
        val progress = when {
            status == "completed" -> 1.0
            total > 0L -> (downloaded.toDouble() / total.toDouble()).coerceIn(0.0, 1.0)
            else -> 0.0
        }

        Log.d(TAG, "${assetPackState.name()}: $status ($downloaded/$total)")

        onUpdate(
            mapOf(
                "name" to assetPackState.name(),
                "status" to status,
                "downloadProgress" to progress,
                "bytesDownloaded" to downloaded,
                "totalBytesToDownload" to total,
                "errorCode" to
                    assetPackState.errorCode().takeIf { status == "failed" }
            )
        )
    }
}
