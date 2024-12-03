import Flutter
import UIKit

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
        if let args = call.arguments as? [String: Any], 
           let tag = args["tag"] as? String {
            print("args: \(args)")
            print("tag: \(tag)")
            getDownloadResources(tag: tag, result: result)
        } else {
            result(FlutterError(code: "INVALID_ARGUMENT",
                                message: "Tag not provided",
                                details: nil))
        }
    default:
        result(FlutterMethodNotImplemented)
    }
}

  /// Method to download resources and return their path
private func getDownloadResources(tag: String, result: @escaping FlutterResult) {
    let resourceRequest = NSBundleResourceRequest(tags: [tag])
    print("Starting resource request for tag: \(tag)")
    
    // Observe the progress of the download
    progressObservation = resourceRequest.progress.observe(\.fractionCompleted) { progress, _ in
        self.sendProgressToFlutter(progress: progress.fractionCompleted)
    }
    
    resourceRequest.beginAccessingResources { [weak self] error in
        guard let self = self else { return }
        if let error = error {
            print("Error accessing resources: \(error.localizedDescription)")
            self.progressObservation?.invalidate()
            result(FlutterError(
                code: "RESOURCE_ERROR",
                message: "Error accessing resources for tag: \(tag)",
                details: error.localizedDescription
            ))
            return
        }
        
        print("Successfully accessed resources for tag: \(tag)")
        let fileManager = FileManager.default
        let dir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let subfolderURL = dir.appendingPathComponent(tag)
        
        do {
            print("Creating subfolder: \(subfolderURL.path)")
            try fileManager.createDirectory(at: subfolderURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("Error creating folder: \(error.localizedDescription)")
            self.progressObservation?.invalidate()
            result(FlutterError(
                code: "ERROR_CREATING_FOLDER",
                message: "Error creating folder for tag: \(tag)",
                details: error.localizedDescription
            ))
            return
        }
        
        for i in 1...27 {
            let assetName = "\(tag.uppercased())_\(i)"
            if let asset = NSDataAsset(name: assetName) {
                let fileURL = subfolderURL.appendingPathComponent("\(assetName).mp3")
                do {
                    print("Saving asset \(assetName) to \(fileURL.path)")
                    try asset.data.write(to: fileURL)
                } catch {
                    print("Error saving asset \(assetName): \(error.localizedDescription)")
                    self.progressObservation?.invalidate()
                    result(FlutterError(
                        code: "ERROR_SAVING_FILE",
                        message: "Error saving file \(fileURL) for tag: \(tag)",
                        details: error.localizedDescription
                    ))
                    return
                }
            } else {
                print("Asset not found: \(assetName)")
                self.progressObservation?.invalidate()
                result(FlutterError(
                    code: "RESOURCE_NOT_FOUND",
                    message: "Resource not found for tag: \(tag), asset: \(assetName)",
                    details: nil
                ))
                return
            }
        }
        
        print("All assets saved successfully for tag: \(tag)")
        result(subfolderURL.absoluteString)
        self.progressObservation?.invalidate()
        self.progressObservation = nil
        resourceRequest.endAccessingResources()
    }
}

    
    /// Send progress updates to Flutter
    private func sendProgressToFlutter(progress: Double) {
        DispatchQueue.main.async {
            self.progressChannel?.invokeMethod("updateProgress", arguments: progress)
        }
    }

    //  private func sendProgressToFlutter(progress: Double) {
    //     DispatchQueue.main.async {
    //         guard let controller = self.window?.rootViewController as? FlutterViewController else {
    //             return
    //         }
    //         let progressChannel = FlutterMethodChannel(name: "on_demand_resources_progress",
    //                                                    binaryMessenger: controller.binaryMessenger)
    //         progressChannel.invokeMethod("updateProgress", arguments: progress)
    //     }
    // }
}
