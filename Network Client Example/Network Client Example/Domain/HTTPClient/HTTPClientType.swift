//
//  HTTPClientType.swift
//  Network Client Example
//
//  Created by Manel Roca on 21/4/23.
//

import Foundation

internal protocol HTTPClientType {
    func send(request: URLRequest) async throws -> Data?
    func sendAndDecode<T: Decodable>(request: URLRequest) async throws -> T?
    func clearAllCache()
}
