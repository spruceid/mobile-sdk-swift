import CoreFoundation
import Foundation
import Security

public class KeyManager: NSObject {
    /**
     * Resets the key store by removing all of the keys.
     */
    static func reset() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
        ]
        
        let ret = SecItemDelete(query as CFDictionary)
        return ret == errSecSuccess
    }
  
    /**
     * Checks to see if a secret key exists based on the id/alias.
     */
    static func keyExists(id: String) -> Bool {
        let tag = id.data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: tag,
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            kSecReturnRef as String: true,
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        return status == errSecSuccess
    }
  
    /**
     * Returns a secret key - based on the id of the key.
     */
    static func getSecretKey(id: String) -> SecKey? {
      let tag = id.data(using: .utf8)!
      let query: [String: Any] = [
          kSecClass as String: kSecClassKey,
          kSecAttrApplicationTag as String: tag,
          kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
          kSecReturnRef as String: true,
      ]
      
      var item: CFTypeRef?
      let status = SecItemCopyMatching(query as CFDictionary, &item)
      
      guard status == errSecSuccess else { return nil }
      
      let key = item as! SecKey
      
      return key
    }
    
    /**
     * Generates a secp256r1 signing key by id
     */
    static func generateSigningKey(id: String) -> Bool {
        let tag = id.data(using: .utf8)!
        
        let access = SecAccessControlCreateWithFlags(
            kCFAllocatorDefault,
            kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            .privateKeyUsage,
            nil)!
        
        let attributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeyClass as String: kSecAttrKeyClassPrivate,
            kSecAttrKeySizeInBits as String: NSNumber(value: 256),
            kSecAttrTokenID as String: kSecAttrTokenIDSecureEnclave,
            kSecPrivateKeyAttrs as String: [
                kSecAttrIsPermanent as String: true,
                kSecAttrApplicationTag as String: tag,
                kSecAttrAccessControl as String: access,
            ]
        ]
        
        var error: Unmanaged<CFError>?
        SecKeyCreateRandomKey(attributes as CFDictionary, &error)
      if (error != nil) { print(error!) }
        return error == nil
    }
    
    /**
     * Returns a JWK for a particular secret key by key id.
     */
    static func getJwk(id: String) -> String? {
      guard let key = getSecretKey(id: id) else { return nil }
      
      guard let publicKey = SecKeyCopyPublicKey(key) else {
          return nil
      }
            
      var error: Unmanaged<CFError>?
      guard let data = SecKeyCopyExternalRepresentation(publicKey, &error) as? Data else {
         return nil
      }
      
      let fullData: Data = data.subdata(in: 1..<data.count)
      let xDataRaw: Data = fullData.subdata(in: 0..<32)
      let yDataRaw: Data = fullData.subdata(in: 32..<64)
      
      let x = xDataRaw.base64EncodedUrlSafe
      let y = yDataRaw.base64EncodedUrlSafe

      let jsonObject: [String: Any]  = [
         "kty": "EC",
         "crv": "P-256",
         "x": x,
         "y": y
      ]
      
      guard let jsonData = try? JSONSerialization.data(withJSONObject: jsonObject, options: []) else { return nil }
      let jsonString = String(data: jsonData, encoding: String.Encoding.ascii)!
      
      return jsonString
    }
    
    /**
     * Signs the provided payload with a ecdsaSignatureMessageX962SHA256 private key.
     */
    static func signPayload(id: String, payload: [UInt8]) -> [UInt8]? {
        guard let key = getSecretKey(id: id) else { return nil }
              
        guard let data = CFDataCreate(kCFAllocatorDefault, payload, payload.count) else {
            return nil
        }
        
        let algorithm: SecKeyAlgorithm = .ecdsaSignatureMessageX962SHA256
        var error: Unmanaged<CFError>?
        guard let signature = SecKeyCreateSignature(
            key,
            algorithm,
            data,
            &error
        ) as Data? else {
          print(error ?? "no error")
            return nil
        }
        
        return [UInt8](signature)
    }
    
    /**
     * Generates an encryption key with a provided id in the Secure Enclave.
     */
    static func generateEncryptionKey(id: String) -> Bool {
        let tag = id.data(using: .utf8)!
        
        let access = SecAccessControlCreateWithFlags(
            kCFAllocatorDefault,
            kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            .privateKeyUsage,
            nil)!
        
        let attributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeyClass as String: kSecAttrKeyClassPrivate,
            kSecAttrKeySizeInBits as String: NSNumber(value: 256),
            kSecAttrTokenID as String: kSecAttrTokenIDSecureEnclave,
            kSecPrivateKeyAttrs as String: [
                kSecAttrIsPermanent as String: true,
                kSecAttrApplicationTag as String: tag,
                kSecAttrAccessControl as String: access,
            ]
        ]
        
        var error: Unmanaged<CFError>?
        SecKeyCreateRandomKey(attributes as CFDictionary, &error)
        if (error != nil) { print(error ?? "no error") }
        return error == nil
    }
    
    /**
     * Encrypts payload by a key referenced by key id.
     */
    static func encryptPayload(id: String, payload: [UInt8]) -> ([UInt8], [UInt8])? {
        guard let key = getSecretKey(id: id) else { return nil }
      
        guard let publicKey = SecKeyCopyPublicKey(key) else {
            return nil
        }
      
        guard let data = CFDataCreate(kCFAllocatorDefault, payload, payload.count) else {
            return nil
        }
        
        let algorithm: SecKeyAlgorithm = .eciesEncryptionCofactorX963SHA512AESGCM
        var error: Unmanaged<CFError>?
      
        guard let encrypted = SecKeyCreateEncryptedData(
            publicKey,
            algorithm,
            data,
            &error
        ) as Data? else {
            return nil
        }
        
        return ([0], [UInt8](encrypted))
    }
    
    /**
     * Decrypts the provided payload by a key id and initialization vector.
     */
    static func decryptPayload(id: String, iv: [UInt8], payload: [UInt8]) -> [UInt8]? {
        guard let key = getSecretKey(id: id) else { return nil }
        
        guard let data = CFDataCreate(kCFAllocatorDefault, payload, payload.count) else {
            return nil
        }
        
        let algorithm: SecKeyAlgorithm = .eciesEncryptionCofactorX963SHA512AESGCM
        var error: Unmanaged<CFError>?
        guard let decrypted = SecKeyCreateDecryptedData(
            key,
            algorithm,
            data,
            &error
        ) as Data? else {
            return nil
        }
        
        return [UInt8](decrypted)
    }
}
