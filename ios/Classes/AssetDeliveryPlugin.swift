import Flutter
import UIKit

public class AssetDeliveryPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
    private var methodChannel: FlutterMethodChannel?
    private var eventChannel: FlutterEventChannel?
    private var eventSink: FlutterEventSink?
    private var progressObservation: NSKeyValueObservation?

    /// Held for the lifetime of the request. A local would be released as soon
    /// as `getDownloadResources` returned, cancelling the download in flight.
    private var resourceRequest: NSBundleResourceRequest?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "asset_delivery", binaryMessenger: registrar.messenger())
        let eventChannel = FlutterEventChannel(name: "asset_delivery/events", binaryMessenger: registrar.messenger())

        let instance = AssetDeliveryPlugin()
        instance.methodChannel = channel
        instance.eventChannel = eventChannel

        registrar.addMethodCallDelegate(instance, channel: channel)
        eventChannel.setStreamHandler(instance)
    }

    // MARK: - FlutterStreamHandler

    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getDownloadResources":
            guard let args = call.arguments as? [String: Any],
                  let tag = args["tag"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENT",
                                    message: "Tag not provided",
                                    details: nil))
                return
            }
            getDownloadResources(tag: tag, args: args, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func getDownloadResources(tag: String, args: [String: Any], result: @escaping FlutterResult) {
        let request = NSBundleResourceRequest(tags: [tag])
        resourceRequest = request

        sendStatus(tag: tag, status: "pending", progress: 0.0)

        // Observe the progress of the download
        progressObservation = request.progress.observe(\.fractionCompleted) { [weak self] progress, _ in
            self?.sendStatus(tag: tag, status: "downloading", progress: progress.fractionCompleted)
        }

        request.beginAccessingResources { [weak self] error in
            guard let self = self else { return }

            if let error = error {
                self.cleanupProgressObservation()
                self.sendStatus(tag: tag, status: "failed", progress: 0.0,
                                errorCode: (error as NSError).code)
                result(FlutterError(
                    code: "RESOURCE_ERROR",
                    message: "Error accessing resources for tag: \(tag)",
                    details: error.localizedDescription
                ))
                return
            }

            self.handleResourceAccess(tag: tag, args: args, result: result)
            request.endAccessingResources()
            self.resourceRequest = nil
        }
    }

    private func handleResourceAccess(tag: String, args: [String: Any], result: @escaping FlutterResult) {
        let fileManager = FileManager.default
        let dir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let subfolderURL = dir.appendingPathComponent(tag)


        do {
            try fileManager.createDirectory(at: subfolderURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            cleanupProgressObservation()
            sendStatus(tag: tag, status: "failed", progress: 0.0)
            result(FlutterError(
                code: "ERROR_CREATING_FOLDER",
                message: "Error creating folder for tag: \(tag)",
                details: error.localizedDescription
            ))
            return
        }
        let range = args["assetRange"] as? Int ?? 1
        let namingPattern = args["namingPattern"] as? String ?? "\(tag.uppercased())_%d"
        let fileExtension = args["extension"] as? String ?? "mp3"

        // `1...range` traps when range < 1, so an empty pack must skip the loop.
        if range >= 1 {
        for i in 1...range {  // Provide dynamic range, customize if needed
            let assetName = String(format: namingPattern, i)
            if let image = UIImage(named: assetName) {
            // Save image as PNG or JPG
            let fileURL = subfolderURL.appendingPathComponent("\(assetName).png")
            if let imageData = image.pngData() {
                do {
                    try imageData.write(to: fileURL)
                } catch {
                    cleanupProgressObservation()
                    sendStatus(tag: tag, status: "failed", progress: 0.0)
                    result(FlutterError(
                        code: "ERROR_SAVING_IMAGE",
                        message: "Error saving image \(fileURL) for tag: \(tag)",
                        details: error.localizedDescription
                    ))
                    return
                }
            }
        } else if let asset = NSDataAsset(name: assetName) {
            // Save as raw data for videos, sounds, etc.
            let fileURL = subfolderURL.appendingPathComponent("\(assetName).\(fileExtension)")
            do {
                try asset.data.write(to: fileURL)
            } catch {
                cleanupProgressObservation()
                sendStatus(tag: tag, status: "failed", progress: 0.0)
                result(FlutterError(
                    code: "ERROR_SAVING_FILE",
                    message: "Error saving file \(fileURL) for tag: \(tag)",
                    details: error.localizedDescription
                ))
                return
            }
        } else {
            cleanupProgressObservation()
            sendStatus(tag: tag, status: "failed", progress: 0.0)
            result(FlutterError(
                code: "RESOURCE_NOT_FOUND",
                message: "Resource not found for tag: \(tag), asset: \(assetName)",
                details: nil
            ))
            return
            }
        }
        }

        cleanupProgressObservation()
        sendStatus(tag: tag, status: "completed", progress: 1.0)
        result(subfolderURL.absoluteString)
    }

    private func cleanupProgressObservation() {
        progressObservation?.invalidate()
        progressObservation = nil
    }

    /// Emits a status update shaped identically to the Android payload, so the
    /// Dart layer can treat both platforms uniformly.
    private func sendStatus(tag: String, status: String, progress: Double, errorCode: Int? = nil) {
        DispatchQueue.main.async {
            var payload: [String: Any] = [
                "name": tag,
                "status": status,
                "downloadProgress": progress,
                "bytesDownloaded": 0,
                "totalBytesToDownload": 0,
            ]
            if let errorCode = errorCode {
                payload["errorCode"] = errorCode
            }
            self.eventSink?(payload)
        }
    }
}
