import Foundation

public class CredentialStore {
    public var credentials: [Credential]

    public init(credentials: [Credential]) {
        self.credentials = credentials
    }

    // swiftlint:disable force_cast
    public func presentMdocBLE(deviceEngagement: DeviceEngagement,
                               callback: BLESessionStateDelegate
                               // , trustedReaders: TrustedReaders
    ) -> BLESessionManager? {
        if let firstMdoc = self.credentials.first(where: {$0 is MDoc}) {
            return BLESessionManager(mdoc: firstMdoc as! MDoc, engagement: DeviceEngagement.QRCode, callback: callback)
        } else {
            return nil
        }
    }
    // swiftlint:enable force_cast
}
