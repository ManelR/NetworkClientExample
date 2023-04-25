//
//  HTTPError.swift
//  Network Client Example
//
//  Created by Manel Roca on 21/4/23.
//

import Foundation

public enum HTTPError: Error {
    // Server Error
    case authenticationError
    case serverError
    // Client Error
    case clientError
    case conflict
    case notFound
    case noInternet
    case timeout
    // Other
    case JSONParseError
    case responseModelNotConformsDecodable
    case createRequest
    case unknownError
}
