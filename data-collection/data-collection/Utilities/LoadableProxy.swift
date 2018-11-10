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

import ArcGIS

protocol LoadableProxyDelegate: AGSLoadable where Self: NSObject {
    
    // MARK: AGSLoadableBase
    
    func doStartLoading(_ retrying: Bool, completion: @escaping (Error?) -> Void)
    func doCancelLoading()
    
    // MARK: LoadableProxyDelegate
    
    func loadStatusDidChange(_ status: AGSLoadStatus)
    func loadErrorDidChange(_ error: Error?)
}

/// Allows an object to adhere to `AGSLoadable` via `AGSLoadableBase` in the situation where it cannot subclass `AGSLoadableBase` directly.
///
/// This allows a class to offload async loading and load state to the ArcGIS SDK, keeping thread safety in mind.
///
class LoadableProxy: AGSLoadableBase {
    
    weak var delegate: LoadableProxyDelegate? {
        didSet {
            delegate?.loadStatusDidChange(loadStatus)
            delegate?.loadErrorDidChange(loadError)
        }
    }
    
    private var kvo: Set<NSKeyValueObservation> = []
    
    override init() {
        
        super.init()
        
        let loadStatusObservation = self.observe(\.loadStatus) { [weak self] (_, _) in
            
            guard let self = self else { return }
            
            self.delegate?.loadStatusDidChange(self.loadStatus)
        }
        
        kvo.insert(loadStatusObservation)
        
        let loadErrorObservation = self.observe(\.loadError) { [weak self] (_, _) in
            
            guard let self = self else { return }
            
            self.delegate?.loadErrorDidChange(self.loadError)
        }
        
        kvo.insert(loadErrorObservation)
    }
    
    override func doCancelLoading() {
        
        // Call cancel delegate method.
        delegate?.doCancelLoading()
        
        // Finish with cancel Error.
        loadDidFinishWithError(UserCancelledError)
    }
    
    override func doStartLoading(_ retrying: Bool) {
        
        // We want to unwrap the delegate, if we have one.
        if let delegate = delegate {
            
            // Call start loading on the delegate
            delegate.doStartLoading(retrying) { [weak self] (error) in
                
                guard let self = self else { return }
                
                // Finish loading with the reponse from the delegate.
                self.loadDidFinishWithError(error)
            }
        }
        else {
            // No delegate, finish loading.
            loadDidFinishWithError(UnknownError)
        }
    }
}
