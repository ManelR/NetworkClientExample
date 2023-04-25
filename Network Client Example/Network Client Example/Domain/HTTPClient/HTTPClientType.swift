//
//  HTTPClientType.swift
//  Network Client Example
//
//  Created by Manel Roca on 21/4/23.
//

import Foundation

protocol HTTPClientType {
    func send(request: URLRequest) async throws -> Data?
}
