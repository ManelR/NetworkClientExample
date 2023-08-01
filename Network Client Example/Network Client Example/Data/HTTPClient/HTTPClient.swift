//
//  HTTPClient.swift
//  Network Client Example
//
//  Created by Manel Roca on 21/4/23.
//

import Foundation

final class HTTPClient: NSObject, HTTPClientType {
    private var session: URLSession?

    init(session: URLSession? = nil) {
        self.session = session
        super.init()
    }

    func send(request: URLRequest) async throws -> Data? {
        var result: (data: Data?, response: URLResponse?)
        do {
            print("\(getName()): REQUEST \(request.httpMethod ?? "?") - \(request.url?.absoluteString ?? "?")")
            if #available(iOS 15.0, *) {
                result = try await self.makeRequest(request: request)
            } else {
                result = try await self.makeRequestUnderiOS15(request: request)
            }
        } catch {
            try self.handleRequestException(error)
        }

        let status = (result.response as? HTTPURLResponse)?.statusCode ?? 0

        if let httpResponse = result.response as? HTTPURLResponse,
           let date = httpResponse.value(forHTTPHeaderField: "Date") {
            print("\(getName()): RESPONSE \(status) - DATE: \(date)")
        }

        if let data = result.data {
            let body = String(decoding: data, as: UTF8.self)
            print("\(getName()): RESPONSE \(status) - BODY: \(body)")
        }

        guard let httpResponse = result.response as? HTTPURLResponse,
              (200..<300) ~= httpResponse.statusCode else {
            throw exceptionFromStatusCode(status)
        }

        return result.data
    }

    func sendAndDecode<T: Decodable>(request: URLRequest) async throws -> T? {
        guard let data = try await self.send(request: request) else {
            return nil
        }
        // Decode JSON
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let decoded = try decoder.decode(T.self, from: data)
            return decoded
        } catch {
            print("\(getName()): JSON Error \(error.localizedDescription)")
            throw HTTPError.JSONParseError
        }
    }

    func clearAllCache() {
        self.session?.configuration.urlCache?.removeAllCachedResponses()
    }
}

extension HTTPClient {
    private func getURLSession() -> URLSession {
        guard let session = self.session else {
            let configuration = URLSessionConfiguration.default

            configuration.timeoutIntervalForRequest = 30.0
            configuration.timeoutIntervalForResource = 30.0

            let session = URLSession(configuration: configuration,
                                     delegate: nil,
                                     delegateQueue: nil)
            self.session = session
            return session
        }

        return session
    }

    internal func getName() -> String {
        return String(describing: self)
    }

    private func makeRequestUnderiOS15(request: URLRequest) async throws -> (Data?, URLResponse?) {
        return try await withCheckedThrowingContinuation({ continuation in
            let dataTask = self.getURLSession().dataTask(with: request) { data, response, error in
                guard let error = error else {
                    continuation.resume(returning: (data, response))
                    return
                }
                continuation.resume(throwing: error)
            }

            dataTask.resume()
        })
    }

    @available(iOS 15.0, *)
    private func makeRequest(request: URLRequest) async throws -> (Data?, URLResponse?) {
        return try await self.getURLSession().data(for: request)
    }

    private func handleRequestException(_ error: Error?) throws {
        if let error = error as NSError?, error.domain == NSURLErrorDomain {
            if error.code == NSURLErrorNotConnectedToInternet {
                throw HTTPError.noInternet
            } else if error.code == NSURLErrorTimedOut {
                throw HTTPError.timeout
            }
        }
        throw HTTPError.clientError
    }

    private func exceptionFromStatusCode(_ status: Int) -> Error {
        switch status {
        case 401, 403:
            // Auth error
            return HTTPError.authenticationError
        case 404:
            return HTTPError.notFound
        case 409:
            return HTTPError.conflict
        default:
            // Server error
            return HTTPError.serverError
        }
    }
}
