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

extension MapViewController {
    
    func setupMapView() {
        
        mapView.touchDelegate = self
        mapView.releaseHardwareResourcesWhenBackgrounded = true
        mapView.interactionOptions.isMagnifierEnabled = false
    }
    
    func setupActivityBarView() {
        
        let activity = ActivityBarView(mapView: mapView, colors: (a: UIColor.primary.lighter, b: UIColor.primary.darker))
        
        activity.translatesAutoresizingMaskIntoConstraints = false
        
        self.view.addSubview(activity)
        
        let top = activity.topAnchor.constraint(equalTo: mapView.topAnchor, constant: 0.0)
        let leading = activity.leadingAnchor.constraint(equalTo: mapView.leadingAnchor, constant: 0.0)
        let trailing = activity.trailingAnchor.constraint(equalTo: mapView.trailingAnchor, constant: 0.0)
        
        NSLayoutConstraint.activate([top, leading, trailing])

        activityBarView = activity
    }
    
    func setupMapViewAttributionBarAutoLayoutConstraints() {
        
        featureDetailViewBottomConstraint = mapView.attributionTopAnchor.constraint(equalTo: smallPopupView.bottomAnchor, constant: 8)
        featureDetailViewBottomConstraint.isActive = true
    }
    
    func setupSmallPopupView() {
        
        smallPopupView.addTarget(self, action: #selector(MapViewController.didTapSmallPopupView(_:)), for: .touchUpInside)
    }
}
