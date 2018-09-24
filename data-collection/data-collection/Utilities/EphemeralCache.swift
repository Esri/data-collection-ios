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

/// A singleton, thread-safe caching system that allows you to set `AnyObject` that is both retrieved and removed from the cache upon the first get of that object.
///
/// The `EphemeralCachce` accomplishes this using `NSCache` and a concurrent `DispatchQueue` (with a barrier flag).
///
class EphemeralCache {
    
    private static let shared = EphemeralCache()
    
    private var cache = NSCache<AnyObject, AnyObject>()
    
    private var queue = DispatchQueue(label: "\(appBundleID).ephemeralCache", attributes: .concurrent)
    
    private init() { }
    
    private subscript(key: String) -> AnyObject? {
        get {
            return queue.sync {
                return cache.object(forKey: key as AnyObject)
            }
        }
        set {
            queue.async(flags: .barrier) { [weak self] in
                guard let newValue = newValue else {
                    self?.cache.removeObject(forKey: key as AnyObject)
                    return
                }
                self?.cache.setObject(newValue, forKey: key as AnyObject)
            }
        }
    }
    
    static func set(object: Any, forKey: String) {
        shared[forKey] = object as AnyObject
    }
    
    static func get(objectForKey key: String) -> Any? {
        let object: AnyObject? = shared[key]
        shared[key] = nil
        return object
    }
    
    static func remove(objectForKey key: String) {
        shared[key] = nil
    }
}
