import CoreBluetooth
import SpruceIDMobileSdkRs

let holderStateCharacteristicId = CBUUID(string: "00000001-A123-48CE-896B-4C76973373E6")
let holderClient2ServerCharacteristicId = CBUUID(string: "00000002-A123-48CE-896B-4C76973373E6")
let holderServer2ClientCharacteristicId = CBUUID(string: "00000003-A123-48CE-896B-4C76973373E6")
let holderL2CAPCharacteristicId = CBUUID(string: "0000000A-A123-48CE-896B-4C76973373E6")

let readerStateCharacteristicId = CBUUID(string: "00000005-A123-48CE-896B-4C76973373E6")
let readerClient2ServerCharacteristicId = CBUUID(string: "00000006-A123-48CE-896B-4C76973373E6")
let readerServer2ClientCharacteristicId = CBUUID(string: "00000007-A123-48CE-896B-4C76973373E6")
let readerIdentCharacteristicId = CBUUID(string: "00000008-A123-48CE-896B-4C76973373E6")
let readerL2CAPCharacteristicId = CBUUID(string: "0000000B-A123-48CE-896B-4C76973373E6")

enum MdocHolderBleError {
    /// When discovery or communication with the peripheral fails
    case peripheral(String)
    /// When Bluetooth is unusable (e.g. unauthorized).
    case bluetooth(CBCentralManager)
}

enum MdocReaderBleError {
    /// When communication with the server fails
    case server(String)
    /// When Bluetooth is unusable (e.g. unauthorized).
    case bluetooth(CBCentralManager)
}

enum MDocBLECallback {
    case done
    case connected
    case message(Data)
    case error(MdocHolderBleError)
    /// Chunks sent so far and total number of chunks to be sent
    case uploadProgress(Int, Int)
}

protocol MDocBLEDelegate: AnyObject {
    func callback(message: MDocBLECallback)
}

enum MDocReaderBLECallback {
    case done([String: [String: MDocItem]])
    case connected
    case error(MdocReaderBleError)
    case message(Data)
    /// Chunks received so far
    case downloadProgress(Int)
}

protocol MDocReaderBLEDelegate: AnyObject {
    func callback(message: MDocReaderBLECallback)
}

/// Return a string describing a BLE characteristic property.
func MDocCharacteristicPropertyName(_ prop: CBCharacteristicProperties) -> String {
    return switch prop {
    case .broadcast: "broadcast"
    case .read: "read"
    case .writeWithoutResponse: "write without response"
    case .write: "write"
    case .notify: "notify"
    case .indicate: "indicate"
    case .authenticatedSignedWrites: "authenticated signed writes"
    case .extendedProperties: "extended properties"
    case .notifyEncryptionRequired: "notify encryption required"
    case .indicateEncryptionRequired: "indicate encryption required"
    default: "unknown property"
    }
}

/// Return a string describing a BLE characteristic.
func MDocCharacteristicName(_ ch: CBCharacteristic) -> String {
    return MDocCharacteristicNameFromUUID(ch.uuid)
}

/// Return a string describing a BLE characteristic given its UUID.
func MDocCharacteristicNameFromUUID(_ ch: CBUUID) -> String {
    return switch ch {
    case holderStateCharacteristicId: "Holder:State"
    case holderClient2ServerCharacteristicId: "Holder:Client2Server"
    case holderServer2ClientCharacteristicId: "Holder:Server2Client"
    case holderL2CAPCharacteristicId: "Holder:L2CAP"
    case readerStateCharacteristicId: "Reader:State"
    case readerClient2ServerCharacteristicId: "Reader:Client2Server"
    case readerServer2ClientCharacteristicId: "Reader:Server2Client"
    case readerIdentCharacteristicId: "Reader:Ident"
    case readerL2CAPCharacteristicId: "Reader:L2CAP"
    default: "Unknown:\(ch)"
    }
}

/// Print a description of a BLE characteristic.
func MDocDesribeCharacteristic(_ ch: CBCharacteristic) {
    print("        \(MDocCharacteristicName(ch)) ( ", terminator: "")

    if ch.properties.contains(.broadcast) { print("broadcast", terminator: " ") }
    if ch.properties.contains(.read) { print("read", terminator: " ") }
    if ch.properties.contains(.writeWithoutResponse) { print("writeWithoutResponse", terminator: " ") }
    if ch.properties.contains(.write) { print("write", terminator: " ") }
    if ch.properties.contains(.notify) { print("notify", terminator: " ") }
    if ch.properties.contains(.indicate) { print("indicate", terminator: " ") }
    if ch.properties.contains(.authenticatedSignedWrites) { print("authenticatedSignedWrites", terminator: " ") }
    if ch.properties.contains(.extendedProperties) { print("extendedProperties", terminator: " ") }
    if ch.properties.contains(.notifyEncryptionRequired) { print("notifyEncryptionRequired", terminator: " ") }
    if ch.properties.contains(.indicateEncryptionRequired) { print("indicateEncryptionRequired", terminator: " ") }
    print(")")

    if let descriptors = ch.descriptors {
        for d in descriptors {
            print("          : \(d.uuid)")
        }
    } else {
        print("          <no descriptors>")
    }
}
