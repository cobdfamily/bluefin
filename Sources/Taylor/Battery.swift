import Foundation
import IOKit.ps

func getBatteryPercentage() -> Int? {
    // Create a blob of Power Source information in a dictionary
    if let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
       let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef],
       let powerSource = sources.first {
        
        // Get detailed information about the battery
        if let description = IOPSGetPowerSourceDescription(snapshot, powerSource)?.takeUnretainedValue() as? [String: Any],
           let currentCapacity = description[kIOPSCurrentCapacityKey as String] as? Int,
           let maxCapacity = description[kIOPSMaxCapacityKey as String] as? Int {
            
            // Calculate the battery percentage
            let percentage = (currentCapacity * 100) / maxCapacity
            return percentage
        }
    }
    
    // Return nil if unable to retrieve the battery percentage
    return nil
}

import Foundation
import IOKit.ps

func getIsCharging() -> Bool? {
    // Get a snapshot of the current power sources
    guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue() else {
        return nil // Unable to retrieve power source info
    }
    
    // Get a list of power sources
    guard let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef] else {
        return nil // No power sources available
    }
    
    // Iterate through power sources to find battery information
    for source in sources {
        // Get the description of each power source
        if let description = IOPSGetPowerSourceDescription(snapshot, source)?.takeUnretainedValue() as? [String: Any] {
            // Check the power source type
            if let powerSourceType = description[kIOPSPowerSourceStateKey as String] as? String {
                // If the source is running on "Battery Power", return true
                return powerSourceType != kIOPSBatteryPowerValue
            }
        }
    }
    
    // Return nil if no battery information is found
    return nil
}