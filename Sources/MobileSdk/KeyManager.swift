import CoreFoundation
import Foundation
import Security

import SpruceIDMobileSdkRs

public class KeyManager: NSObject, KeyManagerInterface {

    
    /**
     * Resets the key store by removing all of the keys.
     */
    public func reset() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey
        ]

        let ret = SecItemDelete(query as CFDictionary)
        return ret == errSecSuccess
    }

    /**
     * Checks to see if a secret key exists based on the id/alias.
     */
    public func keyExists(id: SpruceIDMobileSdkRs.Key) -> Bool {
        let tag = id.data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: tag,
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            kSecReturnRef as String: true
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        return status == errSecSuccess
    }

    /**
     * Returns a secret key - based on the id of the key.
     */
    public static func getSecretKey(id: SpruceIDMobileSdkRs.Key) -> SecKey? {
      let tag = id.data(using: .utf8)!
      let query: [String: Any] = [
          kSecClass as String: kSecClassKey,
          kSecAttrApplicationTag as String: tag,
          kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
          kSecReturnRef as String: true
      ]

      var item: CFTypeRef?
      let status = SecItemCopyMatching(query as CFDictionary, &item)

      guard status == errSecSuccess else { return nil }

      // swiftlint:disable force_cast
      let key = item as! SecKey
      // swiftlint:enable force_cast

      return key
    }

    /**
     * Generates a secp256r1 signing key by id
     */
    public func generateSigningKey(id: SpruceIDMobileSdkRs.Key) -> Bool {
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
                kSecAttrAccessControl as String: access
            ]
        ]

        var error: Unmanaged<CFError>?
        SecKeyCreateRandomKey(attributes as CFDictionary, &error)
      if error != nil { print(error!) }
        return error == nil
    }

    /**
     * Returns a JWK for a particular secret key by key id.
     */
    public func getJwk(id: SpruceIDMobileSdkRs.Key) throws -> String {
        guard let key = KeyManager.getSecretKey(id: id) else { throw KeyManagerError.KeyNotFound }

      guard let publicKey = SecKeyCopyPublicKey(key) else {
          throw KeyManagerError.KeyInvalid
      }

      var error: Unmanaged<CFError>?
      guard let data = SecKeyCopyExternalRepresentation(publicKey, &error) as? Data else {
          throw KeyManagerError.UnexpectedUniFfiCallbackError("Failed to copy external representation")
      }

      let fullData: Data = data.subdata(in: 1..<data.count)
      let xDataRaw: Data = fullData.subdata(in: 0..<32)
      let yDataRaw: Data = fullData.subdata(in: 32..<64)

      let xCoordinate = xDataRaw.base64EncodedUrlSafe
      let yCoordinate = yDataRaw.base64EncodedUrlSafe

      let jsonObject: [String: Any]  = [
         "kty": "EC",
         "crv": "P-256",
         "x": xCoordinate,
         "y": yCoordinate
      ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: jsonObject, options: []) else { throw KeyManagerError.UnexpectedUniFfiCallbackError("Failed to serialize JWT") }
      let jsonString = String(data: jsonData, encoding: String.Encoding.ascii)!

      return jsonString
    }

    /**
     * Signs the provided payload with a ecdsaSignatureMessageX962SHA256 private key.
     */
    public func signPayload(id: SpruceIDMobileSdkRs.Key, payload: Data) throws -> Data {
        guard let key = KeyManager.getSecretKey(id: id) else { throw KeyManagerError.KeyNotFound }

        
        let data = try? payload.withUnsafeBytes<UInt8> { (paypointer: UnsafeRawBufferPointer) in
            CFDataCreate(kCFAllocatorDefault, paypointer.baseAddress, payload.count)
        }
        

        let algorithm: SecKeyAlgorithm = .ecdsaSignatureMessageX962SHA256
        var error: Unmanaged<CFError>?
        guard let signature = SecKeyCreateSignature(
            key,
            algorithm,
            data!,
            &error
        ) as Data? else {
          print(error ?? "no error")
            throw KeyManagerError.FailedToSign
        }

        return Data(signature)
    }

    /**
     * Generates an encryption key with a provided id in the Secure Enclave.
     */
    public func generateEncryptionKey(id: SpruceIDMobileSdkRs.Key) -> Bool {
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
                kSecAttrAccessControl as String: access
            ]
        ]

        var error: Unmanaged<CFError>?
        SecKeyCreateRandomKey(attributes as CFDictionary, &error)
        if error != nil { print(error ?? "no error") }
        return error == nil
    }

    /**
     * Encrypts payload by a key referenced by key id.
     */
    public func encryptPayload(id: SpruceIDMobileSdkRs.Key, payload: Data) throws -> EncryptedPayload {
        guard let key = KeyManager.getSecretKey(id: id) else { throw KeyManagerError.KeyNotFound }

        guard let publicKey = SecKeyCopyPublicKey(key) else {
            throw KeyManagerError.FailedToEncrypt
        }

        let data = try? payload.withUnsafeBytes<UInt8> { ( paypointer: UnsafeRawBufferPointer) in
            CFDataCreate(kCFAllocatorDefault, paypointer.baseAddress, payload.count)
        }
        
        let algorithm: SecKeyAlgorithm = .eciesEncryptionCofactorX963SHA512AESGCM
        var error: Unmanaged<CFError>?

        guard let encrypted = SecKeyCreateEncryptedData(
            publicKey,
            algorithm,
            data!,
            &error
        ) as Data? else {
            throw KeyManagerError.FailedToEncrypt
        }

        return ( EncryptedPayload(iv: Data([0]), ciphertext: encrypted) )
    }

    /**
     * Decrypts the provided payload by a key id and initialization vector.
     */
    public func decryptPayload(id: SpruceIDMobileSdkRs.Key, encryptedPayload: EncryptedPayload) throws -> Data {
        guard let key = KeyManager.getSecretKey(id: id) else { throw KeyManagerError.KeyNotFound }

        let data = encryptedPayload.ciphertext().withUnsafeBytes { (paypointer: UnsafeRawBufferPointer) in
            CFDataCreate(kCFAllocatorDefault, paypointer.baseAddress, encryptedPayload.ciphertext().count)
        }

        let algorithm: SecKeyAlgorithm = .eciesEncryptionCofactorX963SHA512AESGCM
        var error: Unmanaged<CFError>?
        guard let decrypted = SecKeyCreateDecryptedData(
            key,
            algorithm,
            data!,
            &error
        ) as Data? else {
            throw KeyManagerError.FailedToDecrypt
        }

        return Data(decrypted)
    }
}
