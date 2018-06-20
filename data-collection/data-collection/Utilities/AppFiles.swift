//// Copyright 2018 Esri
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import Foundation
import ArcGIS


extension FileManager {
    
//    private static var temporaryDocumentsDirectory: URL? {
//        return URL(string: NSTemporaryDirectory())
//    }
//    
//    public static var temporaryOfflineMapDirectoryURL: URL? {
//        
//        guard var path = temporaryDocumentsDirectory else {
//            print("[Error: AppFiles] failed to build url for temporary offline map documents directory.")
//            return nil
//        }
//        path.appendPathComponent("offlineMap")
//        return path
//    }
    
    private static var baseDocumentsDirectoryURL: URL? {
        do {
            return try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor:nil, create:false)
        }
        catch {
            print("[Error: AppFiles] failed to build url for base docs directory.", error.localizedDescription)
            return nil
        }
    }
    
    private static var dataCollectionDocsDirectoryURL: URL? {
        
        guard var path = baseDocumentsDirectoryURL else {
            print("[Error: AppFiles] failed to build url for data collection documents directory.")
            return nil
        }
        path.appendPathComponent("data_collection")
        return path
    }
    
    public static var offlineMapDirectoryURL: URL? {
        
        guard var path = dataCollectionDocsDirectoryURL else {
            print("[Error: AppFiles] failed to build url for offline map documents directory.")
            return nil
        }
        path.appendPathComponent("offlineMap")
        return path
    }
    
    private static var appGeneratedAssetsDirectoryURL: URL? {
        
        guard var path = dataCollectionDocsDirectoryURL else {
            print("[Error: AppFiles] failed to build url for generated assets documents directory.")
            return nil
        }
        path.appendPathComponent("generatedAssets")
        return path
    }
    
    private static var offlineExtentImageFileURL: URL? {
        
        guard var path = appGeneratedAssetsDirectoryURL else {
            print("[Error: AppFiles] failed to build url for offline extent image file documents directory.")
            return nil
        }
        path.appendPathComponent(OfflineExtentImage.fileName)
        path.appendPathExtension(OfflineExtentImage.fileExtension)
        return path
    }
    
    static func buildOfflineDirectories() {
//        prepareTemporaryOfflineMapDirectory()
        buildOfflineMapDirectory()
        buildGeneratedAssetsDirectory()
    }
    
//    static func prepareTemporaryOfflineMapDirectory() {
//        guard let path = temporaryOfflineMapDirectoryURL else {
//            print("[Error: AppFiles] failed to build url for temporary offline map documents directory.")
//            return
//        }
//        do {
//            try FileManager.default.removeItem(at: path)
//        }
//        catch {
//            print("[Error: AppFiles] could not create directory: \(path) with error:", error.localizedDescription)
//        }
//    }
    
    static func buildOfflineMapDirectory() {
        guard let path = offlineMapDirectoryURL else {
            print("[Error: AppFiles] failed to build url for offline map documents directory.")
            return
        }
        do {
            try FileManager.default.createDirectory(at: path, withIntermediateDirectories: true, attributes: nil)
        }
        catch {
            print("[Error: AppFiles] could not create directory: \(path) with error:", error.localizedDescription)
        }
    }
    
    static func buildGeneratedAssetsDirectory() {
        guard let path = appGeneratedAssetsDirectoryURL else {
            print("[Error: AppFiles] failed to build url for generated assets documents directory.")
            return 
        }
        do {
            try FileManager.default.createDirectory(at: path, withIntermediateDirectories: true, attributes: nil)
        }
        catch {
            print("[Error: AppFiles] could not create directory: \(path) with error:", error.localizedDescription)
        }
    }
    
    struct OfflineExtentImage {
        
        static let fileName = "offlineMapExtent"
        static let fileExtension = "png"
        
        var image: UIImage
        
        var data: Data? {
            return UIImagePNGRepresentation(image)
        }
    }
    
    // TODO incorporate
    // TODO string feedback for UI
    
//    static var offlineExtentImageFile: UIImage? {
//        get {
//            guard let path = offlineExtentImageFileURL else {
//                print("[Error: AppFiles] could not build path to offline map extent image file.")
//                return nil
//            }
//
//            guard FileManager.default.fileExists(atPath: path.absoluteString) else {
//                print("[AppFiles] no offline map extent image file at path \(path).")
//                return nil
//            }
//
//            guard FileManager.default.isReadableFile(atPath: path.absoluteString) else {
//                print("[Error: AppFiles] cannot read offline map extent image file at path \(path).")
//                return nil
//            }
//
//            guard let image = UIImage(contentsOfFile: path.absoluteString) else {
//                print("[Error: AppFiles] file exists at offline extent image file path but could not load image at path \(path).")
//                return nil
//            }
//
//            return image
//        }
//        set {
//            guard let path = offlineExtentImageFileURL else {
//                print("[Error: AppFiles] could not build path to offline map extent image file.")
//                return
//            }
//
//            if FileManager.default.fileExists(atPath: path.absoluteString) {
//                guard FileManager.default.isDeletableFile(atPath: path.absoluteString) else {
//                    print("[Error: AppFiles] cannot delete offline map extent image file at path \(path).")
//                    return
//                }
//                do {
//                    try FileManager.default.removeItem(at: path)
//                }
//                catch {
//                    print("[Error: AppFiles] cannot remove item at path: \(path) with error:", error.localizedDescription)
//                    return
//                }
//            }
//
//            if let newImage = newValue {
//                guard FileManager.default.isWritableFile(atPath: path.absoluteString) else {
//                    print("[Error: AppFiles] cannot write offline map extent image file to path \(path).")
//                    return
//                }
//                let extentImage = OfflineExtentImage(image: newImage)
//                FileManager.default.createFile(atPath: path.absoluteString, contents: extentImage.data, attributes: nil)
//            }
//        }
//    }
}
