// Copyright 2024 by Alex Jurgensen for Canadian Organization of the Blind and DeafBlind
// Part of the Tuna Screen Reader
// “This is a new year. A new beginning. And things will change.” Taylor Swift
import NodeAPI
import CNodeAPI
import Cocoa
import CoreGraphics
import Foundation
import ApplicationServices

#NodeModule(exports: [
    "AXAPIEnabled": try NodeFunction { () -> Bool in
        return AXIsProcessTrusted()
    },

    "AXIsProcessTrusted": try NodeFunction { () -> Bool in
        return AXIsProcessTrusted()
    },
    
    "AXUIElementCreateSystemWide": try NodeFunction { () -> Int? in
        let element = AXUIElementCreateSystemWide()
        return getIntFromUIElement( element: element )
    },

    "AXUIElementCreateApplication": try NodeFunction { (pid: Int) -> Int? in
        let element = AXUIElementCreateApplication(pid_t(Int32(pid)))
        return getIntFromUIElement( element: element )
    },
    
    "AXUIElementCopyAttributeValue": try NodeFunction { (intPtr: Int, attribute: String) -> NodeObject? in
        if let element = getUIElementFromInt( intPtr: intPtr ) {
            
            // Prepare a variable to receive the attribute value
            var value: CFTypeRef?
            let result = AXUIElementCopyAttributeValue(element, attribute as CFString, &value)
            
if result == .success, let unwrappedValue = value {

do
{
            // Attempt to cast and return the value if successful, otherwise return nil
if let convertedValue = getStringFromAXAttributeValue( unwrappedValue ) {
// Convert String to NodeObject
let nodeObject = try NodeObject( coercing: convertedValue )
return nodeObject
}

else if let convertedValue = getCGRectFromAXAttributeValue( unwrappedValue ) {
// Convert CGRect
return nil
}

else if let convertedValue = getCGPointFromAXAttributeValue( unwrappedValue ) {
// Convert CGPoint
let nodeObject = try NodeObject()
try nodeObject.define( NodeObjectPropertyList( dictionaryLiteral: ( "x", Double( convertedValue.x ) ) ) )
try nodeObject.define( NodeObjectPropertyList( dictionaryLiteral: ( "y", Double( convertedValue.y ) ) ) )
return nodeObject;
}

else if let convertedValue = getCGSizeFromAXAttributeValue( unwrappedValue ) {
// Convert CGSize
let nodeObject = try NodeObject()
try nodeObject.define( NodeObjectPropertyList( dictionaryLiteral: ( "height", Double( convertedValue.height ) ) ) )
try nodeObject.define( NodeObjectPropertyList( dictionaryLiteral: ( "width", Double( convertedValue.width ) ) ) )
return nodeObject;
}

else if let convertedValue = getAXUIElementFromAXAttributeValue( unwrappedValue ) {
// Convert AXUIElement
return try NodeObject( coercing: getIntFromUIElement( element: convertedValue ) )
}

else if let convertedValue = getAXUIElementArrayFromAXAttributeValue( unwrappedValue ) {
// Convert [AXUIElement]
return nil
}

else if let convertedValue = getBoolFromAXAttributeValue( unwrappedValue ) {
// Convert Bool
return try NodeObject( coercing: convertedValue )
}

else if let convertedValue = getNSNumberFromAXAttributeValue( unwrappedValue ) {
// Convert NSNumber
return nil
}

else if let convertedValue = getNSRangeFromAXAttributeValue( unwrappedValue ) {
// Convert NSRange
return nil
}

else if let convertedValue = getURLFromAXAttributeValue( unwrappedValue ) {
// Convert URL
return try NodeObject( coercing: convertedValue.absoluteString )
}

else if let convertedValue = getStringArrayFromAXAttributeValue( unwrappedValue ) {
// Convert [String]
return nil
}

else if let convertedValue = getUIntFromAXAttributeValue( unwrappedValue ) {
// Convert UInt
return try NodeObject( coercing: Int( bitPattern: convertedValue ) )
}

else
{
print( CFGetTypeID( value ) )
return nil
}

}
catch
{
return nil
}

}
else
{
 return nil;
}
//            return result == .success ? value as Any : nil
        } else {
print( "Eek" )
            return nil
        }
    },

    "AXUIElementCopyAttributeNames": try NodeFunction { (intPtr: Int ) -> NodeArray? in
        if let ptr = UnsafeRawPointer(bitPattern: UInt(bitPattern: intPtr) ) {
            // Convert UnsafeRawPointer back to an AXUIElement
            let element = Unmanaged<AXUIElement>.fromOpaque(ptr).takeUnretainedValue()
            
            // Prepare a variable to receive the attribute value
    var attributeNames: CFArray?

    // Pass a pointer to `attributeNames` directly to match the expected type
    let result = AXUIElementCopyAttributeNames(element, &attributeNames)

    if result == .success, let swiftArray: [NodeValueConvertible] = attributeNames as? [String] {
do
{
    let nodeArray = try NodeArray( capacity: 0 )
    
for ( index, item ) in swiftArray.enumerated() {
let plist = NodeObjectPropertyList( dictionaryLiteral: ( String(index), item ) )
    // Append each element from Swift array to NodeArray
        try nodeArray.define( plist )
}

    
    return nodeArray
}
catch
{
print( error )
return nil
}
    } else {
        print("Failed to get attribute names. AXError: \(result)")
return nil;
    }

        } else {
print( "Eek" )
            return nil
        }
    },

    "runAppleScript": try NodeFunction { ( script: String ) -> String? in
    // Create an NSAppleScript instance with the given script string
    let appleScript = NSAppleScript(source: script)
    
    // Run the script and store any errors
    var error: NSDictionary?
    let result = appleScript?.executeAndReturnError(&error)
    
    // Check for errors and return results
    if let error = error {
        print("AppleScript Error: \(error)")
        return nil
    } else if let result = result {
        return result.stringValue // Return the result as a string
    }
    
    return nil
},

    "getIdOfFrontmostApp": try NodeFunction { () -> Int? in
    guard let frontmostApp = NSWorkspace.shared.frontmostApplication else {
        return nil
    }
    return Int(frontmostApp.processIdentifier)
},

    "getBatteryPercentage": try NodeFunction { () -> Int? in
return getBatteryPercentage()
},

    "getIsCharging": try NodeFunction { () -> Bool? in
return getIsCharging()
},

    "getKeychainItem": try NodeFunction { ( service: String, account: String ) -> String? in
return getKeychainItem( service: service, account: account )
},

    "setKeychainItem": try NodeFunction { ( service: String, account: String, password: String ) -> Bool? in
return setKeychainItem( service: service, account: account, password: password )
},



])
public struct FastAX {}
