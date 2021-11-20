/*
 *  license-start
 *
 *  Copyright (C) 2021 Zucchetti S.p.a and all other contributors
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
*/

import Foundation

public enum SyncResult
{
    case updated
    case sdkOutdated
    case error(error: String)
}

public struct SdkOutdatedError : Error {
    
}

public class DataSynchronizer {
    public init(){
    }
    
    public init(initLocalData: Bool) {
        if(initLocalData) {
            LocalData.initialize { }
        }
    }
    
    public func sync(completion: @escaping (SyncResult) -> Void)
    {
        guard !isSdkVersionOutdated() else {
            completion(.sdkOutdated)
            return
        }
        GatewayConnection.shared.initialize { [weak self] in self?.load(completion: completion) }
    }
    
    public func getLastUpdate() -> Date? {
        let lastFetch = LocalData.sharedInstance.lastFetch
        return lastFetch.timeIntervalSince1970 > 0 ? lastFetch : nil
    }
    
    private func load(completion: @escaping (SyncResult) -> Void) {
        SettingDataStorage.initialize {
            GatewayConnection.shared.settings { _ in }
        }
        LocalData.initialize {
            GatewayConnection.shared.update { errorString in
                if let error = errorString {
                    completion(.error(error: error))
                    return
                }
                completion(.updated)
            }
        }
    }
    
    public func isSdkVersionOutdated() -> Bool {
        guard let minVersion = minSdkVersion() else { return false }
        return currentSdkVersion().compare(minVersion, options: .numeric) == .orderedAscending
    }
    
    public func currentSdkVersion() -> String {
        return SDKConfig.SDKVersion
    }
    
    private func minSdkVersion() -> String? {
        return SettingDataStorage
            .sharedInstance
            .settings
            .first(where: { $0.name == "sdk" })?
            .value
    }
}