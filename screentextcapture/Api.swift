//
//  Api.swift
//  screentextcapture
//
//  Created by ku on 2020/02/16.
//  Copyright © 2020 ku. All rights reserved.
//

import Foundation

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

struct ErrorResponse: Decodable {
    let error: Error
    struct Error: Decodable {
        let code: Int
        let message: String
        let status: String
    }
}
