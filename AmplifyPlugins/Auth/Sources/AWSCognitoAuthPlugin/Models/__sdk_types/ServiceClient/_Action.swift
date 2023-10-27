//
//  File.swift
//  
//
//  Created by Saultz, Ian on 10/26/23.
//

import Foundation
import AWSPluginsCore

struct CognitoIdentityAction<Input: Encodable, Output: Decodable> {
    let name: String
    let method: HTTPMethod
    let xAmzTarget: String
    let requestURI: String
    let successCode: Int
    let hostPrefix: String
    let mapError: (Data, HTTPURLResponse) throws -> Error

    let encode: (Input, JSONEncoder) throws -> Data = { model, encoder in
        try encoder.encode(model)
    }

    let decode: (Data, JSONDecoder) throws -> Output = { data, decoder in
        try decoder.decode(Output.self, from: data)
    }

    func url(region: String) throws -> URL {
        guard let url = URL(
            string: "https://\(hostPrefix)cognito-identity.\(region).amazonaws.com\(requestURI)"
        ) else {
            throw PlaceholderError()
        }

        return url
    }
}



