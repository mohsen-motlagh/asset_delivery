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
        
        // Observe the progress of the download
        progressObservation = resourceRequest.progress.observe(\.fractionCompleted) { progress, _ in
            self.sendProgressToFlutter(progress: progress.fractionCompleted)
        }
        
        resourceRequest.beginAccessingResources { [self] error in
            if let error = error {
                result(FlutterError(code: "RESOURCE_ERROR",
                                    message: "Error accessing resources for tag \(tag)",
                                    details: error.localizedDescription))
                return
            }
            
            let fileManager = FileManager.default
            let dir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
            let subfolderName = tag
            let subfolderURL = dir.appendingPathComponent(subfolderName)
            
            do {
                try fileManager.createDirectory(at: subfolderURL, withIntermediateDirectories: true, attributes: nil)
            } catch {
                result(FlutterError(code: "ERROR_CREATING_FOLDER",
                                    message: "Error creating folder for tag \(tag)",
                                    details: error.localizedDescription))
                return
            }
            
            for i in 1...27 {
                if let asset = NSDataAsset(name: "\(tag.uppercased())_\(i)") {
                    let fileURL = subfolderURL.appendingPathComponent("\(tag.uppercased())_\(i).mp3")
                    do {
                        try asset.data.write(to: fileURL)
                    } catch {
                        result(FlutterError(code: "ERROR_SAVING_FILE",
                                            message: "Error saving file \(fileURL) for tag \(tag)",
                                            details: error.localizedDescription))
                        return
                    }
                } else {
                    result(FlutterError(code: "RESOURCE_NOT_FOUND",
                                        message: "Resource not found for tag \(tag)",
                                        details: nil))
                    return
                }
            }
            
            result(subfolderURL.absoluteString)
            progressObservation?.invalidate()
            progressObservation = nil
            resourceRequest.endAccessingResources()
        }
    }
    
    /// Send progress updates to Flutter
    private func sendProgressToFlutter(progress: Double) {
        DispatchQueue.main.async {
            self.progressChannel?.invokeMethod("updateProgress", arguments: progress)
        }
    }
}
