import CoreBluetooth
import SpruceIDMobileSdkRs

public class MDocReader {
    var sessionManager: MdlSessionManager
    var bleManager: MDocReaderBLEPeripheral!
    var callback: BLEReaderSessionStateDelegate

    public init?(callback: BLEReaderSessionStateDelegate, uri: String, requestedItems: [String: [String: Bool]], trustAnchorRegistry: [String]?) {
        self.callback = callback
        do {
            let sessionData = try SpruceIDMobileSdkRs.establishSession(uri: uri, requestedItems: requestedItems, trustAnchorRegistry: trustAnchorRegistry)
            sessionManager = sessionData.state
            bleManager = MDocReaderBLEPeripheral(callback: self, serviceUuid: CBUUID(string: sessionData.uuid), request: sessionData.request, bleIdent: sessionData.bleIdent)
        } catch {
            print("\(error)")
            return nil
        }
    }

    public func cancel() {
        bleManager.disconnect()
    }
}

extension MDocReader: MDocReaderBLEDelegate {
    func callback(message: MDocReaderBLECallback) {
        switch message {
        case let .done(data):
            callback.update(state: .success(data))
        case .connected:
            callback.update(state: .connected)
        case let .error(error):
            callback.update(state: .error(BleReaderSessionError(readerBleError: error)))
            cancel()
        case let .message(data):
            do {
                let responseData = try SpruceIDMobileSdkRs.handleResponse(state: sessionManager, response: data)
                sessionManager = responseData.state
                callback.update(state: .success(responseData.verifiedResponse))
            } catch {
                callback.update(state: .error(.generic("\(error)")))
                cancel()
            }
        case let .downloadProgress(index):
            callback.update(state: .downloadProgress(index))
        }
    }
}

/// To be implemented by the consumer to update the UI
public protocol BLEReaderSessionStateDelegate: AnyObject {
    func update(state: BLEReaderSessionState)
}

public enum BLEReaderSessionState {
    /// App should display the error message
    case error(BleReaderSessionError)
    /// App should indicate to the reader is waiting to connect to the holder
    case advertizing
    /// App should indicate to the user that BLE connection has been established
    case connected
    /// App should display the fact that a certain amount of data has been received
    /// - Parameters:
    ///   - 0: The number of chunks received to far
    case downloadProgress(Int)
    /// App should display a success message and offer to close the page
    case success([String: [String: MDocItem]])
}

public enum BleReaderSessionError {
    /// When communication with the server fails
    case server(String)
    /// When Bluetooth is unusable (e.g. unauthorized).
    case bluetooth(CBCentralManager)
    /// Generic unrecoverable error
    case generic(String)

    init(readerBleError: MdocReaderBleError) {
        switch readerBleError {
        case let .server(string):
            self = .server(string)
        case let .bluetooth(string):
            self = .bluetooth(string)
        }
    }
}
