public class AssetDeliveryPlugin: NSObject, FlutterPlugin {
    private var methodChannel: FlutterMethodChannel?
    private var progressChannel: FlutterMethodChannel?
    private var progressObservation: NSKeyValueObservation?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "asset_delivery", binaryMessenger: registrar.messenger())
        let progressChannel = FlutterMethodChannel(name: "on_demand_resources_progress", binaryMessenger: registrar.messenger())
        
        let instance = AssetDeliveryPlugin()
        instance.methodChannel = channel
        instance.progressChannel = progressChannel
        
        registrar.addMethodCallDelegate(instance, channel: channel)
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
            print("Tag received: \(tag)")
            getDownloadResources(tag: tag, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func getDownloadResources(tag: String, result: @escaping FlutterResult) {
        let resourceRequest = NSBundleResourceRequest(tags: [tag])
        print("Resource request started for tag: \(tag)")
        
        // Observe the progress of the download
        progressObservation = resourceRequest.progress.observe(\.fractionCompleted) { [weak self] progress, _ in
            self?.sendProgressToFlutter(progress: progress.fractionCompleted)
        }
        
        resourceRequest.beginAccessingResources { [weak self] error in
            guard let self = self else { return }
            
            if let error = error {
                print("Resource request failed: \(error.localizedDescription)")
                self.cleanupProgressObservation()
                result(FlutterError(
                    code: "RESOURCE_ERROR",
                    message: "Error accessing resources for tag: \(tag)",
                    details: error.localizedDescription
                ))
                return
            }
            
            self.handleResourceAccess(tag: tag, result: result)
            resourceRequest.endAccessingResources()
        }
    }

    private func handleResourceAccess(tag: String, result: @escaping FlutterResult) {
        let fileManager = FileManager.default
        let dir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let subfolderURL = dir.appendingPathComponent(tag)
        
        do {
            print("Creating subfolder at: \(subfolderURL.path)")
            try fileManager.createDirectory(at: subfolderURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("Failed to create subfolder: \(error.localizedDescription)")
            cleanupProgressObservation()
            result(FlutterError(
                code: "ERROR_CREATING_FOLDER",
                message: "Error creating folder for tag: \(tag)",
                details: error.localizedDescription
            ))
            return
        }
        
        for i in 1...27 {  // Hardcoded range, customize if needed
            let assetName = "\(tag.uppercased())_\(i)"
            guard let asset = NSDataAsset(name: assetName) else {
                print("Asset not found: \(assetName)")
                cleanupProgressObservation()
                result(FlutterError(
                    code: "RESOURCE_NOT_FOUND",
                    message: "Resource not found for tag: \(tag), asset: \(assetName)",
                    details: nil
                ))
                return
            }
            
            let fileURL = subfolderURL.appendingPathComponent("\(assetName).mp3")
            do {
                print("Saving asset to \(fileURL.path)")
                try asset.data.write(to: fileURL)
            } catch {
                print("Failed to save asset: \(error.localizedDescription)")
                cleanupProgressObservation()
                result(FlutterError(
                    code: "ERROR_SAVING_FILE",
                    message: "Error saving file \(fileURL) for tag: \(tag)",
                    details: error.localizedDescription
                ))
                return
            }
        }
        
        print("All assets downloaded successfully for tag: \(tag)")
        cleanupProgressObservation()
        result(subfolderURL.absoluteString)
    }

    private func cleanupProgressObservation() {
        progressObservation?.invalidate()
        progressObservation = nil
    }

    private func sendProgressToFlutter(progress: Double) {
        DispatchQueue.main.async {
            self.progressChannel?.invokeMethod("updateProgress", arguments: progress)
        }
    }
}
