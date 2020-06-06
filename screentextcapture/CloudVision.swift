//
//  CloudVision.swift
//  screentextcapture
//
//  Created by ku on 2020/02/16.
//  Copyright © 2020 ku. All rights reserved.
//

import Foundation
import AppKit

enum Result<T, ErrorType: Error> {
    case success(value: T)
    case failure(error: ErrorType)
}


enum CloudVisionError: LocalizedError {
    case textNotFound(rawText: String?)

    var errorDescription: String? {
        switch self {
        case .textNotFound(let rawText):
            return "CloundVisionError.textNotFound \(rawText ?? "")"
        }
    }
}


class CloudVision: NSObject {
    private let accessKey: String
    private var googleURL: URL {
        return URL(string: "https://vision.googleapis.com/v1/images:annotate?key=\(accessKey)")!
    }
    enum ApplicationError: LocalizedError {
        case failedToBuildRequest
        case imageTooLarge
        case captureCancelled
        case networkFailed
        case error(message: String)
        case capturedImageReadError

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

    func annotate(file: URL, completion: @escaping (Result<String, Error>) -> Void) {
        let result = base64Encode(file: file)
        switch result {
        case .success(let base64Text):
            guard let request = buildRequest(with: base64Text) else {
                completion(.failure(error: ApplicationError.failedToBuildRequest))
                return
            }

            DispatchQueue.global().async {
                self.send(request: request, completion: completion)
            }
        case .failure(let error):
            completion(.failure(error: error))
        }

    }



    private func base64Encode(file: URL) -> Result<String, ApplicationError> {
        guard let data = try? Data(contentsOf: file) else { return .failure(error: .capturedImageReadError) }

        // Resize the image if it exceeds the 2MB API limit
        if (data.count > 2_097_152) {
            return .failure(error: .imageTooLarge)
        }

        return .success(value: data.base64EncodedString(options: .endLineWithCarriageReturn))
    }

    private func buildRequest(with base64Text: String) -> URLRequest? {
        var request = URLRequest(url: googleURL)
              request.httpMethod = "POST"
              request.addValue("application/json", forHTTPHeaderField: "Content-Type")
              request.addValue(Bundle.main.bundleIdentifier ?? "", forHTTPHeaderField: "X-Ios-Bundle-Identifier")

        let payload = annotateApiPayload(requests: [
            .init(
                features: [
                    .init()
                ],
                image: .init(content: base64Text),
                imageContext: .init(languageHints: ["ja", "en"])
            )
        ])

        let jsonEncoder = JSONEncoder()
        guard let json = try? jsonEncoder.encode(payload) else { return nil }
        request.httpBody = json
        return request
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

//            writeToLocalFile(data)

            do {
              let response = try decoder.decode(AnnotationResponse.self, from: data)
                guard let text = response.responses.first?.fullTextAnnotation?.text else {
                    completion(.failure(error: CloudVisionError.textNotFound(rawText: String(data: data, encoding: .utf8))))
                    return
                }
                completion(.success(value: text))
            } catch {
                completion(.failure(error: error))
            }
        }

        task.resume()
    }

    private func writeToLocalFile(_ data: Data) {
        let filename = self.getDocumentsDirectory().appendingPathComponent("response.txt")
        do {
            try data.write(to: filename)
        } catch {
            print(error)
        }
    }
}

