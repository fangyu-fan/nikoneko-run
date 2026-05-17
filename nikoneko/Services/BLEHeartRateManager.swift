import CoreBluetooth

final class BLEHeartRateManager: NSObject {
    private var central: CBCentralManager?
    private var peripheral: CBPeripheral?
    var onHRUpdate: ((Int) -> Void)?

    private let heartRateServiceUUID     = CBUUID(string: "180D")
    private let heartRateMeasurementUUID = CBUUID(string: "2A37")

    func start(onHRUpdate: @escaping (Int) -> Void) {
        self.onHRUpdate = onHRUpdate
        central = CBCentralManager(delegate: self, queue: .main)
    }

    func stop() {
        if let p = peripheral { central?.cancelPeripheralConnection(p) }
        central?.stopScan()
    }

    private func parseMeasurement(_ data: Data) -> Int {
        let flags = data[0]
        let is16bit = (flags & 0x01) != 0
        return is16bit
            ? Int(data[1]) | (Int(data[2]) << 8)
            : Int(data[1])
    }
}

extension BLEHeartRateManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        guard central.state == .poweredOn else { return }
        central.scanForPeripherals(withServices: [heartRateServiceUUID])
    }

    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any], rssi: NSNumber) {
        self.peripheral = peripheral
        central.stopScan()
        central.connect(peripheral)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.delegate = self
        peripheral.discoverServices([heartRateServiceUUID])
    }
}

extension BLEHeartRateManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        peripheral.services?.forEach { service in
            peripheral.discoverCharacteristics([heartRateMeasurementUUID], for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        service.characteristics?.forEach { char in
            if char.uuid == heartRateMeasurementUUID {
                peripheral.setNotifyValue(true, for: char)
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let data = characteristic.value else { return }
        let hr = parseMeasurement(data)
        onHRUpdate?(hr)
    }
}
