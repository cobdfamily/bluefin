import Foundation

func TFDebugPrint( message: String ) -> Void {
if let environmentFlag = ProcessInfo.processInfo.environment["TF_DEBUG"], environmentFlag == "true" {
debugPrint( message)
}

};
