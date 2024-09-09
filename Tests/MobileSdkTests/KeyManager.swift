//
//  File.swift
//  
//
//  Created by Ross Schulman on 9/7/24.
//

import Foundation
import XCTest
@testable import SpruceIDMobileSdk
@testable import SpruceIDMobileSdkRs

final class KeyManager: XCTestCase {
    /**
            Tests encrypting and decrypting a payload
     */
    func testEncryptionAndDecryption() throws {
        let keyManager = SpruceIDMobileSdk.KeyManager()
        let keyId = SpruceIDMobileSdkRs.Key("testid")
        let madeKey = keyManager.generateEncryptionKey(id: keyId)
        XCTAssertTrue(madeKey)
        let payload = "encryption and decryption payload"
        
        let payloadData = Data(payload.utf8)
        
        let encrypted = try keyManager.encryptPayload(id: keyId, payload: payloadData)
        
        let decrypted = try keyManager.decryptPayload(id: keyId, encryptedPayload: encrypted)
        
        XCTAssertEqual(Data(payload.utf8), decrypted)
    }
}
