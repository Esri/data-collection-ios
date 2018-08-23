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

class AppContextAwareNavigationController: UINavigationController {
    
    var changeHandler = AppContextChangeHandler()
    
    override init(navigationBarClass: AnyClass?, toolbarClass: AnyClass?) {
        super.init(navigationBarClass: navigationBarClass, toolbarClass: toolbarClass)
        subscribeToWorkModeChange()
        adjustNavigationBarTintForWorkMode()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        subscribeToWorkModeChange()
        adjustNavigationBarTintForWorkMode()
    }
    
    private func adjustNavigationBarTintForWorkMode() {
        navigationBar.barTintColor = appContext.workMode == .online ? appColors.primary : appColors.offline
    }
    
    private func subscribeToWorkModeChange() {
        
        let workModeChange: AppContextChange = .workMode { [weak self] (workMode) in
            self?.adjustNavigationBarTintForWorkMode()
        }
        
        changeHandler.subscribe(toChange: workModeChange)
    }
}
