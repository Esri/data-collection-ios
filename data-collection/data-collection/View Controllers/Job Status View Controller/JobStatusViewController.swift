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

class JobStatusViewController: UIViewController {
        
    @IBOutlet weak var jobStatusLabel: UILabel!
    @IBOutlet weak var jobStatusProgressView: UIProgressView!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var doneButton: UIButton!
    
    var job: OfflineMapJobManager.Job!
    
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        job.jobMessages = { [weak self] (message) in
            guard let self = self else { return }
            self.jobStatusLabel.text = message
        }
        
        job.completion = { [weak self] (success) in
            guard let self = self else { return }
            self.updateForFinishedJob(successfully: success)
        }
        
        jobStatusProgressView.observedProgress = job.progress
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // We want to disable the idle timer, keeping the device active as the job performs.
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        do {
            try appContext.offlineMapManager.startJob(job: job)
        }
        catch {
            self.jobStatusLabel.text = error.localizedDescription
            updateForFinishedJob(successfully: false)
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        // The job is finished and the idle timer is turned back on.
        UIApplication.shared.isIdleTimerDisabled = false
    }
    
    // MARK: Finished Job
    
    private func updateForFinishedJob(successfully success: Bool) {
        cancelButton.isEnabled = false
        doneButton.isEnabled = true
        if !success {
            jobStatusProgressView.progress = 0.0
        }
        else {
            jobStatusProgressView.progress = 1.0
        }
    }
    
    // MARK: Actions
    
    @IBAction func userDidTapCancelJob(_ sender: Any) {
        jobStatusProgressView.observedProgress?.cancel()
    }
    
    @IBAction func userDidTapDone(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}
