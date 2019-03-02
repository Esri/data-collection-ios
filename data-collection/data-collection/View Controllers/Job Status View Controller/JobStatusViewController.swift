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

protocol JobStatusViewControllerDelegate: AnyObject {
    func jobStatusViewController(didEndAbruptly jobStatusViewController: JobStatusViewController)
    func jobStatusViewController(_ jobStatusViewController: JobStatusViewController, didEndWithError error: Error)
    func jobStatusViewController(_ jobStatusViewController: JobStatusViewController, didEndWithResult result: Any)
}

class JobStatusViewController: UIViewController {
        
    @IBOutlet weak var jobStatusLabel: UILabel!
    @IBOutlet weak var jobStatusProgressView: UIProgressView!
    @IBOutlet weak var cancelButton: UIButton!
    
    weak var delegate: JobStatusViewControllerDelegate?
    
    var jobConstruct: OfflineMapJobConstruct? {
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
        
        // We want to disable the idle timer, keeping the device active as the job performs.
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // By now a job must have been set, otherwise dismiss the view controller.
        guard let job = mapJob else {
            delegate?.jobStatusViewController(didEndAbruptly: self)
            present(simpleAlertMessage: "Something went wrong, could not perform the job.")
            return
        }
        
        // Attach the progress view's observed progress to the job's progress.
        // As the job progresses, the progress view will reflect accordingly.
        jobStatusProgressView.observedProgress = job.progress
        
        // Job message index, for printing.
        var i = 0
        
        job.start(statusHandler: { (_) in
            
            // Print Job messages to console.
            while i < job.messages.count {
                let message = job.messages[i]
                print("[Job: \(i)] \(message.message)")
                i += 1
            }
            
        }) { [weak self] (result, error) in
            
            guard let self = self else { return }
            
            // If there is an error, the job was not successful.
            if let error = error {
                self.handleJob(error: error)
                return
            }
            
            // Handle the successful completion of the job.
            if let result = result {
                self.handleJob(result: result)
            }
            else {
                self.handleJobFailure()
            }
        }
    }
    
    private func handleJob(error: Error) {
        
        // An error is thrown if the user cancelled the error.
        // We want to reflect the messaging to the end-user accordingly.
        if (error as NSError).code == NSUserCancelledError {
            jobStatusLabel.text = jobConstruct?.cancelMessage
        }
        else {
            jobStatusLabel.text = jobConstruct?.errorMessage
        }
        
        delegate?.jobStatusViewController(self, didEndWithError: error)
    }
    
    private func handleJob(result: Any) {
        
        // Pass off the results of the job to the delegate.
        jobStatusLabel.text = jobConstruct?.successMessage
        delegate?.jobStatusViewController(self, didEndWithResult: result)
    }
    
    private func handleJobFailure() {
        
        // An unknown error occured, this should not happen.
        delegate?.jobStatusViewController(didEndAbruptly: self)
        present(simpleAlertMessage: "Something went wrong, could not perform the job.")
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        // The job is finished and the idle timer is turned back on.
        UIApplication.shared.isIdleTimerDisabled = false
    }
    
    @IBAction func userDidTapCancelJob(_ sender: Any) {
        if let appJob = mapJob  {
            // Calling cancel will call the completion closure contained by the job's `start` function.
            appJob.progress.cancel()
        }
        else {
            delegate?.jobStatusViewController(didEndAbruptly: self)
        }
    }
}
