//
//  CloudVision.swift
//  gyat
//
//  Created by ku on 2020/01/10.
//  Copyright © 2020 ku KUMAGAI Kentaro. All rights reserved.
//

import Foundation
import AppKit

class CloudVision {
    private let googleAPIKey: String
    var googleURL: URL {
        return URL(string: "https://vision.googleapis.com/v1/images:annotate?key=\(googleAPIKey)")!
    }

    init(accessKey: String) {
        googleAPIKey = accessKey
    }

    func run() {
        executeScript { file in
            self.api(file: file)
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

    struct annotateApiPayload: Encodable {
        let requests: [AnnotateRequest]


        struct AnnotateRequest: Encodable {
            let features: [Feature]
            let image: Image
            let imageContext: ImageContext

            struct Feature: Encodable {
                let type: String = "TEXT_DETECTION"
            }
            struct Image: Encodable {
                let content: String
            }

            struct ImageContext: Encodable {
                let languageHints: [String]
            }
        }
    }

    func api(file: URL) {
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
        guard let json = try? jsonEncoder.encode(payload) else { return }

        let filename = getDocumentsDirectory().appendingPathComponent("request.txt")
        do {
            try json.write(to: filename)
        } catch {
            print(error)
        }

        request.httpBody = json
        DispatchQueue.global().async {
            self.runRequestOnBackgroundThread(request)
        }
    }

    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }

    func runRequestOnBackgroundThread(_ request: URLRequest) {
        // run the request
        let session = URLSession.shared

        let task: URLSessionDataTask = session.dataTask(with: request) { (data, response, error) in
            guard let data = data, error == nil else {
                print(error?.localizedDescription ?? "")
                return
            }

            let filename = self.getDocumentsDirectory().appendingPathComponent("response.txt")
            do {
                try data.write(to: filename)
            } catch {
                print(error)
            }

            let decoder = JSONDecoder()
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



    struct AnnotationResponse: Decodable {
        let responses: [Response]
        struct Response: Decodable {
            let textAnnotations: [Annotation]?
            let fullTextAnnotation: FullTextAnnotation?
            struct Annotation: Decodable {
                let locale: String?
                let descrption: String?
                let boundingPoly: BoundingPoly?

                struct BoundingPoly: Decodable {
                    let verticles: [Point]?

                    struct Point: Decodable {
                        let x: Int
                        let y: Int
                    }
                }
            }
            struct FullTextAnnotation: Decodable {
                let text: String
            }
        }
    }

    func executeScript(completion: @escaping (URL) -> Void) {
        let shellScript = "/usr/sbin/screencapture"
        // assert(FileManager.default.fileExists(atPath: shellScript))
        let unixScript = try! NSUserUnixTask(url: URL(fileURLWithPath: shellScript))
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
                print(error.localizedDescription)
            } else {
                completion(fileUrl)
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
