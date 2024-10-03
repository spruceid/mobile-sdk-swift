import Foundation
import SpruceIDMobileSdkRs

public class CredentialStore {
    public var credentials: [ParsedCredential]

    public init(credentials: [ParsedCredential]) {
        self.credentials = credentials
    }

    // swiftlint:disable force_cast
    public func presentMdocBLE(deviceEngagement: DeviceEngagement,
                               callback: BLESessionStateDelegate,
                               useL2CAP: Bool = true
                               // , trustedReaders: TrustedReaders
    ) async -> IsoMdlPresentation? {
        if let firstMdoc = self.credentials.first(where: { $0.asMsoMdoc() != nil }) {
            let mdoc = firstMdoc.asMsoMdoc()!
            return await IsoMdlPresentation(mdoc: MDoc(Mdoc: mdoc),
                                     engagement: DeviceEngagement.QRCode,
                                     callback: callback,
                                      useL2CAP: useL2CAP)
        } else {
            return nil
        }
    }
    // swiftlint:enable force_cast
}
