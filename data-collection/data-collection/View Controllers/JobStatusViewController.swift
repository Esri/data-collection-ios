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
import UIKit
import ArcGIS

protocol JobStatusViewControllerDelegate {
    func jobStatusViewController(didEndAbruptly jobStatusViewController: JobStatusViewController)
    func jobStatusViewController(_ jobStatusViewController: JobStatusViewController, didEndWithError error: Error)
    func jobStatusViewController(_ jobStatusViewController: JobStatusViewController, didEndWithResult result: Any)
}

class JobStatusViewController: AppContextAwareController {
    
    // TODO integrate toolkit
    
    @IBOutlet weak var jobStatusLabel: UILabel!
    @IBOutlet weak var jobStatusProgressView: UIProgressView!
    @IBOutlet weak var cancelButton: UIButton!
    
    var delegate: JobStatusViewControllerDelegate?
    
    var jobConstruct: AppOfflineMapJobConstruct? {
        didSet {
            mapJob = jobConstruct?.generateJob()
        }
    }
    
    private var mapJob: AGSJob?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        jobStatusLabel.text = "Preparing"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        jobStatusLabel.text = jobConstruct?.message ?? "Unknown Error"
        
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        guard let job = mapJob else {
            delegate?.jobStatusViewController(didEndAbruptly: self)
            return
        }
        
        job.start(statusHandler: { [weak self] (status) in
            if let job = self?.mapJob, let progressView = self?.jobStatusProgressView {
                progressView.progress = Float(job.progress.fractionCompleted)
            }
        }) { (result, error) in
            
            guard error == nil else {
                if let nserror = error as NSError?, nserror.code == 3072 {
                    self.jobStatusLabel.text = self.jobConstruct?.cancelMessage
                }
                else {
                    self.jobStatusLabel.text = self.jobConstruct?.errorMessage
                }
                self.delegate?.jobStatusViewController(self, didEndWithError: error!)
                return
            }
            if let result = result {
                self.jobStatusLabel.text = self.jobConstruct?.successMessage
                self.delegate?.jobStatusViewController(self, didEndWithResult: result)
            }
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        UIApplication.shared.isIdleTimerDisabled = false
    }
    
    var jobStatusProgress: Float = 0.0 {
        didSet {
            jobStatusProgressView?.progress = status(jobStatusProgress, upperBounds: 1.0, lowerBounds: 0.0)
        }
    }
    
    func status(_ status: Float, upperBounds: Float, lowerBounds: Float) -> Float {
        return max(min(status, upperBounds), lowerBounds)
    }
    
    @IBAction func userDidTapCancelJob(_ sender: Any) {
        if let appJob = mapJob  {
            appJob.progress.cancel()
        }
        else {
            delegate?.jobStatusViewController(didEndAbruptly: self)
        }
    }
}
