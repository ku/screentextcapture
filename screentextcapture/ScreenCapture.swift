//
//  ScreenCapture.swift
//  screentextcapture
//
//  Created by ku on 2020/02/16.
//  Copyright © 2020 ku. All rights reserved.
//

import Foundation

class ScreenCapture {
    
    func capture(completion: @escaping (Result<URL, Error>) -> Void) {
        execute(executable: "/usr/sbin/screencapture") { result in
            switch result {
            case .success(let file):
                completion(.success(value: file))
            case .failure(let error):
                completion(.failure(error: error))
            }
        }
    }
    
    private func execute(executable: String, completion: @escaping (Result<URL, Error>) -> Void) {
        let unixScript = try! NSUserUnixTask(url: URL(fileURLWithPath: executable))
        let fileUrl = temporaryFileURL()
        let stdout = try! FileHandle(forWritingTo: fileUrl)
        unixScript.standardOutput = stdout
        
        let shellArguments: [String] = [
            "-tjpg",
            "-i",
            fileUrl.path
        ]
        
        unixScript.execute(withArguments: shellArguments) { error in
            if let error = error {
                completion(.failure(error: error))
            } else {
                if let attributes = try? FileManager.default.attributesOfItem(atPath: fileUrl.path),
                    let size = attributes[.size] as? Int,
                    size > 0 {
                    completion(.success(value: fileUrl))
                } else {
                    completion(.failure(error: ApplicationError.cancelled))
                }
            }
        }
    }
    private func temporaryFileURL() -> URL {
        let destinationURL: URL = FileManager.default.temporaryDirectory
        let temporaryFilename = ProcessInfo().globallyUniqueString
        let temporaryFileURL = destinationURL.appendingPathComponent(temporaryFilename)
        FileManager.default.createFile(atPath: temporaryFileURL.path, contents: nil)
        return temporaryFileURL
    }
    
}
