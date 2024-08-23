import Foundation
import CryptoKit

public class CredentialPack {
    
    private var credentials: [Credential]
    
    public init() {
        self.credentials = []
    }
    
    public init(credentials: [Credential]) {
        self.credentials = credentials
    }
    
    public func addW3CVC(credentialString: String) throws -> [Credential]? {
        do {
            let credential = try W3CVC(credentialString: credentialString)
            self.credentials.append(credential)
            return self.credentials
        } catch {
            throw error
        }
    }
    
    public func addMDoc(mdocBase64: String, keyPEM: String) throws -> [Credential]? {
        do {
            let mdocData = Data(base64Encoded: mdocBase64)!
            let key = try P256.Signing.PrivateKey(pemRepresentation: keyPEM)
            let attributes = [kSecAttrKeyType: kSecAttrKeyTypeECSECPrimeRandom,
                             kSecAttrKeyClass: kSecAttrKeyClassPrivate] as [String: Any]
            let secKey = SecKeyCreateWithData(key.x963Representation as CFData,
                                              attributes as CFDictionary,
                                              nil)!
            let query = [kSecClass: kSecClassKey,
          kSecAttrApplicationLabel: "mdoc_key",
                kSecAttrAccessible: kSecAttrAccessibleWhenUnlocked,
     kSecUseDataProtectionKeychain: true,
                      kSecValueRef: secKey] as [String: Any]
            SecItemDelete(query as CFDictionary)
            let status = SecItemAdd(query as CFDictionary, nil)
            print("Status store item: \(status.description)")
            let credential = MDoc(fromMDoc: mdocData, namespaces: [:], keyAlias: "mdoc_key")!
            self.credentials.append(credential)
            return self.credentials
        } catch {
            throw error
        }
    }
    
    public func get(keys: [String]) -> [String:[String:GenericJSON]] {
        var values: [String:[String:GenericJSON]] = [:]
        for c in self.credentials {
            values[c.id] = c.get(keys: keys)
        }
        
        return values
    }
    
    public func get(credentialsIds: [String]) -> [Credential] {
        return self.credentials.filter { credentialsIds.contains($0.id) }
    }
    
    public func get(credentialId: String) -> Credential? {
        if let credential = self.credentials.first(where: { $0.id == credentialId }) {
           return credential
        } else {
           return nil
        }
    }
}
