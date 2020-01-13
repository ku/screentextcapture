//
//  CloudVision.swift
//  gyat
//
//  Created by ku on 2020/01/10.
//  Copyright © 2020 ku KUMAGAI Kentaro. All rights reserved.
//

import Foundation
import AppKit
import CoreGraphics

enum Result<T, ErrorType: Error> {
    case success(value: T)
    case failure(error: ErrorType)
}

class CloudVision {
    private let accessKey: String
    private var googleURL: URL {
        return URL(string: "https://vision.googleapis.com/v1/images:annotate?key=\(accessKey)")!
    }
    enum ApplicationError: LocalizedError {
        case failedToBuildRequest
        case captureCancelled
        case networkFailed
        case error(message: String)

        public var errorDescription: String? {
            switch self {
            case .error(let message):
                return message
            default:
                return "\(self)"
            }
        }
    }

    init(accessKey: String) {
        self.accessKey = accessKey
    }

    private var canRecordScreen : Bool {
      guard let windows = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as? [[String: AnyObject]] else { return false }
      return windows.allSatisfy({ window in
          let windowName = window[kCGWindowName as String] as? String
          let isSharingEnabled = window[kCGWindowSharingState as String] as? Int
          return windowName != nil || isSharingEnabled == 1
      })
    }

    func run(completion: @escaping (Result<String, Error>) -> Void) {
        if canRecordScreen {
            capture(completion: completion)
        } else {
            let mainDisplay    = CGMainDisplayID()

            let displayBounds  = CGDisplayBounds(mainDisplay)
            let recordingQueue = DispatchQueue.global(qos: .background)

            // to show permission dialog. but does not work.
            // https://stackoverflow.com/a/58142253
            if let stream = CGDisplayStream(dispatchQueueDisplay: mainDisplay, outputWidth: Int(displayBounds.width), outputHeight: Int(displayBounds.height), pixelFormat: Int32(kCVPixelFormatType_32BGRA), properties: nil, queue: recordingQueue, handler: nil) {
                print(stream)
            }

        }
    }

    private func capture(completion: @escaping (Result<String, Error>) -> Void) {
        execute(executable: "/usr/sbin/screencapture") { result in
            switch result {
            case .success(let file):
                print(file)
                self.annotate(file: file, completion: completion)
            case .failure(let error):
                completion(.failure(error: error))
            }
        }
    }

    func base64Encode(file: URL) -> String {
        guard let data = try? Data(contentsOf: file) else { fatalError("x_X")}

        // Resize the image if it exceeds the 2MB API limit
        if (data.count > 2097152) {
            fatalError("x_X")
        }

        return data.base64EncodedString(options: .endLineWithCarriageReturn)
    }

    private func buildRequest(with file: URL) -> URLRequest? {

        let imageBase64 = base64Encode(file: file)
        var request = URLRequest(url: googleURL)
              request.httpMethod = "POST"
              request.addValue("application/json", forHTTPHeaderField: "Content-Type")
              request.addValue(Bundle.main.bundleIdentifier ?? "", forHTTPHeaderField: "X-Ios-Bundle-Identifier")

        let payload = annotateApiPayload(requests: [
            .init(
                features: [
                    .init()
                ],
                image: .init(content: imageBase64),
                imageContext: .init(languageHints: ["ja", "en"])
            )
        ])

        let jsonEncoder = JSONEncoder()
        guard let json = try? jsonEncoder.encode(payload) else { return nil }

//        let filename = getDocumentsDirectory().appendingPathComponent("request.txt")
//        do {
//            try json.write(to: filename)
//        } catch {
//            print(error)
//        }

        request.httpBody = json
        return request
    }

    func annotate(file: URL, completion: @escaping (Result<String, Error>) -> Void) {
        guard let request = buildRequest(with: file) else {
            completion(.failure(error: ApplicationError.failedToBuildRequest))
            return
        }

        DispatchQueue.global().async { [weak self] in
            self?.send(request: request, completion: completion)
        }
    }

    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }

    private func send(request: URLRequest, completion: @escaping (Result<String, Error>) -> Void) {
        // run the request
        let session = URLSession.shared

        let task: URLSessionDataTask = session.dataTask(with: request) { (data, response, error) in
            if let error = error {
                completion(.failure(error: error))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse,
                let data = data else {
                    completion(.failure(error: ApplicationError.networkFailed))
                    return
            }

            let decoder = JSONDecoder()

            guard httpResponse.statusCode < 400 else {
                do {
                  let response = try decoder.decode(ErrorResponse.self, from: data)
                    completion(.failure(error: ApplicationError.error(message: response.error.message)))
                } catch {
                    completion(.failure(error: error))
                }
                return
            }

            let filename = self.getDocumentsDirectory().appendingPathComponent("response.txt")
            do {
                try data.write(to: filename)
            } catch {
                print(error)
            }

            do {
              let response =  try  decoder.decode(AnnotationResponse.self, from: data)
                guard response.responses.count > 0 else {
                    print("not found")
                    return
                }

                self.copy(response)
                let app = NSApplication.shared
                app.terminate(app)
            } catch {
                print(String(data: data, encoding: .utf8))
                print(error)
            }
        }

        task.resume()
    }

    func copy(_ response: AnnotationResponse) {
        let pasteboard = NSPasteboard.general
        pasteboard.declareTypes([NSPasteboard.PasteboardType.string], owner: nil)

        guard let text = response.responses.first?.fullTextAnnotation?.text else { return }
        pasteboard.setString(text, forType: NSPasteboard.PasteboardType.string)

        NSSound(named: "Ping")?.play()
    }

    func execute(executable: String, completion: @escaping (Result<URL, Error>) -> Void) {
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
                    completion(.failure(error: ApplicationError.captureCancelled))
                }
            }
        }
    }

    func temporaryFileURL() -> URL {
        let destinationURL: URL = FileManager.default.temporaryDirectory
        let temporaryFilename = ProcessInfo().globallyUniqueString
        let temporaryFileURL = destinationURL.appendingPathComponent(temporaryFilename)
        FileManager.default.createFile(atPath: temporaryFileURL.path, contents: nil)
        return temporaryFileURL
    }
}
