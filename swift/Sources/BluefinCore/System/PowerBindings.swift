import Foundation
import IOKit.ps

// Read-only window onto the host's battery state via
// IOKit Power Sources. On Macs without a battery
// (Mac mini, Mac Pro, Mac Studio) the power-sources
// list is empty -- callers get
// (percentage: nil, isCharging: false, isPresent: false).
public enum PowerBindings {
    public struct BatteryStatus {
        public let percentage: Double?
        public let isCharging: Bool
        public let isPresent: Bool

        public init(percentage: Double?, isCharging: Bool, isPresent: Bool) {
            self.percentage = percentage
            self.isCharging = isCharging
            self.isPresent = isPresent
        }
    }

    public static func batteryStatus() -> BatteryStatus {
        guard let info = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(info)?.takeRetainedValue() as? [CFTypeRef] else {
            return BatteryStatus(percentage: nil, isCharging: false, isPresent: false)
        }

        for source in sources {
            guard let description = IOPSGetPowerSourceDescription(info, source)?.takeUnretainedValue() as? [String: Any] else {
                continue
            }
            // Internal battery only -- ignore HID
            // peripheral batteries (mice, keyboards).
            let transport = description[kIOPSTransportTypeKey as String] as? String
            guard transport == kIOPSInternalType else { continue }

            let current = description[kIOPSCurrentCapacityKey as String] as? Double
            let max = description[kIOPSMaxCapacityKey as String] as? Double
            let isCharging = description[kIOPSIsChargingKey as String] as? Bool ?? false

            let percentage: Double?
            if let current, let max, max > 0 {
                percentage = (current / max) * 100.0
            } else {
                percentage = nil
            }

            return BatteryStatus(
                percentage: percentage,
                isCharging: isCharging,
                isPresent: true)
        }

        return BatteryStatus(percentage: nil, isCharging: false, isPresent: false)
    }
}
