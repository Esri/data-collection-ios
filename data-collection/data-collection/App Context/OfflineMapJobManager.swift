// Copyright 2020 Esri
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

protocol OfflineMapJobManagerDelegate: class {
    func offlineMapJobManager(_ manager: OfflineMapJobManager, job: OfflineMapJobManager.Job, onDemandDownloadResult: AGSGenerateOfflineMapResult)
    func offlineMapJobManager(_ manager: OfflineMapJobManager, job: OfflineMapJobManager.Job, syncResult: AGSOfflineMapSyncResult)
    func offlineMapJobManager(_ manager: OfflineMapJobManager, job: OfflineMapJobManager.Job, failed error: Error)
}

class OfflineMapJobManager {
    
    private enum Status {
        case none
        case staged(UUID, AGSJob)
        case downloading(UUID, AGSGenerateOfflineMapJob)
        case synchronizing(UUID, AGSOfflineMapSyncJob)
    }
    
    private var status: Status = .none {
        didSet {
            switch status {
            case .none:
                print(
                    "[Offline Map Job Manager]",
                    "\n\tNo job"
                )
            case .staged(_, let job):
                print(
                    "[Offline Map Job Manager]",
                    "\n\tStaged - ", "\(type(of: job))"
                )
            case .downloading(_, let job):
                print(
                    "[Offline Map Job Manager]",
                    "\n\tDownloading - ", job.onlineMap?.item?.title ?? "(no title)"
                )
            case .synchronizing(_, let job):
                print(
                    "[Offline Map Job Manager]",
                    "\n\tSynchronizing - ", job.parameters.syncDirection
                )
            }
        }
    }
    
    private var currentJobID: UUID? {
        switch status {
        case .staged(let id, _):
            return id
        case .downloading(let id, _):
            return id
        case .synchronizing(let id, _):
            return id
        default:
            return nil
        }
    }
    private var isJobInProgress: Bool {
        switch status {
        case .none, .staged:
            return false
        case .downloading, .synchronizing:
            return true
        }
    }
    
    struct OfflineMapManagerError: LocalizedError {
        let localizedDescription: String
    }
    
    // MARK: Job
    
    class Job: NSObject {
        
        let id = UUID()
        let progress: Progress
        let type: JobType
        
        var jobMessages: ((String) -> Void)? = nil
        var completion: ((Bool) -> Void)? = nil
        
        fileprivate init(job: AGSJob) {
            self.progress = job.progress
            switch job {
            case is AGSGenerateOfflineMapJob:
                self.type = .GenerateOfflineMap
            case is AGSOfflineMapSyncJob:
                self.type = .OfflineMapSync
            default:
                preconditionFailure("Unsupported job type.")
            }
        }
        
        enum JobType {
            case GenerateOfflineMap
            case OfflineMapSync
        }
    }
    
    // MARK: Create Job
    
    func stageOnDemandDownloadMapJob(_ map: AGSMap, extent: AGSGeometry, scale: Double, url: URL) throws -> Job {
        
        guard !isJobInProgress else {
            throw OfflineMapManagerError(localizedDescription: "A job is already in progress.")
        }
                        
        let offlineMapTask = AGSOfflineMapTask(
            onlineMap: map
        )
        
        let offlineMapParameters = AGSGenerateOfflineMapParameters(
            areaOfInterest: extent,
            minScale: scale,
            maxScale: map.maxScale
        )
        
        let offlineMapJob = offlineMapTask.generateOfflineMapJob(
            with: offlineMapParameters,
            downloadDirectory: url
        )
                        
        let job = Job(job: offlineMapJob)
        
        status = .staged(job.id, offlineMapJob)
        
        return job
    }
    
    func stageSyncMapJob(_ map: AGSMap) throws -> Job {
        
        guard !isJobInProgress else {
            throw OfflineMapManagerError(localizedDescription: "A job is already in progress.")
        }
                
        let task = AGSOfflineMapSyncTask(map: map)
        
        let params: AGSOfflineMapSyncParameters = {
            let params = AGSOfflineMapSyncParameters()
            params.syncDirection = .bidirectional
            return params
        }()
        
        let syncJob = task.offlineMapSyncJob(with: params)
                        
        let job = Job(job: syncJob)
        
        status = .staged(job.id, syncJob)

        return job
    }
    
    // MARK: Start Job
    
    func startJob(_ job: Job) throws {
        
        guard case let .staged(stagedID, stagedJob) = status else {
            throw OfflineMapManagerError(localizedDescription: "Job (\(job.id)) does not exist.")
        }
        
        guard stagedID == job.id else {
            throw OfflineMapManagerError(localizedDescription: "Job (\(job.id)) is no longer staged.")
        }
        
        job.jobMessages?("Starting job...")
        
        switch stagedJob {
        case is AGSGenerateOfflineMapJob:
            startOnDemandDownloadMapJob(job, generateOfflineMapJob: stagedJob as! AGSGenerateOfflineMapJob)
        case is AGSOfflineMapSyncJob:
            startSyncMapJob(job, syncMapJob: stagedJob as! AGSOfflineMapSyncJob)
        default:
            preconditionFailure("Unsupported request type.")
        }
    }
    
    private func startOnDemandDownloadMapJob(_ job: Job, generateOfflineMapJob: AGSGenerateOfflineMapJob) {

        status = .downloading(job.id, generateOfflineMapJob)
                
        // Job message index, for printing.
        var i = 0
        
        job.jobMessages?("Downloading map offline")
        
        generateOfflineMapJob.start(statusHandler: { [weak self] (status) in
            guard let self = self else { return }
            self.logMessages(generateOfflineMapJob, i: &i)
        }) { [weak self] (result, error) in
            guard let self = self else { return }
                        
            // If there is an error, the job was not successful.
            if let error = error {
                job.jobMessages?(error.localizedDescription)
                self.delegate?.offlineMapJobManager(self, job: job, failed: error)
            }
            
            // Handle the successful completion of the job.
            else if let result = result {
                job.jobMessages?("Success")
                self.delegate?.offlineMapJobManager(self, job: job, onDemandDownloadResult: result)
            }
            
            self.status = .none
        }
    }
    
    private func startSyncMapJob(_ job: Job, syncMapJob: AGSOfflineMapSyncJob) {
        
        status = .synchronizing(job.id, syncMapJob)
                
        // Job message index, for printing.
        var i = 0
        
        job.jobMessages?("Synchronizing offline map")
        
        syncMapJob.start(statusHandler: { [weak self] (status) in
            guard let self = self else { return }
            self.logMessages(syncMapJob, i: &i)
        }) { [weak self] (result, error) in
            guard let self = self else { return }
            
            // If there is an error, the job was not successful.
            if let error = error {
                job.jobMessages?(error.localizedDescription)
                self.delegate?.offlineMapJobManager(self, job: job, failed: error)
            }
                
            // Handle the successful completion of the job.
            else if let result = result {
                job.jobMessages?("Success")
                self.delegate?.offlineMapJobManager(self, job: job, syncResult: result)
            }
            
            self.status = .none
        }
    }
    
    private func logMessages(_ job: AGSJob, i: inout Int) {
        // Print Job messages to console.
        while i < job.messages.count {
            let message = job.messages[i]
            print(
                "[Job: \(i)]",
                "\n\t\(message.message)"
            )
            i += 1
        }
    }
    
    // MARK: Delegate
    
    weak var delegate: OfflineMapJobManagerDelegate?
}

extension AGSSyncDirection: CustomStringConvertible {
    public var description: String {
        switch self {
        case .bidirectional:
            return "Bi-directional"
        case .upload:
            return "Upload"
        case .download:
            return "Download"
        case .none:
            return "None"
        @unknown default:
            fatalError("Unsupported \(type(of: self)) type.")
        }
    }
}
