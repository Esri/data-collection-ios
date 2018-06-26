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
    
    // MARK: Components and Extensions
    
    struct OfflineDirectoryComponents {
        
        static let dataCollection = "data_collection"
        static let offlineMap = "offlineMap"
        static let generatedAssets = "generatedAssets"
    }
    
    struct OfflineExtentImage {
        
        static let fileName = "offlineMapExtent"
        static let fileExtension = "png"
        
        var image: UIImage
        
        var data: Data? {
            return UIImagePNGRepresentation(image)
        }
    }
    
    // MARK: Temporary Map Directory
    
    public static var temporaryOfflineMapDirectoryURL: URL {
        let tmpDir = NSTemporaryDirectory()
        return
            URL(fileURLWithPath: tmpDir)
            .appendingPathComponent(OfflineDirectoryComponents.dataCollection)
            .appendingPathComponent(OfflineDirectoryComponents.offlineMap)
    }
    
    static func prepareTemporaryOfflineMapDirectory() throws {
        
        let path = temporaryOfflineMapDirectoryURL
        
        do {
            try FileManager.default.createDirectory(at: path, withIntermediateDirectories: true, attributes: nil)
            try FileManager.default.removeItem(at: path)
        }
        catch {
            throw error
        }
    }
    
    // MARK: URLs
    
    private static var baseDocumentsDirectoryURL: URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    private static var dataCollectionDocsDirectoryURL: URL {
        return baseDocumentsDirectoryURL.appendingPathComponent(OfflineDirectoryComponents.dataCollection)
    }
    
    public static var offlineMapDirectoryURL: URL {
        return dataCollectionDocsDirectoryURL.appendingPathComponent(OfflineDirectoryComponents.offlineMap)
    }
    
    private static var appGeneratedAssetsDirectoryURL: URL {
        return dataCollectionDocsDirectoryURL.appendingPathComponent(OfflineDirectoryComponents.generatedAssets)
    }
    
    private static var offlineExtentImageFileURL: URL {
        return appGeneratedAssetsDirectoryURL.appendingPathComponent(OfflineExtentImage.fileName).appendingPathExtension(OfflineExtentImage.fileExtension)
    }
    
    // MARK: Offline Directories
    
    static func buildOfflineDirectories() {
        
        buildOfflineMapDirectory()
        buildGeneratedAssetsDirectory()
    }
    
    static func buildOfflineMapDirectory() {
        
        let path = offlineMapDirectoryURL
        
        do {
            try FileManager.default.createDirectory(at: path, withIntermediateDirectories: true, attributes: nil)
        }
        catch {
            print("[Error: AppFiles] could not create directory: \(path) with error:", error.localizedDescription)
        }
    }
    
    static func buildGeneratedAssetsDirectory() {
        
        let path = appGeneratedAssetsDirectoryURL

        do {
            try FileManager.default.createDirectory(at: path, withIntermediateDirectories: true, attributes: nil)
        }
        catch {
            print("[Error: AppFiles] could not create directory: \(path) with error:", error.localizedDescription)
        }
    }
    
    // MARK: Offline Extent Image
    
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
