import CryptoKit
import Foundation

public class CredentialPack {
    private var credentials: [Credential]

    public init() {
        credentials = []
    }

    public init(credentials: [Credential]) {
        self.credentials = credentials
    }

    public func addW3CVC(credentialString: String) throws -> [Credential]? {
        do {
            let credential = try W3CVC(credentialString: credentialString)
            credentials.append(credential)
            return credentials
        } catch {
            throw error
        }
    }

    public func addMDoc(mdocBase64: String, keyAlias: String = UUID().uuidString) throws -> [Credential]? {
        let mdocData = Data(base64Encoded: mdocBase64)!
        let credential = MDoc(fromMDoc: mdocData, namespaces: [:], keyAlias: keyAlias)!
        credentials.append(credential)
        return credentials
    }

    public func get(keys: [String]) -> [String: [String: GenericJSON]] {
        var values: [String: [String: GenericJSON]] = [:]
        for cred in credentials {
            values[cred.id] = cred.get(keys: keys)
        }

        return values
    }

    public func get(credentialsIds: [String]) -> [Credential] {
        return credentials.filter { credentialsIds.contains($0.id) }
    }

    public func get(credentialId: String) -> Credential? {
        if let credential = credentials.first(where: { $0.id == credentialId }) {
            return credential
        } else {
            return nil
        }
    }
}
