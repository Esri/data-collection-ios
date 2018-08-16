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
        
    @IBOutlet weak var jobStatusLabel: UILabel!
    @IBOutlet weak var jobStatusProgressView: UIProgressView!
    @IBOutlet weak var cancelButton: UIButton!
    
    var delegate: JobStatusViewControllerDelegate?
    
    var jobConstruct: AppOfflineMapJobConstructionInfo? {
        didSet {
            mapJob = jobConstruct?.generateJob()
        }
    }
    
    private var mapJob: AGSJob?
    
    var progressObserver: NSKeyValueObservation?
    
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
        super.viewDidAppear(animated)
        
        guard let job = mapJob else {
            delegate?.jobStatusViewController(didEndAbruptly: self)
            return
        }
        
        progressObserver = job.progress.observe(\.fractionCompleted) { [weak self] (progress,_) in
            DispatchQueue.main.async {
                 self?.jobStatusProgress = Float(progress.fractionCompleted)
            }
        }
        
        job.start(statusHandler: nil) { [weak self] (result, error) in

            guard error == nil else {
                self?.handleJob(error: error!)
                return
            }
            
            if let result = result {
                self?.handleJob(result: result)
            }
            else {
                print("[Job Status View Controller: Job Failure] something went very wrong.")
                self?.handleJobFailure()
            }
        }
    }
    
    private func handleJob(error: Error) {
        
        if let nserror = error as NSError?, nserror.code == 3072 {
            jobStatusLabel.text = jobConstruct?.cancelMessage
        }
        else {
            jobStatusLabel.text = jobConstruct?.errorMessage
        }
        
        delegate?.jobStatusViewController(self, didEndWithError: error)
    }
    
    private func handleJob(result: Any) {
        
        jobStatusLabel.text = jobConstruct?.successMessage
        delegate?.jobStatusViewController(self, didEndWithResult: result)
    }
    
    private func handleJobFailure() {
        
        delegate?.jobStatusViewController(didEndAbruptly: self)
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
