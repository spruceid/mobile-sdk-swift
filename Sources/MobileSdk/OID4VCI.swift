import Foundation

import SpruceIDMobileSdkRs

public class Oid4vciDefaultHttpClient : SpruceIDMobileSdkRs.HttpClient {
    public func httpClient(request: HttpRequest) throws -> HttpResponse {
        guard let url = URL(string: request.url) else {
            throw HttpClientError.Other(error: "failed to construct URL")
        }
        
        let session = URLSession.shared
        var req = URLRequest(url: url,
                             cachePolicy: .useProtocolCachePolicy,
                             timeoutInterval: 60)
        req.httpMethod = request.method
        req.httpBody = request.body
        req.allHTTPHeaderFields = request.headers
        
        let semaphore = DispatchSemaphore(value: 0)

        var data: Data?
        var response: URLResponse?
        var error: Error?
        
        let dataTask = session.dataTask(with: req) {
            data = $0
            response = $1
            error = $2

            semaphore.signal()
        }
        dataTask.resume()

        _ = semaphore.wait(timeout: .distantFuture)
        
        if let error {
            throw HttpClientError.Other(error: "failed to execute request: \(error)")
        }
        
        guard let response = response as? HTTPURLResponse else {
            throw HttpClientError.Other(error: "failed to parse response")
        }
        
        guard let data = data else {
            throw HttpClientError.Other(error: "failed to parse response data")
        }
        
        guard let statusCode = UInt16(exactly: response.statusCode) else {
            throw HttpClientError.Other(error: "failed to parse response status code")
        }
        
        let headers = try response.allHeaderFields.map({ (k, v) in
            guard let k = k as? String else {
                throw HttpClientError.HeaderParse
            }
            
            guard let v = v as? String else {
                throw HttpClientError.HeaderParse
            }
            
            return (k, v)
        })
        
        return HttpResponse(
            statusCode: statusCode,
            headers: Dictionary(uniqueKeysWithValues: headers),
            body: data)
    }
}

public class Oid4vci {
    let httpClient: SpruceIDMobileSdkRs.HttpClient;
    
    public init(httpClient: SpruceIDMobileSdkRs.HttpClient) {
        self.httpClient = httpClient
    }
    
    public convenience init() {
        self.init(httpClient: Oid4vciDefaultHttpClient())
    }

    public func getMetadata(
        session: Oid4vciSession
    ) async throws -> Oid4vciMetadata {
        try await SpruceIDMobileSdkRs.oid4vciGetMetadata(
            session: session)
    }
    
    public func initiateWithOffer(
        credentialOffer: String,
        clientId: String,
        redirectUrl: String
    ) async throws -> Oid4vciSession {
        try await SpruceIDMobileSdkRs.oid4vciInitiateWithOffer(
            credentialOffer: credentialOffer,
            clientId: clientId,
            redirectUrl: redirectUrl,
            httpClient: self.httpClient)
    }
    
    public func initiate(
        baseUrl: String,
        clientId: String,
        redirectUrl: String
    ) async throws -> Oid4vciSession {
        try await SpruceIDMobileSdkRs.oid4vciInitiate(
            baseUrl: baseUrl,
            clientId: clientId,
            redirectUrl: redirectUrl,
            httpClient: self.httpClient)
    }

    public func exchangeToken(
        session: Oid4vciSession
    ) throws -> String? {
        try SpruceIDMobileSdkRs.oid4vciExchangeToken(
            session: session,
            httpClient: self.httpClient)
    }

    public func exchangeCredential(
        session: Oid4vciSession,
        proofsOfPossession: [String]
    ) async throws -> [SpruceIDMobileSdkRs.CredentialResponse] {
        try await SpruceIDMobileSdkRs.oid4vciExchangeCredential(
            session: session,
            proofsOfPossession: proofsOfPossession,
            httpClient: self.httpClient)
    }

    public func generatePopPrepare(
        audience: String,
        issuer: String,
        nonce: String?,
        vm: String,
        publicJwk: String,
        durationInSecs: Int64?
    ) throws -> [UInt8] {
        let prepare = try SpruceIDMobileSdkRs.generatePopPrepare(
            audience: audience,
            issuer: issuer,
            nonce: nonce,
            vm: vm,
            publicJwk: publicJwk,
            durationInSecs: durationInSecs)
        
        return [UInt8](prepare)
    }

    public func generatePopComplete(
        signingInput: [UInt8],
        signature: [UInt8]
    ) throws -> String {
        let complete = try SpruceIDMobileSdkRs.generatePopComplete(
            signingInput: Data(signingInput),
            signature: Data(signature))
        
        return complete
    }
}
